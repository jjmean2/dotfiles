# shellcheck shell=bash disable=SC1090
# fasd: 자주 간 디렉터리·파일로 건너뛰기 (z, 등). https://github.com/clvv/fasd
#
# fasd --init 의 출력을 매번 만들지 않고 파일에 캐시해 둔다 (셸 시작 시간).
# 캐시가 없거나, fasd 실행 파일이나 이 파일이 캐시보다 최신이면 다시 만든다.
#
# zsh 의 단어 완성(zsh-wcomp, zsh-wcomp-install: `vim ,rc,lo<Tab>` 처럼 쉼표로 찾기)은 넣지 않는다.
# fasd 는 그 부분을 compinit 이 끝난 뒤에만 켜는데, 켜면 전역 completer 를
# `_complete _fasd_zsh_word_complete_trigger` 로 바꿔 Tab 완성 전체에 끼어든다.
# 쓰려면 아래 zsh 줄의 목록에 zsh-wcomp zsh-wcomp-install 을 더한다.
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
			fasd --init posix-alias zsh-hook zsh-ccomp zsh-ccomp-install >|"$_fasd_cache" 2>/dev/null
		elif [ -n "$BASH_VERSION" ]; then
			fasd --init posix-alias bash-hook bash-ccomp bash-ccomp-install >|"$_fasd_cache" 2>/dev/null
		else
			fasd --init posix-alias posix-hook >|"$_fasd_cache" 2>/dev/null
		fi
	fi

	[ -s "$_fasd_cache" ] && . "$_fasd_cache"
	unset _fasd_cache
fi
