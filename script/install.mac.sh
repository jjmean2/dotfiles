#!/usr/bin/env bash
set -euo pipefail

# macOS 개발 환경에 필요한 기본 도구를 설치한다.
# Homebrew(Brewfile), mise 로 관리하는 언어 런타임 순서로 설치하며
# 이미 설치되어 있으면 건너뛰므로 여러 번 실행해도 안전하다(멱등).

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

if ! command -v brew &>/dev/null; then
	NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

	if [ -x /opt/homebrew/bin/brew ]; then
		eval "$(/opt/homebrew/bin/brew shellenv)"
	elif [ -x /usr/local/bin/brew ]; then
		eval "$(/usr/local/bin/brew shellenv)"
	fi
fi

brew update
brew bundle --file="$dir/../config/homebrew/Brewfile"

if ! command -v mise &>/dev/null; then
	echo "mise 명령을 찾을 수 없습니다. brew bundle 이 정상적으로 끝났는지 확인해 주세요." >&2
	exit 1
fi

eval "$(mise activate bash)"

# mise use --global 은 지정한 버전이 없으면 설치하고, 이미 설치/설정되어 있으면 그대로 둔다.
mise use --global node@lts go@latest python@latest deno@latest

echo "macOS 기본 도구 설치 완료"
