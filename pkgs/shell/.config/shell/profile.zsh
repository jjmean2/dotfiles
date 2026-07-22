export FPATH

# 내가 직접 작성한 autoload 함수를 찾을 수 있도록 fpath에 추가한다.
# 사실 개인 autoload 함수는 대부분 대화형 세션에서 쓸 용도라서
# 굳이 여기에 넣을 필요가 있을까 싶기도 한다.
fpath=(~/.jongwan/share/zsh/site-functions $fpath)

# zsh에서는 변수 확장시 공백에서 word splitting 이 일어나지 않으므로 큰 따옴표로 감싸지 않아도 된다.
# 배열 변수의 경우에는 배열 요소를 경계로 요소가 나뉜다.

# The following lines have been added by Docker Desktop to enable Docker CLI completions.
if [[ -d $HOME/.docker/completions ]]; then
	fpath=($HOME/.docker/completions $fpath)
fi

# homebrew로 설치한 zsh-completions의 completion 함수들을 fpath에 추가
if command -v brew &>/dev/null; then
	fpath+=($(brew --prefix)/share/zsh-completions)
fi
