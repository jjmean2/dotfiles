#!/usr/bin/env bash
set -euo pipefail

# pkgs/<tool>/ 밑의 stow 패키지들을 설치한다.
# - "local" 패키지는 ~/.jongwan 을 타깃으로 하고 --no-folding 으로 설치해서
#   로컬에서 자유롭게 수정할 수 있게 한다.
# - 그 외 패키지는 ~ 를 타깃으로 기본 폴딩을 사용한다.
# - 현재 OS 와 반대되는 플랫폼 전용 파일(*.darwin / *.linux)은 심링크를 만들지 않는다.
# 여러 번 실행해도 안전하도록 --restow 를 사용한다(멱등).

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"
pkgs_dir="$dir/pkgs"

if ! command -v stow &>/dev/null; then
	echo "stow 명령을 찾을 수 없습니다. 먼저 설치해 주세요 (예: brew install stow)." >&2
	exit 1
fi

case "$(uname -s)" in
Darwin) other_os=linux ;;
Linux) other_os=darwin ;;
*)
	echo "지원하지 않는 OS 입니다: $(uname -s)" >&2
	exit 1
	;;
esac

# local 패키지의 타깃 자체이므로 항상 실제 디렉토리로 미리 만들어둔다
# (stow 는 --target 디렉토리가 미리 존재해야 한다).
mkdir -p "$HOME/.jongwan"

# 그 외 패키지들의 최상위 디렉토리 항목(예: .config, .jongwan)은 여러 패키지가 같은
# 이름을 공유할 수 있으므로, stow 가 통째로 심링크로 접어버리지 않도록 실제 디렉토리로
# 미리 만들어둔다. 그 아래 단계(예: .config/nvim)는 그대로 폴딩되므로 도구별 심링크 하나로
# 접히는 이점은 유지된다. local 패키지는 --no-folding 이라 애초에 폴딩되지 않으므로 제외한다.
for pkg_path in "$pkgs_dir"/*/; do
	pkg="$(basename "$pkg_path")"
	[ "$pkg" = local ] && continue

	while IFS= read -r -d '' entry; do
		mkdir -p "$HOME/$(basename "$entry")"
	done < <(find "$pkg_path" -mindepth 1 -maxdepth 1 -type d -print0)
done

for pkg_path in "$pkgs_dir"/*/; do
	pkg="$(basename "$pkg_path")"

	if [ "$pkg" = local ]; then
		stow --dir="$pkgs_dir" --target="$HOME/.jongwan" --ignore="\\.${other_os}\$" --no-folding --restow "$pkg"
		echo "설치됨: $pkg -> ~/.jongwan (--no-folding)"
	else
		stow --dir="$pkgs_dir" --target="$HOME" --ignore="\\.${other_os}\$" --restow "$pkg"
		echo "설치됨: $pkg -> ~"
	fi
done

echo "pkgs 설치 완료"
