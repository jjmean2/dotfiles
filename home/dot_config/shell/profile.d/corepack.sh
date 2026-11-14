# shellcheck shell=sh
# corepack 이 package.json 의 packageManager 필드를 스스로 채우지 않게 한다.
# https://github.com/nodejs/corepack/blob/main/README.md#environment-variables
if command -v corepack >/dev/null 2>&1; then
	export COREPACK_ENABLE_AUTO_PIN=0
fi
