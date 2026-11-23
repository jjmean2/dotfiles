# shellcheck shell=bash
# wtp: 브랜치 이름 일부로 그 브랜치가 체크아웃된 워크트리를 찾는다 (~/.jongwan/bin/wtp).
#
#   wcd foo      브랜치 이름에 foo 가 든 워크트리로 cd (여럿이면 fzf 로 고른다)
#   wcd          체크아웃된 브랜치 전체에서 고른다
#   wcd -m       main 워크트리로
#   wcd <Tab>    체크아웃된 브랜치 이름 완성 (부분 일치)
#
# 함수와 완성은 `wtp init` 이 만든 것을 eval 한다. 완성(compdef)을 등록하므로 compinit 뒤(rc.d)에 있어야 한다.
if command -v wtp >/dev/null 2>&1; then
	if [ -n "$ZSH_VERSION" ]; then
		eval "$(wtp init zsh)"
	elif [ -n "$BASH_VERSION" ]; then
		eval "$(wtp init bash)"
	fi
fi
