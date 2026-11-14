# shellcheck shell=sh
# pnpm: 전역 설치(pnpm add -g)한 실행 파일
if [ -d "$HOME/Library/pnpm" ]; then
	export PNPM_HOME="$HOME/Library/pnpm"
	PATH="$PNPM_HOME/bin:$PATH"
fi
