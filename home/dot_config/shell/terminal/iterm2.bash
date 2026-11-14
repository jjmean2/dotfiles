# shellcheck shell=bash disable=SC1091
# iTerm2 셸 통합 (bash). iTerm2 안에서만 적용한다.
# LC_TERMINAL 은 iTerm2 가 심는 변수로 ssh 와 tmux 너머로도 전해진다.
[ "$TERM_PROGRAM" = "iTerm.app" ] || [ "$LC_TERMINAL" = "iTerm2" ] || return 0

# iterm2.com 이 배포하는 스크립트 그대로 (../iterm2/)
if [ -e "$HOME/.config/shell/iterm2/iterm2_shell_integration.bash" ]; then
	. "$HOME/.config/shell/iterm2/iterm2_shell_integration.bash"
fi

iterm2_print_user_vars() {
	iterm2_set_user_var gitBranch "$( (git branch 2>/dev/null) | grep '\*' | cut -c3-)"
}
