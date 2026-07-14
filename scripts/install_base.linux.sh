#!/usr/bin/env bash
set -euo pipefail

# Linux(주로 dev container) 환경에 필요한 최소한의 도구를 설치한다.
# 배포판마다 다른 패키지 매니저를 자동으로 감지해서 사용하고,
# 이미 설치되어 있는 도구는 건너뛰므로 여러 번 실행해도 안전하다(멱등).

has() { command -v "$1" &>/dev/null; }

as_root() {
	if [ "$(id -u)" -eq 0 ]; then
		"$@"
	else
		sudo "$@"
	fi
}

# 설치할 도구 목록. 새 도구를 추가하려면 여기에 이름만 추가하면 되고,
# 패키지 이름/실행파일 이름이 도구 이름과 다를 때만 아래 테이블에 예외를 등록한다.
tools=(rg fd jq stow tree-sitter-cli)

# 도구의 기본 패키지 이름이 tools 의 이름과 다를 때만 등록한다. (배포판 공통)
# 실행파일 이름은 tools 자체가 canonical bin 이름이므로 별도 기본값 테이블이 필요 없다.
declare -A default_pkg=(
	[rg]=ripgrep
	[nvim]=neovim
)

# 특정 배포판(apt/apk/dnf/pacman)만 위 기본값과 다를 때만 등록한다.
# apt/dnf 의 fd 는 패키지 이름이 fd-find 이고, 실행파일도 fdfind 라는 이름으로 설치된다.
declare -A pkg_override=(
	[apt:fd]=fd-find
	[dnf:fd]=fd-find
)
declare -A bin_override=(
	[apt:fd]=fdfind
	[dnf:fd]=fdfind
)

# $1: 배포판 식별자, $2: 도구 이름 -> 설치해야 할 패키지 이름
resolve_pkg() { echo "${pkg_override[$1:$2]:-${default_pkg[$2]:-$2}}"; }
# $1: 배포판 식별자, $2: 도구 이름 -> 설치되는 실행파일 이름
resolve_bin() { echo "${bin_override[$1:$2]:-$2}"; }

# $1: 배포판 식별자(apt/apk/dnf/pacman). tools 중 아직 설치되지 않은 것들의
# 패키지 이름을 한 줄씩 출력한다.
missing_packages() {
	local manager="$1" tool
	for tool in "${tools[@]}"; do
		has "$(resolve_bin "$manager" "$tool")" || resolve_pkg "$manager" "$tool"
	done
}

# tools 중 실행파일 이름이 도구 이름과 다르게 설치된 것을, 도구 이름으로 심볼릭 링크한다.
# (예: fd-find 패키지는 fdfind 라는 이름으로 설치되므로 fd 로 연결)
link_renamed_bins() {
	local manager="$1" tool bin
	for tool in "${tools[@]}"; do
		bin="$(resolve_bin "$manager" "$tool")"
		if [ "$bin" != "$tool" ] && ! has "$tool" && has "$bin"; then
			as_root ln -sf "$(command -v "$bin")" "/usr/local/bin/$tool"
		fi
	done
}

# 배포판별 패키지 매니저를 순서대로 감지해서 사용한다.
# dev container 는 Debian/Ubuntu(apt) 계열이 가장 흔하고, 경량 이미지는 Alpine(apk) 인 경우가 많아
# 둘을 우선 확인하고, RHEL/Fedora(dnf), Arch(pacman) 를 뒤이어 지원한다.
if has apt-get; then
	manager=apt
elif has apk; then
	manager=apk
elif has dnf; then
	manager=dnf
elif has pacman; then
	manager=pacman
else
	echo "지원하는 패키지 매니저(apt, apk, dnf, pacman)를 찾지 못했습니다." >&2
	exit 1
fi

mapfile -t pkgs < <(missing_packages "$manager")

# 설치할 패키지가 있을 때만 매니저를 건드린다. (없으면 apt-get update 같은 네트워크 호출도 스킵)
if [ "${#pkgs[@]}" -gt 0 ]; then
	case "$manager" in
	apt)
		as_root env DEBIAN_FRONTEND=noninteractive apt-get update
		as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "${pkgs[@]}"
		;;
	apk)
		as_root apk add --no-cache "${pkgs[@]}"
		;;
	dnf)
		as_root dnf install -y "${pkgs[@]}"
		;;
	pacman)
		as_root pacman -Sy --noconfirm --needed "${pkgs[@]}"
		;;
	esac
fi

link_renamed_bins "$manager"

dir="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

"$dir/installer/nvim-linux.sh"

has mise || curl https://mise.run | sh

echo "Linux 기본 도구 설치 완료: ${tools[*]}"
