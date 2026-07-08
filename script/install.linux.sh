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

# 설치할 도구 목록. 새 도구를 추가하려면 tools 와 default_pkg 에 한 줄씩만 추가하면 된다.
tools=(rg fd jq nvim)

# 배포판 대부분에서 공통으로 쓰는 패키지 이름.
declare -A default_pkg=(
	[rg]=ripgrep
	[fd]=fd
	[jq]=jq
	[nvim]=neovim
)

# default_pkg 와 다른 이름을 쓰는 배포판만 예외로 등록한다. (apt/dnf 는 fd-find 라는 이름을 쓴다)
declare -A pkg_name=(
	[apt:fd]=fd-find
	[dnf:fd]=fd-find
)

# $1: 배포판 식별자(apt/apk/dnf/pacman). tools 중 아직 설치되지 않은 것들의
# 패키지 이름을 한 줄씩 출력한다.
missing_packages() {
	local manager="$1" tool
	for tool in "${tools[@]}"; do
		has "$tool" || echo "${pkg_name[$manager:$tool]:-${default_pkg[$tool]}}"
	done
}

# $1: 배포판 식별자, 나머지 인자: 패키지 매니저 install 커맨드.
# 설치할 패키지가 없으면 아무 것도 하지 않는다.
install_missing() {
	local manager="$1"
	shift

	local -a pkgs=()
	while IFS= read -r pkg; do
		pkgs+=("$pkg")
	done < <(missing_packages "$manager")

	[ "${#pkgs[@]}" -eq 0 ] && return 0

	as_root "$@" "${pkgs[@]}"
}

# 배포판별 패키지 매니저를 순서대로 감지해서 사용한다.
# dev container 는 Debian/Ubuntu(apt) 계열이 가장 흔하고, 경량 이미지는 Alpine(apk) 인 경우가 많아
# 둘을 우선 확인하고, RHEL/Fedora(dnf), Arch(pacman) 를 뒤이어 지원한다.
if has apt-get; then
	if [ -n "$(missing_packages apt)" ]; then
		as_root env DEBIAN_FRONTEND=noninteractive apt-get update
	fi
	install_missing apt env DEBIAN_FRONTEND=noninteractive apt-get install -y
elif has apk; then
	install_missing apk apk add --no-cache
elif has dnf; then
	install_missing dnf dnf install -y
elif has pacman; then
	install_missing pacman pacman -Sy --noconfirm --needed
else
	echo "지원하는 패키지 매니저(apt, apk, dnf, pacman)를 찾지 못했습니다." >&2
	exit 1
fi

# fd-find 패키지는 배포판에 따라 바이너리 이름이 fdfind 인 경우가 있어 fd 로 심볼릭 링크를 만들어 준다.
if ! has fd && has fdfind; then
	as_root ln -sf "$(command -v fdfind)" /usr/local/bin/fd
fi

echo "Linux 기본 도구 설치 완료: ${tools[*]}"
