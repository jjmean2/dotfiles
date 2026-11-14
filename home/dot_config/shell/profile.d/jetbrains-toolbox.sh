# shellcheck shell=sh
# JetBrains Toolbox App 이 만드는 IDE 실행 스크립트 (idea, webstorm 등)
if [ -d "$HOME/Library/Application Support/JetBrains/Toolbox/scripts" ]; then
	PATH="$HOME/Library/Application Support/JetBrains/Toolbox/scripts:$PATH"
fi
