#!/usr/bin/env bash
set -euo pipefail

# OS 를 감지해서 mac/linux 전용 설치 스크립트로 위임한다.

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

case "$(uname -s)" in
	Darwin)
		exec "$dir/install.mac.sh"
		;;
	Linux)
		exec "$dir/install.linux.sh"
		;;
	*)
		echo "지원하지 않는 OS 입니다: $(uname -s)" >&2
		exit 1
		;;
esac
