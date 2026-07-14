#!/usr/bin/env bash
set -euo pipefail

# OS 를 감지해서 darwin/linux 전용 설치 스크립트로 위임한다.

dir="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

case "$(uname -s)" in
Darwin)
	exec "$dir/install_base.darwin.sh"
	;;
Linux)
	exec "$dir/install_base.linux.sh"
	;;
*)
	echo "지원하지 않는 OS 입니다: $(uname -s)" >&2
	exit 1
	;;
esac

# 공통 스크립트 설치
# 패키지 매니저로 설치할 수 없는 도구들은 scripts/custom/ 밑에 도구별 설치 스크립트로 분리해 둔다.
"$dir/installer/fasd.sh"
