# commands 변수에는 zsh에서 사용 가능한 외부 실행파일의 경로가 담겨 있다.
# $+commands[fasd]는 fasd 키가 연관배열 변수에 있으면 1, 없으면 0을 반환한다.
# ((expr))는 expr이 0이면, exit code 1, 0이 아니면 exit code 0으로 종료된다.
# 이를 조합하여 특정 커맨드가 사용 가능한지 검사하는 조건을 만들 수 있다.
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
