# shellcheck shell=bash
# tmux-dev: 창을 패널의 경로로 찾는다. libexec/tmux-dev-project 와 tmux-dev-worktree 가 source 한다
# (키마다 도는 빠른 길에서는 읽지 않는다. 여기는 tmux 를 부르는 쪽이 쓴다).
#
# 왜 경로인가: 전에는 만든 창에 사용자 옵션(worktree, dir)을, 세션에 tmux-dev-path 를 붙여 두고 그것으로 찾았다.
# 표지는 창이라는 자리에 붙는데 "워크트리 안에 있다" 는 패널의 성질이다. 그래서 prefix c 로 연 창은 잡히지 않았고(같은 워크트리의
# 창이 하나 더 생겼다), break-pane 으로 떼어 낸 패널은 표지를 잃고 남은 창은 무관한 패널만 있어도 표지를 지녔으며, 정리는 표지 없는
# 창의 프로세스를 지워지는 디렉토리에 남겼다. tmux 는 패널마다 두 경로를 이미 들고 있다:
#   pane_start_path     패널을 만들 때 받은 경로(-c). cd 로 바뀌지 않고 break-pane·join-pane 에서 패널을 따라간다.
#                       받은 그대로라 심볼릭 링크가 풀려 있지 않다 → real_dir 로 푼다
#   pane_current_path   패널의 포그라운드 프로그램의 cwd (셸이 아니다). 실제 경로다
#
# 규칙 (이 파일의 함수 하나씩이 규칙 하나다. W 의 목록·Enter·정리 미리보기·정리, S 의 워크트리 이동이 같은 함수를 쓴다)
#   패널의 주인(pane_owner)   현재 경로가 이 저장소의 워크트리 안이면 그 워크트리, 아니면 시작 경로의 워크트리. 겹치면 가장 깊은 것
#                             (메인 체크아웃이 그 아래 .claude/worktrees/* 를 삼키지 않게). 한 패널의 주인은 하나다.
#                             현재 경로를 먼저 보는 것은 지울 때 중요한 것이 "지금 거기 있는 프로세스" 여서다. 시작 경로로
#                             물러나는 것은 프로그램이 잠깐 다른 곳으로 옮겨도(현재 경로가 바뀐다) 창이 깜빡이지 않게.
#   워크트리의 창(window_for) 그 워크트리가 주인인 패널이 있는 가장 앞 번호의 창
#   디렉토리의 창(dir_window_for)  현재 경로가 정확히 그 디렉토리인 패널이 있는 가장 앞 창, 없으면 시작 경로가 그런 창.
#                             디렉토리는 겹칠 수 있어(app 과 app/docs) "안에 있으면" 이 아니라 같을 때만이다
#   피커 자신은 뺀다          피커는 그 창의 modal 패널이고 세션 디렉토리로 cd 해 있다. 세지 않는다 (pane_modal_flag)
# 표지는 이제 쓰지도 읽지도 않는다. 떠 있는 서버의 세션·창에 예전 값이 남아 있어도 아무 일도 하지 않는다.

# list-panes 의 한 줄. 앞에 칸을 덧붙여 쓸 수 있다 (project 의 open_worktree). US 는 lib/picker.sh
# shellcheck disable=SC2034  # 부른 쪽 스크립트가 쓴다
PANE_FMT="#{window_index}${US}#{window_id}${US}#{pane_id}${US}#{pane_modal_flag}${US}#{pane_current_command}${US}#{pane_start_path}${US}#{pane_current_path}"

# 디렉토리 → REAL (심볼릭 링크를 푼 실제 경로). 없는 디렉토리면 1. 서브셸을 띄우지 않는다 (세션·패널 수만큼 불린다)
real_dir() {
  REAL=""; [ -n "${1:-}" ] || return 1
  local old=$PWD
  cd -P -- "$1" 2>/dev/null || return 1
  REAL=$PWD
  cd -- "$old" 2>/dev/null || true
}

WT_ARR=()   # 이 저장소의 워크트리 경로들 (메인 포함). 비어 있으면 주인도 없다
wt_set() {  # $1 워크트리 경로들 (한 줄에 하나)
  local w; WT_ARR=()
  while IFS= read -r w; do [ -z "$w" ] || WT_ARR+=("$w"); done <<< "$1"
  return 0
}
wt_of() {  # $1 경로 → OWNER (그 경로를 담는 가장 깊은 워크트리). 없으면 빈 값과 1
  local w; OWNER=""
  [ -n "${1:-}" ] || return 1
  for w in "${WT_ARR[@]+"${WT_ARR[@]}"}"; do
    case $1 in "$w"|"$w"/*) [ "${#w}" -le "${#OWNER}" ] || OWNER=$w ;; esac
  done
  [ -n "$OWNER" ]
}
is_wt_root() {  # $1 경로가 워크트리 루트인가
  local w
  for w in "${WT_ARR[@]+"${WT_ARR[@]}"}"; do [ "$w" != "$1" ] || return 0; done
  return 1
}
pane_owner() {  # $1 시작 경로 $2 현재 경로 → OWNER (없으면 빈 값과 1), START (실제 경로로 푼 시작 경로)
  START=${1:-}; real_dir "$START" && START=$REAL
  wt_of "${2:-}" || wt_of "$START"
}

# 읽어 둔 패널 (창 번호 순, 한 창의 패널은 이어서 나온다). modal 패널은 들어 있지 않다
P_IDX=(); P_WIN=(); P_ID=(); P_CMD=(); P_START=(); P_CUR=(); P_OWN=()
panes_read() {  # stdin: PANE_FMT 줄들 → P_*
  local idx win id modal cmd start cur
  P_IDX=(); P_WIN=(); P_ID=(); P_CMD=(); P_START=(); P_CUR=(); P_OWN=()
  while IFS=$US read -r idx win id modal cmd start cur; do
    [ -n "$id" ] || continue
    [ "$modal" != 1 ] || continue
    # Claude Code 는 실행 파일의 실제 이름이 버전 숫자라(~/.local/share/claude/versions/2.1.330) 명령 이름이 숫자로 나온다.
    # 정리 미리보기에서 무엇이 닫히는지 알아볼 수 있게 claude 로 보인다 (tmux.conf 의 탭 이름과 같은 규칙)
    [[ $cmd =~ ^[0-9]+[.][0-9]+[.][0-9]+$ ]] && cmd=claude
    pane_owner "$start" "$cur" || OWNER=""
    P_IDX+=("$idx"); P_WIN+=("$win"); P_ID+=("$id"); P_CMD+=("$cmd"); P_START+=("$START"); P_CUR+=("$cur"); P_OWN+=("$OWNER")
  done
  return 0
}
# 아래 둘은 결과를 WIN(창 id, 없으면 빈 값)과 WIN_IDX(창 번호)에 둔다 (행마다 $(...) 서브셸을 띄우지 않으려고)
# shellcheck disable=SC2034  # 부른 쪽 스크립트가 읽는다 (아래 두 함수의 대입도 같다)
WIN=""; WIN_IDX=""
# shellcheck disable=SC2034
window_for() {  # $1 워크트리 경로
  local i; WIN=""; WIN_IDX=""
  for ((i = 0; i < ${#P_ID[@]}; i++)); do
    [ "${P_OWN[$i]}" = "$1" ] || continue
    WIN=${P_WIN[$i]}; WIN_IDX=${P_IDX[$i]}; return 0
  done
  return 1
}
# shellcheck disable=SC2034
dir_window_for() {  # $1 디렉토리 (실제 경로)
  local i; WIN=""; WIN_IDX=""
  for ((i = 0; i < ${#P_ID[@]}; i++)); do
    [ "${P_CUR[$i]}" = "$1" ] || continue
    WIN=${P_WIN[$i]}; WIN_IDX=${P_IDX[$i]}; return 0
  done
  for ((i = 0; i < ${#P_ID[@]}; i++)); do
    [ "${P_START[$i]}" = "$1" ] || continue
    WIN=${P_WIN[$i]}; WIN_IDX=${P_IDX[$i]}; return 0
  done
  return 1
}
# 디렉토리 모드의 한 경로가 가리키는 창: 워크트리 루트면 워크트리 규칙, 아니면 디렉토리 규칙.
# 목록의 ●N 과 Enter(resolve_dir → ensure_window | ensure_dir_window)가 같은 창을 가리키게 하는 하나의 갈림이다
open_window_for() { if is_wt_root "$1"; then window_for "$1"; else dir_window_for "$1"; fi; }
