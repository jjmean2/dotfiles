# shellcheck shell=bash disable=SC1090
# fzf: 키 바인딩(Ctrl-R 히스토리, Ctrl-T 파일, Alt-C 디렉터리)과 ** 탭 완성
if command -v fzf >/dev/null 2>&1; then
	# Use `fd` instead of `find` command for `fzf`, CTRL_T and ALT_C
	if command -v fd >/dev/null 2>&1; then
		export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git --no-ignore'
		export FZF_CTRL_T_COMMAND='fd --hidden --exclude .git --no-ignore'
		export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git --no-ignore'
	fi

	# Set up fzf key bindings and fuzzy completion
	if [ -n "$ZSH_VERSION" ]; then
		source <(fzf --zsh)
	elif [ -n "$BASH_VERSION" ]; then
		eval "$(fzf --bash)"
	fi

	if command -v fd >/dev/null 2>&1; then
		# Use `fd` instead of `find` command for path completion (e.g. vim **<TAB>) and dir completion (e.g. cd **<TAB>)
		_fzf_compgen_path() {
			echo "$1"
			fd --hidden --follow --exclude ".git" --no-ignore . "$1"
		}

		_fzf_compgen_dir() {
			fd --type d --hidden --follow --exclude ".git" --no-ignore . "$1"
		}
	fi
fi
