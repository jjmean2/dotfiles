# shellcheck shell=sh
# vcpkg (C/C++ 패키지 매니저). 빌드 도구가 이 변수로 위치를 찾는다.
if [ -d "$HOME/vcpkg" ]; then
	export VCPKG_ROOT="$HOME/vcpkg"
fi
