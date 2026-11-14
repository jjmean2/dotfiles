# shellcheck shell=sh disable=SC1091
# iPhone ShellFish 앱 (ssh 클라이언트) 의 셸 통합
if [ -e "$HOME/.shellfishrc" ]; then
	. "$HOME/.shellfishrc"
fi
