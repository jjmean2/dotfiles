# tmux 윈도우 레이아웃 함수. tmux-dev project(세션의 첫 윈도우)와 tmux-dev worktree(워크트리 윈도우)가
# 함께 source 한다. bash 용. 패널 = 역할: 왼쪽 셸(명령, 에이전트 CLI), 오른쪽 nvim.
#
# "레이아웃" 은 tmux 자체의 패널 배치 프리셋(prefix Space, select-layout)과는 별개로,
# "새 윈도우의 어느 패널에 무엇을 띄우나" 를 정하는 것이다. 윈도우를 만든 직후 한 번만 적용한다.
#
# 사용: apply_layout <이름> <윈도우 대상> <디렉토리>
#   <윈도우 대상> 은 tmux 의 target-window. 세션 이름(그 세션의 현재 윈도우), "@3" 같은 윈도우 id,
#   "세션:인덱스" 모두 된다. 패널은 "<대상>.<패널 인덱스>" 로 가리킨다 (man tmux: COMMANDS 의 target-pane).
# 이름을 추가하려면 layout_<이름> 함수를 쓰고 apply_layout 의 case 에 넣는다.

layout_ide() {   # 왼쪽 셸(여기서 claude 등을 띄운다), 오른쪽 nvim. 포커스는 왼쪽
  local win=$1 dir=$2
  tmux split-window -h -t "$win" -c "$dir"
  tmux send-keys -t "$win.1" 'nvim' Enter   # 셸 위에서 띄워 nvim 을 닫아도 패널이 남는다
  tmux select-pane -t "$win.0"
}
layout_plain() { # 셸 하나
  :
}
apply_layout() {
  case "$1" in
    ide)   layout_ide "$2" "$3" ;;
    plain) layout_plain "$2" "$3" ;;
    *) echo "모르는 레이아웃 '$1' (ide, plain)" >&2; return 1 ;;
  esac
}
