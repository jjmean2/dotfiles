# bun 의 zsh 완성 스크립트 ~/.bun/_bun. 이 파일이 있는 머신에서만 읽힌다.
# (fpath 디렉터리에 _bun 이 있는 머신은 그것으로 완성이 잡히므로 이 파일이 없어도 된다.)
#
# _bun 은 끝에서 compdef 를 부르고, compinit 이 아직 안 돌았으면 스스로 돌린다. 그래서 로그인 단계(profile.d)가
# 아니라 compinit 뒤(rc.d)에서 읽는다. 앞에서 읽으면 compinit 이 두 번 돌고, fpath 가 덜 찬 상태로 만든
# 완성 표가 캐시에 남는다. zsh 문법이라 bash 는 읽으면 안 되므로 확장자가 .zsh 다.
if [[ -s $HOME/.bun/_bun ]]; then
	source "$HOME/.bun/_bun"
fi
