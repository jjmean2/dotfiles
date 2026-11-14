# shellcheck shell=sh disable=SC1091
# swiftly (Swift 툴체인 관리자). env.sh 가 ~/.swiftly/bin 을 PATH 에 넣는다.
#
# 이름에 숫자가 붙은 이유: 다른 도구보다 먼저 읽혀서 PATH 에서 뒤에 서야 한다. ~/.swiftly/bin 에는
# clang, cc, ar 같은 이름이 들어 있어서, 나중에 읽히면 llvm.sh 의 clang 등 다른 도구의 같은 이름을 가린다.
if [ -f "$HOME/.swiftly/env.sh" ]; then
	. "$HOME/.swiftly/env.sh"
fi
