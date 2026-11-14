# shellcheck shell=sh disable=SC1091
# bun: 전역 설치(bun install -g)한 실행 파일과 완성 스크립트
if [ -d "$HOME/.bun" ]; then
	# bun global install
	export BUN_INSTALL="$HOME/.bun"
	PATH="$BUN_INSTALL/bin:$PATH"

	# bun completions
	if [ -s "$HOME/.bun/_bun" ]; then
		. "$HOME/.bun/_bun"
	fi
fi
