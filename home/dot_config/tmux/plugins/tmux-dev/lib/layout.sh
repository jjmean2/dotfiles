# tmux 윈도우 레이아웃. tmux-dev project(세션의 첫 윈도우)와 tmux-dev worktree(워크트리 윈도우)가 함께 source 한다. bash 용.
#
# "레이아웃" 은 tmux 자체의 패널 배치 프리셋(prefix Space, select-layout: 패널의 기하학)과는 별개로,
# "새 윈도우의 어느 패널에 무엇을 띄우나"(역할) 를 정하는 것이다. 윈도우를 만든 직후 한 번만 적용한다.
#
# 어느 레이아웃을 쓰나 (resolve_layout): 명령줄 --layout > 저장소의 git config tmux-dev.layout > 전역 TMUX_DEV_LAYOUT
# (tmux 옵션 @tmux-dev-layout 을 진입 스크립트가 넘긴다) > ide. 피커에서 alt-l 로 고르면 그 저장소의 기본값으로 남는다
# (tmux-dev.layout). 매번 묻지 않고 한 번 고른 것을 기억하는 쪽이 키가 적다.
#
# 레이아웃 추가: layout_<이름>() 함수를 쓰고 layout_register 로 설명과 그림을 등록한다. 개인 레이아웃은
# ~/.config/tmux-dev/layouts.sh 에 같은 꼴로 두면 있을 때 source 한다. 예)
#   layout_agent() { local win=$1 dir=$2; layout_ide "$win" "$dir"; tmux send-keys -t "$win.0" 'claude' Enter; }
#   layout_register agent "왼쪽 claude 자동 실행 / 오른쪽 nvim" $'┌──────┬──────┐\n│claude│ nvim │\n└──────┴──────┘'
#
# 사용: apply_layout <이름> <윈도우 대상> <디렉토리>
#   <윈도우 대상> 은 tmux 의 target-window. 세션 이름(그 세션의 현재 윈도우), "@3" 같은 윈도우 id,
#   "세션:인덱스" 모두 된다. 패널은 "<대상>.<패널 인덱스>" 로 가리킨다 (man tmux: COMMANDS 의 target-pane).

LAYOUT_NAMES=(); LAYOUT_DESCS=(); LAYOUT_ARTS=()
layout_register() { LAYOUT_NAMES+=("$1"); LAYOUT_DESCS+=("$2"); LAYOUT_ARTS+=("$3"); }

layout_ide() {   # 왼쪽 셸(여기서 claude 등을 띄운다), 오른쪽 nvim. 포커스는 왼쪽
  local win=$1 dir=$2
  tmux split-window -h -t "$win" -c "$dir"
  tmux send-keys -t "$win.1" 'nvim' Enter   # 셸 위에서 띄워 nvim 을 닫아도 패널이 남는다
  tmux select-pane -t "$win.0"
}
layout_register ide "왼쪽 셸 / 오른쪽 nvim" \
'┌────────────┬────────────┐
│ 셸         │ nvim       │
│ (claude 등)│            │
└────────────┴────────────┘'

layout_plain() { # 셸 하나
  :
}
layout_register plain "셸 하나" \
'┌─────────────────────────┐
│ 셸                      │
│                         │
└─────────────────────────┘'

# ---------------------------------------------------------------------------
# dev 서버 패널
# ---------------------------------------------------------------------------
# 무엇을 실행하나 (dev_command): 저장소의 git config tmux-dev.dev (워크트리도 메인과 config 를 공유한다)
#   > package.json 에 scripts.dev 가 있으면 lockfile 로 고른 패키지 매니저의 dev (pnpm/yarn/bun/npm)
#   > 없음. 없으면 그 패널은 빈 셸로 남는다 (원하는 걸 직접 친다).
#   예) git config tmux-dev.dev 'pnpm --filter web dev'   또는   git config tmux-dev.dev 'make serve'
# 셸 위에서 send-keys 로 실행하므로 Ctrl-C 로 서버를 끄면 셸이 남고, ↑ Enter 로 다시 켠다.
# 새 워크트리에 node_modules 가 없으면 서버가 실패한다. 설치는 워크트리 셋업 훅(git config tmux-dev.worktree.setup) 몫.
# 워크트리 여러 개에서 동시에 켜면 포트가 겹친다. Vite·Next 는 다음 빈 포트로 비켜 간다.
dev_command() {   # $1 디렉토리 → 실행할 명령 한 줄. 없으면 빈 출력
  local dir=$1 cmd
  cmd=$(git -C "$dir" config --get tmux-dev.dev 2>/dev/null) && [ -n "$cmd" ] && { printf '%s\n' "$cmd"; return; }
  [ -f "$dir/package.json" ] || return 0
  if command -v jq >/dev/null 2>&1; then
    jq -e '.scripts.dev' "$dir/package.json" >/dev/null 2>&1 || return 0
  else
    grep -q '"dev"[[:space:]]*:' "$dir/package.json" || return 0
  fi
  if   [ -f "$dir/pnpm-lock.yaml" ]; then echo 'pnpm dev'
  elif [ -f "$dir/yarn.lock" ]; then echo 'yarn dev'
  elif [ -f "$dir/bun.lock" ] || [ -f "$dir/bun.lockb" ]; then echo 'bun run dev'
  else echo 'npm run dev'
  fi
}
dev_pane() {      # $1 dev 패널 id, $2 디렉토리. 명령이 있으면 실행한다
  local cmd; cmd=$(dev_command "$2")
  [ -n "$cmd" ] && tmux send-keys -t "$1" "$cmd" Enter
  return 0
}
# 패널 인덱스는 위치 순이라 나눌 때마다 바뀐다. 셋 이상으로 나누는 레이아웃은 split-window -P 로 패널 id(%N)를 받아 쓴다.

layout_ide-dev() {   # 왼쪽 위 셸, 왼쪽 아래 dev 서버, 오른쪽 nvim. 포커스는 셸
  local win=$1 dir=$2 shell nvim dev
  shell=$(tmux display-message -p -t "$win" '#{pane_id}')
  nvim=$(tmux split-window -h -t "$shell" -c "$dir" -P -F '#{pane_id}')
  dev=$(tmux split-window -v -l 30% -t "$shell" -c "$dir" -P -F '#{pane_id}')
  tmux send-keys -t "$nvim" 'nvim' Enter
  dev_pane "$dev" "$dir"
  tmux select-pane -t "$shell"
}
layout_register ide-dev "왼쪽 셸 + dev 서버 / 오른쪽 nvim" \
'┌────────────┬────────────┐
│ 셸         │ nvim       │
│ (claude 등)│            │
├────────────┤            │
│ dev 서버   │            │
└────────────┴────────────┘'

layout_nvim() {   # nvim 하나 (셸 위에서 띄우므로 :q 하면 셸이 남는다)
  tmux send-keys -t "$1" 'nvim' Enter
}
layout_register nvim "nvim 하나" \
'┌─────────────────────────┐
│ nvim                    │
│                         │
└─────────────────────────┘'

layout_nvim-dev() {  # 위 nvim, 아래 dev 서버. 포커스는 nvim
  local win=$1 dir=$2 nvim dev
  nvim=$(tmux display-message -p -t "$win" '#{pane_id}')
  dev=$(tmux split-window -v -l 25% -t "$nvim" -c "$dir" -P -F '#{pane_id}')
  tmux send-keys -t "$nvim" 'nvim' Enter
  dev_pane "$dev" "$dir"
  tmux select-pane -t "$nvim"
}
layout_register nvim-dev "위 nvim / 아래 dev 서버" \
'┌─────────────────────────┐
│ nvim                    │
│                         │
├─────────────────────────┤
│ dev 서버                │
└─────────────────────────┘'

# 개인 레이아웃 (있으면)
# shellcheck disable=SC1090
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/tmux-dev/layouts.sh" ] && . "${XDG_CONFIG_HOME:-$HOME/.config}/tmux-dev/layouts.sh"

layout_index() {  # 이름 → LAYOUT_IDX. 없으면 1 반환
  local i; LAYOUT_IDX=-1
  for ((i = 0; i < ${#LAYOUT_NAMES[@]}; i++)); do [ "${LAYOUT_NAMES[$i]}" = "$1" ] && { LAYOUT_IDX=$i; return 0; }; done
  return 1
}
layout_list() {   # "<이름>\t<설명>" 한 줄씩
  local i; for ((i = 0; i < ${#LAYOUT_NAMES[@]}; i++)); do printf '%s\t%s\n' "${LAYOUT_NAMES[$i]}" "${LAYOUT_DESCS[$i]}"; done
}
layout_art() { layout_index "$1" && printf '%s\n' "${LAYOUT_ARTS[$LAYOUT_IDX]}"; }
apply_layout() {
  layout_index "$1" || { echo "모르는 레이아웃 '$1' ($(layout_list | cut -f1 | tr '\n' ' '))" >&2; return 1; }
  "layout_$1" "$2" "$3"
}
# 쓸 레이아웃을 정한다: $1 명령줄 값(비어 있을 수 있음) $2 저장소 디렉토리(비어 있거나 저장소가 아닐 수 있음)
resolve_layout() {
  local l=$1
  [ -n "$l" ] || { [ -n "${2:-}" ] && l=$(git -C "$2" config --get tmux-dev.layout 2>/dev/null) || l=""; }
  [ -n "$l" ] || l=${TMUX_DEV_LAYOUT:-ide}
  printf '%s\n' "$l"
}
# fzf 로 레이아웃을 고른다. $1 은 미리보기용 명령 접두 (뒤에 이름이 붙어 그림을 출력해야 한다). $2 는 머리말 (생략하면
# 저장소 기본값 안내). 고른 이름을 출력, 취소면 1.
# Esc 는 검색어만 지우고 닫기는 ctrl-c (tmux-dev 피커 공통 규칙, tmux-dev-project 의 pick 참고).
choose_layout() {
  local out
  out=$(layout_list | fzf --delimiter=$'\t' --with-nth=1,2 --nth=1 --prompt='layout> ' --height=100% --reverse \
        --bind 'esc:clear-query' \
        --header="${2:-이 윈도우를 어떤 레이아웃으로 열까요. 고른 것이 이 저장소의 기본이 된다 (git config tmux-dev.layout)}" \
        --preview="$1 {1}" --preview-window='right,50%,border-left') || return 1
  printf '%s\n' "${out%%$'\t'*}"
}
