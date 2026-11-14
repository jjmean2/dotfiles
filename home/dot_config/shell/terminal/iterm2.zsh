# iTerm2 셸 통합 (zsh). iTerm2 안에서만 적용한다.
# LC_TERMINAL 은 iTerm2 가 심는 변수로 ssh 와 tmux 너머로도 전해진다. tmux 안에서는 아래 배포본이
# 스스로 물러나고(TERM 이 tmux-256color / screen 이면 건너뛴다) 유틸리티 alias 만 남는다.
[ "$TERM_PROGRAM" = "iTerm.app" ] || [ "$LC_TERMINAL" = "iTerm2" ] || return 0

# iterm2.com 이 배포하는 스크립트 그대로 (../iterm2/)
if [ -e "$HOME/.config/shell/iterm2/iterm2_shell_integration.zsh" ]; then
	. "$HOME/.config/shell/iterm2/iterm2_shell_integration.zsh"
fi

iterm2_print_user_vars() {
	iterm2_set_user_var gitBranch "$( (git branch 2>/dev/null) | grep '\*' | cut -c3-)"
}

# iTerm2 유틸리티(imgcat, it2copy, it2dl …)를 이름 그대로 쓸 수 있게 alias로 건다.
# (설치 스크립트가 통합 스크립트 끝에 붙이던 alias 줄을 대신한다.)
for _it2_util in $HOME/.iterm2/*(N.x); do
	alias ${_it2_util:t}=$_it2_util
done
unset _it2_util
