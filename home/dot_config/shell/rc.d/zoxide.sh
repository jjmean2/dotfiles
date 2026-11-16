# shellcheck shell=bash
# zoxide: 자주 간 디렉터리로 건너뛰기. https://github.com/ajeetdsouza/zoxide
#
#   z foo        foo 가 든 경로 중 자주·최근 간 디렉터리로 (z foo bar 처럼 조각 여러 개)
#   z foo<Space><Tab>   후보를 fzf 로 고른다
#   zi           기록 전체를 fzf 로 고른다
#   zoxide query -l -s   기록과 점수 보기 / zoxide remove <경로>  기록 지우기
#
# cd 는 바꾸지 않는다 (--cmd cd 를 쓰지 않는다). 디렉터리를 옮길 때마다 기록되므로 cd 로 다니면 z 가 배운다.
# 완성(compdef)을 등록하므로 compinit 뒤(rc.d)에 있어야 한다. init 출력은 몇 ms 라 캐시하지 않는다.
# 예전 fasd 기록 옮기기 (머신마다 한 번): zoxide import fasd --merge  (~/.fasd 를 읽는다)
if command -v zoxide >/dev/null 2>&1; then
	if [ -n "$ZSH_VERSION" ]; then
		eval "$(zoxide init zsh)"
	elif [ -n "$BASH_VERSION" ]; then
		eval "$(zoxide init bash)"
	fi
fi
