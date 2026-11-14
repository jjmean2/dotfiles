# shellcheck shell=sh
# git 에 딸려 오는 diff-highlight (줄 안에서 바뀐 부분 강조). ~/.config/git/config.darwin 의 pager 가 쓴다.
if [ -d "$HOMEBREW_PREFIX/share/git-core/contrib/diff-highlight" ]; then
	PATH="$HOMEBREW_PREFIX/share/git-core/contrib/diff-highlight:$PATH"
fi
