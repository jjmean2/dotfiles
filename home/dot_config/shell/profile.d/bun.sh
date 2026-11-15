# shellcheck shell=sh
# bun: 전역 설치(bun install -g)한 실행 파일. zsh 완성은 rc.d/bun.zsh
if [ -d "$HOME/.bun" ]; then
	# bun global install
	export BUN_INSTALL="$HOME/.bun"
	PATH="$BUN_INSTALL/bin:$PATH"
fi
