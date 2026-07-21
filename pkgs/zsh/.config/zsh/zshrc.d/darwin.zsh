# help 명령어
if alias run-help >/dev/null; then
	unalias run-help
fi
autoload -Uz run-help
HELPDIR="/usr/share/zsh/$ZSH_VERSION/help"
alias help=run-help
