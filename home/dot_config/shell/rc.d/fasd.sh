# shellcheck shell=bash disable=SC1090
# fasd: 자주 간 디렉터리·파일로 건너뛰기 (z, 등). https://github.com/clvv/fasd
#
# fasd --init 의 출력을 매번 만들지 않고 파일에 캐시해 둔다 (셸 시작 시간).
# 캐시가 없거나, fasd 실행 파일이나 이 파일이 캐시보다 최신이면 다시 만든다.
#
# zsh 단어 완성: 아무 명령의 인자 자리에서 조각을 치고 키를 누르면 fasd 기록에서 찾은 경로로 바뀐다.
#   Ctrl-X Ctrl-A   파일·디렉터리 (`vim rc,lo` 처럼 쉼표로 조각을 여러 개 줄 수 있다)
#   Ctrl-X Ctrl-D   디렉터리만
# tmux 안에서는 C-a 가 prefix2 라서 Ctrl-X Ctrl-A 를 C-x, C-a, C-a 로 누른다 (Ctrl-X Ctrl-D 는 그대로).
# fasd 문서의 세 번째 키 Ctrl-X Ctrl-F (파일만, fasd-complete-f)는 zsh 기본 동작이 걸려 있어 묶지 않았다.
#
# 위젯만 받고(zsh-wcomp) Tab 에는 끼우지 않는다(zsh-wcomp-install 은 뺀다). zsh-wcomp-install 은
# 전역 completer 를 `_complete _fasd_zsh_word_complete_trigger` 로 정해 Tab 이 후보를 못 찾을 때마다
# fasd 를 실행한다 (`vim ,rc,lo<Tab>` 꼴. 쓰려면 아래 zsh 줄의 목록에 더한다).
# fasd 는 위젯을 compinit 이 끝난 뒤에만 만들므로 이 파일은 compinit 뒤(rc.d)에 있어야 한다.
if command -v fasd >/dev/null 2>&1; then
	if [ -n "$ZSH_VERSION" ]; then
		_fasd_cache="$HOME/.fasd-init-zsh"
	elif [ -n "$BASH_VERSION" ]; then
		_fasd_cache="$HOME/.fasd-init-bash"
	else
		_fasd_cache="$HOME/.fasd-init-posix-shell"
	fi

	if [ ! -s "$_fasd_cache" ] ||
		[ "$(command -v fasd)" -nt "$_fasd_cache" ] ||
		[ "$HOME/.config/shell/rc.d/fasd.sh" -nt "$_fasd_cache" ]; then
		if [ -n "$ZSH_VERSION" ]; then
			fasd --init posix-alias zsh-hook zsh-ccomp zsh-ccomp-install zsh-wcomp >|"$_fasd_cache" 2>/dev/null
		elif [ -n "$BASH_VERSION" ]; then
			fasd --init posix-alias bash-hook bash-ccomp bash-ccomp-install >|"$_fasd_cache" 2>/dev/null
		else
			fasd --init posix-alias posix-hook >|"$_fasd_cache" 2>/dev/null
		fi
	fi

	[ -s "$_fasd_cache" ] && . "$_fasd_cache"
	unset _fasd_cache

	# 위젯이 만들어졌을 때만 키에 건다 (zle -l <이름> 은 그 위젯이 있으면 참).
	if [ -n "$ZSH_VERSION" ] && zle -l fasd-complete fasd-complete-d; then
		bindkey '^X^A' fasd-complete
		bindkey '^X^D' fasd-complete-d
	fi
fi
