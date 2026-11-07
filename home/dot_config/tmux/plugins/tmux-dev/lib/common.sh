# tmux-dev 공용 (bash). libexec/ 의 서브커맨드 스크립트가 source 한다.
#
# 파일 위치는 XDG 세 디렉토리에 종류별로 1:1 대응한다. 환경변수로 바꿀 수 있다 (테스트용).
#   설정   $XDG_CONFIG_HOME/tmux-dev/ignore            디렉토리 탐색에서 뺄 경로 (gitignore 문법, 머신별. lib/dirs.sh)
#   상태   $XDG_STATE_HOME/tmux-dev/history            prefix S 피커로 고른 곳 (최근 순)
#   데이터 $XDG_DATA_HOME/tmux-dev/worktrees/<저장소>/<브랜치>   tmux-dev worktree 가 만드는 워크트리
#   캐시   $XDG_CACHE_HOME/tmux-dev/{merged,patchids}/   머지 판정 결과와 main 커밋 patch-id 집합 (지워도 다시 계산된다)
# 워크트리는 저장소에서 파생된 체크아웃이고 영속적인 것은 브랜치라, 도구가 관장하는 데이터 자리에 둔다.
# 저장소별로 바꾸려면 git config tmux-dev.worktree.root (tmux-dev worktree --help).
TMUX_DEV_IGNORE="${TMUX_DEV_IGNORE:-${XDG_CONFIG_HOME:-$HOME/.config}/tmux-dev/ignore}"
TMUX_DEV_HISTORY="${TMUX_DEV_HISTORY:-${XDG_STATE_HOME:-$HOME/.local/state}/tmux-dev/history}"
TMUX_DEV_WORKTREES="${TMUX_DEV_WORKTREES:-${XDG_DATA_HOME:-$HOME/.local/share}/tmux-dev/worktrees}"
TMUX_DEV_CACHE="${TMUX_DEV_CACHE:-${XDG_CACHE_HOME:-$HOME/.cache}/tmux-dev}"
# 새 윈도우의 레이아웃 (lib/layout.sh). 진입 스크립트가 @tmux-dev-layout 을 환경변수로 넘긴다.
TMUX_DEV_LAYOUT="${TMUX_DEV_LAYOUT:-ide}"

# 색 (fzf --ansi 용)
B=$'\033[1m'; D=$'\033[2m'; G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[0m'

# 오류: stderr 와 (tmux 안이면) 상태줄 메시지에 함께 적는다. 팝업은 -E 로 바로 닫혀 stderr 만으로는 못 본다.
die() {
  echo "tmux-dev: $*" >&2
  [ -n "${TMUX:-}" ] && tmux display-message -d 5000 "tmux-dev: $*" || true
  exit 1
}
expand_tilde() { printf '%s\n' "${1/#\~/$HOME}"; }
abbrev_home()  { case $1 in "$HOME") printf '~\n' ;; "$HOME"/*) printf '~%s\n' "${1#"$HOME"}" ;; *) printf '%s\n' "$1" ;; esac; }
# 디렉토리를 정규화한 절대 경로로. 존재하지 않으면 빈 줄.
canon() { [ -d "$1" ] && (cd "$1" 2>/dev/null && pwd) || true; }
