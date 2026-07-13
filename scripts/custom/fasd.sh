#!/usr/bin/env bash
set -euo pipefail

# fasd 는 저장소가 아카이브되면서 여러 패키지 매니저에서 formula/package 가 빠져,
# 소스를 임시로 클론해서 직접 빌드/설치한다.
# 이미 설치되어 있으면 아무것도 하지 않으므로 여러 번 실행해도 안전하다(멱등).
#
# 사용법: fasd.sh <prefix>  (예: fasd.sh "$(brew --prefix)", fasd.sh /usr/local)

prefix="$1"

if [[ -e $prefix/fasd ]]; then
	exit 0
fi

src="$(mktemp -d)"
trap 'rm -rf "$src"' EXIT

git clone --depth=1 https://github.com/clvv/fasd.git "$src"
make -C "$src" install PREFIX="$prefix"
