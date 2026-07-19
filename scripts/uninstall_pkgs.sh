#!/usr/bin/env bash
set -euo pipefail

# pkgs/<tool>/ 밑의 stow 패키지들을 전부 제거한다. 패키지 하나를 제거하는 실제 로직은
# pkgs/local/.jongwan/bin/jw-stow(설치 후에는 ~/.jongwan/bin/jw-stow)에 있고, 여기서는
# pkgs/ 밑의 모든 패키지 이름을 모아서 그 스크립트에 넘기기만 한다.
# 패키지 하나만 제거하고 싶다면 jw-stow -d <pkg> 를 직접 실행하면 된다.

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"
pkgs_dir="$dir/pkgs"
jw_stow="$pkgs_dir/local/.jongwan/bin/jw-stow"

pkgs=()
for pkg_path in "$pkgs_dir"/*/; do
	pkgs+=("$(basename "$pkg_path")")
done

"$jw_stow" -d "${pkgs[@]}"

echo "pkgs 제거 완료"
