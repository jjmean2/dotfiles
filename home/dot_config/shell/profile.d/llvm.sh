# shellcheck shell=sh
# brew 로 설치한 llvm (keg-only). clang, clang++ 등을 시스템 것 대신 쓰고, 빌드 도구가 그 라이브러리를 찾게 한다.
# brew 의 llvm 이 깔려 있을 때만 적용된다.
if [ -d "$HOMEBREW_PREFIX/opt/llvm" ]; then
	PATH="$HOMEBREW_PREFIX/opt/llvm/bin:$PATH"
	export LDFLAGS="-L$HOMEBREW_PREFIX/opt/llvm/lib"
	export CPPFLAGS="-I$HOMEBREW_PREFIX/opt/llvm/include"
	export CMAKE_PREFIX_PATH="$HOMEBREW_PREFIX/opt/llvm"
fi
