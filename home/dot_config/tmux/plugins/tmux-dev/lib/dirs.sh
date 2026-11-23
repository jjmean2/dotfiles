# 디렉토리 탐색과 미리보기. tmux-dev project(prefix S → 세션)와 tmux-dev worktree 의 dir 모드
# (prefix W → 지금 세션의 윈도우)가 함께 source 한다. 같은 탐색을 쓰고, 다른 것은 "무엇을 여나" 뿐이다. bash 용.
#
# 탐색 범위는 미리 정하지 않는다. 시작점은 홈($TMUX_DEV_SCAN_ROOT, 기본 $HOME) 하나이고 깊이 제한이 없다.
# 빼는 것은 두 가지다.
#   - 숨김 디렉토리. 저장소 탐색은 .git 만 예외로 들어간다. 숨김 아래는 대부분 도구 캐시·데이터라
#     홈 전체가 13초 → 1.4초로 준다 (2026-11-07 실측, session-picker.md). 숨김 아래를 열려면 경로를 직접 친다.
#   - ignore 파일($TMUX_DEV_IGNORE, ~/.config/tmux-dev/ignore)의 패턴. gitignore 문법이고 fd --ignore-file 로
#     넘긴다. / 로 시작하는 패턴은 탐색 시작점(홈) 기준이다. 파일이 없으면 Library, node_modules 를 뺀다.
# 디렉토리 탐색은 .gitignore 도 따른다(빌드 산출물 등). 저장소 탐색은 따르지 않는다(무시된 곳의 저장소도 찾는다).

SCAN_ROOT=${TMUX_DEV_SCAN_ROOT:-$HOME}
FD=$(command -v fd || command -v fdfind || true)   # 데비안·우분투 패키지는 fdfind 이름으로 설치된다

ignore_args() {  # fd 에 넘길 제외 인자를 IGNORE_ARGS 배열에
  IGNORE_ARGS=()
  if [ -f "$TMUX_DEV_IGNORE" ]; then IGNORE_ARGS=(--ignore-file "$TMUX_DEV_IGNORE")
  else IGNORE_ARGS=(--exclude Library --exclude node_modules); fi
}
need_fd() { [ -n "$FD" ] || die "fd is required (brew install fd)"; }

# 저장소 = .git 이 디렉토리인 곳 (메인 체크아웃). .git 이 파일인 워크트리·서브모듈은 --type d 로 빠진다.
# 숨김 중 .git 만 들어가도록 .git 이 아닌 숨김 이름을 모두 뺀다. --prune 은 .git 안으로 내려가지 않게 한다.
scan_repos() {  # 한 줄에 절대 경로 하나. 찾는 대로 흘려 보낸다
  need_fd; ignore_args
  "$FD" --base-directory "$SCAN_ROOT" --absolute-path --type d --hidden --no-ignore --prune --glob .git \
    --exclude '.[!g]*' --exclude '.g[!i]*' --exclude '.gi[!t]*' --exclude '.git?*' "${IGNORE_ARGS[@]}" 2>/dev/null \
    | sed 's|/\.git/*$||'
}
scan_dirs() {   # 한 줄에 절대 경로 하나 (숨김 제외, .gitignore 존중)
  need_fd; ignore_args
  "$FD" --base-directory "$SCAN_ROOT" --absolute-path --type d "${IGNORE_ARGS[@]}" 2>/dev/null | sed 's|/$||'
}

# --- 탐색 결과 캐시 (켜고 끄는 확장. 기본 꺼짐) --------------------------------------------
# 켜면(TMUX_DEV_SCAN_CACHE=on. tmux 에서는 @tmux-dev-scan-cache on 을 tmux-dev-open 이 넘긴다) 지난 탐색 결과를 바로
# 내보내고, 피커와 따로 도는 백그라운드 작업이 탐색을 다시 해 다음에 열 때 쓸 캐시를 새로 쓴다. 이번 목록을 도중에
# 갈아 끼우지는 않는다(커서 아래 항목이 바뀌는 일이 없다). 대가는 지난번 이후의 변화가 다음에 열 때 보인다는 것:
# 새 디렉토리는 아직 없고(경로를 치면 열린다), 지운 디렉토리는 아직 있다(고르면 안내만 한다. stale_pick, lib/picker.sh).
# 보안 에이전트가 디렉토리 열기마다 검사를 붙이는 머신에서 홈 탐색이 수 초 걸릴 때를 위한 것이다
# (design/session-picker.md "탐색 결과 캐시"). 꺼져 있으면 아래 scan_repos·scan_dirs 를 그대로 부른다.
# 캐시는 종류(repos|dirs)와 탐색 시작점별 파일 하나다: $TMUX_DEV_CACHE/scan/<종류>-<시작점의 / 를 %>. 지워도 된다.
scan_cached() {  # $1 repos | dirs → 한 줄에 절대 경로 하나
  [ "${TMUX_DEV_SCAN_CACHE:-off}" = on ] || { "scan_$1"; return; }
  local f=$TMUX_DEV_CACHE/scan/$1-${SCAN_ROOT//\//%}
  if [ -s "$f" ]; then
    cat "$f"
    scan_refresh_bg "$1" "$f"
  else
    # 첫 탐색: 지금처럼 찾는 대로 흘려 보내며 받아 적는다. 피커가 먼저 닫혀 끊기면 임시 파일만 남고(갱신 작업이 1시간 뒤
    # 치운다) 다음에 다시 이 길을 탄다
    mkdir -p "${f%/*}" 2>/dev/null || true
    "scan_$1" | tee "$f.$$"
    mv -f "$f.$$" "$f" 2>/dev/null || true
  fi
}
# 캐시 $2 를 새로 쓰는 탐색을 피커와 떼어 띄운다. 목록 프로세스는 기다리지 않고 바로 끝난다.
#   - set -m: 백그라운드 작업이 자기 프로세스 그룹을 갖는다. fzf 는 아직 도는 reload 를 끊을 때 그룹째 SIGKILL 을
#     보낸다(worktree-picker.md 의 index.lock 함정). 갱신은 목록을 다 내보낸 뒤 띄우므로 그 틈은 작다(바로 닫아도,
#     모드를 바꿔도 갱신이 끝까지 도는 것을 격리 tmux 에서 set -m 없이도 확인했다). 그 작은 틈을 막는 보험이다
#   - 표준 입출력을 모두 /dev/null 로: fzf 의 목록 파이프를 쥐고 있으면 fzf 가 목록이 끝나기를(로딩 표시) 기다린다
#   - 락(mkdir)으로 한 번에 하나만. 죽어서 남은 락은 10분 뒤 무시한다. 나머지 시간 동안은 낮은 우선순위(renice 10)
scan_refresh_bg() {  # $1 repos | dirs  $2 캐시 파일
  local kind=$1 f=$2 lock=$2.lock
  if ! mkdir "$lock" 2>/dev/null; then
    [ -n "$(find "$lock" -maxdepth 0 -mmin +10 2>/dev/null)" ] || return 0
    /bin/rm -rf "$lock"; mkdir "$lock" 2>/dev/null || return 0
  fi
  set -m
  (
    trap '/bin/rm -rf "$lock"' EXIT
    renice -n 10 -p "${BASHPID:-$$}" >/dev/null 2>&1 || true   # fd 가 물려받는다 (bash 3.2 는 BASHPID 가 없어 곧 끝날 부모에)
    find "${f%/*}" -maxdepth 1 -type f -name '*-*.[0-9]*' -mmin +60 -delete 2>/dev/null || true   # 끊긴 첫 탐색의 임시 파일
    if "scan_$kind" > "$f.$$.new" && [ -s "$f.$$.new" ]; then mv -f "$f.$$.new" "$f"; else /bin/rm -f "$f.$$.new"; fi
  ) < /dev/null > /dev/null 2>&1 &
  set +m
}

# git 브랜치 이름 → GB. 후보마다 git 을 띄우면 팝업이 느려지므로 .git/HEAD 를 직접 읽는다.
# 저장소가 아니면 빈 문자열, detached 면 짧은 해시. 저장소 모드는 행마다 부르므로 $(...) 서브셸 없이 전역에 둔다.
git_branch() {
  local g=$1/.git line
  GB=""
  [ -e "$g" ] || return 0
  if [ -f "$g" ]; then                       # worktree: "gitdir: <경로>"
    IFS= read -r line < "$g" || return 0
    g=${line#gitdir: }
    [[ $g = /* ]] || g=$1/$g
  fi
  [ -f "$g/HEAD" ] || return 0
  IFS= read -r line < "$g/HEAD" || return 0
  case $line in
    "ref: refs/heads/"*) GB=${line#ref: refs/heads/} ;;
    "ref: "*)            GB=${line#ref: } ;;
    *)                   GB=${line:0:7} ;;
  esac
}

dir_preview() {  # 저장소면 브랜치와 최근 커밋, 그리고 내용
  local d=$1
  [ -d "$d" ] || return 0
  if [ -e "$d/.git" ]; then
    git_branch "$d"; printf '%s%s%s\n\n' "$B" "$GB" "$R"
    git -C "$d" log --oneline --color=always -8 2>/dev/null; echo
  fi
  ls -1Ap "$d" 2>/dev/null | head -40
}
