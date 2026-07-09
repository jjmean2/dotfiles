if command -v nvim &>/dev/null; then
	# 참고: VISUAL은 화면 전체를 사용하는 에디터를 의미하고, EDITOR는 한 줄씩 편집하던 옛날 방식(ed 등)과의 호환성을 위한 것인데, 현대에는 보통 둘 다 똑같이 설정합니다.
	# EDITOR만 설정해도 되는데, VISUAL, EDITOR 둘다 설정한 경우, edit-command-line 기능은 VISUAL 값을 따름
	export VISUAL='nvim'
	export EDITOR='nvim'

	bindkey -e
fi

typeset -U path

path=("$HOME/.local/bin" $path)

eval "$(mise activate zsh)"

source_zsh_variants ~/.zshrc
