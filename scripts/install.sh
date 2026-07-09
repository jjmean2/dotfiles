#!/usr/bin/env bash
set -euo pipefail

# 개발 환경을 한 번에 설정한다: 기본 도구 설치(install_base.sh) 후
# pkgs 를 stow 로 설치한다(install_pkgs.sh).

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

"$dir/install_base.sh"
"$dir/install_pkgs.sh"

echo "설치 완료"
