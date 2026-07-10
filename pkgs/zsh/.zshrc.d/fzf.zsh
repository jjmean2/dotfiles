# fzf 커맨드가 없으면 early return 한다.
((${+commands[fzf]})) || return 0

# fzf 키 바인딩 설정
# Use `fd` instead of `find` command for `fzf`, CTRL_T and ALT_C
if command -v fd &>/dev/null; then
	export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git --no-ignore'
	export FZF_CTRL_T_COMMAND='fd --hidden --exclude .git --no-ignore'
	export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git --no-ignore'
fi

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

# Use `fd` instead of `find` command for path completion (e.g. vim **<TAB>) and dir completion (e.g. cd **<TAB>)
_fzf_compgen_path() {
	echo "$1"
	fd --hidden --follow --exclude ".git" --no-ignore . "$1"
}

_fzf_compgen_dir() {
	fd --type d --hidden --follow --exclude ".git" --no-ignore . "$1"
}
