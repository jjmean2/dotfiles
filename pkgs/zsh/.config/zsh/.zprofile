# 환경 변수 및 도구별 환경 설정을 진행한다.
# shebang을 이용한 스크립트형 실행 파일이나 외부 도구에서 zsh를 이용해 실행할 때
# 필요에 따라 -l 옵션만 붙여서 실행하면 이 설정이 적용되도록 하기 위함이다.
# 대화형 세션에만 유용하고 설정이 무거울 수 있는 것들은 .zshrc에서 처리한다.
# 패키지 매니저 설정은 그 패키지로 설치한 도구들을 찾기 위해서 필요하므로 여기서 처리한다.

# ==================================================
# 🛠️ PATH, FPATH 및 도구별 환경 설정
# ==================================================
# fastlane 명령시 에러나지 않도록?
# https://docs.fastlane.tools/getting-started/ios/setup/#set-up-environment-variables
#export LANG=en_US.UTF-8
#export LANGUAGE=en_US.UTF-8
#export LC_ALL=en_US.UTF-8

# zsh에서는 변수 확장시 공백에서 word splitting 이 일어나지 않으므로 큰 따옴표로 감싸지 않아도 된다.
# 배열 변수의 경우에는 배열 요소를 경계로 요소가 나뉜다.
path=(/usr/local/bin $path)
path=($HOME/.local/bin $path)

# The following lines have been added by Docker Desktop to enable Docker CLI completions.
if [[ -d $HOME/.docker/completions ]]; then
	fpath=($HOME/.docker/completions $fpath)
fi

# homebrew로 설치한 zsh-completions의 completion 함수들을 fpath에 추가
if command -v brew &>/dev/null; then
	fpath+=($(brew --prefix)/share/zsh-completions)
fi

# corepack 설정
# Disable automatic package.json#packageManager field setting when using corepack
# https://github.com/nodejs/corepack/blob/main/README.md#environment-variables
export COREPACK_ENABLE_AUTO_PIN=0

# swiftly
if [[ -f $HOME/.swiftly/env.sh ]]; then
	source "$HOME/.swiftly/env.sh"
fi

# SDKMAN
#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
if [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
	export SDKMAN_DIR="$HOME/.sdkman"
	source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

# cargo
if [[ -f $HOME/.cargo/env ]]; then
	source "$HOME/.cargo/env"
fi

# Toolbox App
if [[ -d "$HOME/Library/Application Support/JetBrains/Toolbox/scripts" ]]; then
	path=("$HOME/Library/Application Support/JetBrains/Toolbox/scripts" $path)
fi

if [[ -d $HOME/.pixi/bin ]]; then
	path=($HOME/.pixi/bin $path)
fi

if [[ -d /opt/homebrew/share/git-core/contrib/diff-highlight ]]; then
	path=(/opt/homebrew/share/git-core/contrib/diff-highlight $path)
fi

# LM Studio CLI (lms)
if [[ -d $HOME/.lmstudio/bin ]]; then
	path=($HOME/.lmstudio/bin $path)
fi

# mozjpeg KEG-only
if [[ -d /opt/homebrew/opt/mozjpeg/bin ]]; then
	path=(/opt/homebrew/opt/mozjpeg/bin $path)
fi

if [[ -d $HOME/vcpkg ]]; then
	export VCPKG_ROOT="$HOME/vcpkg"
fi

if [[ -d $HOME/.bun ]]; then
	# bun global install
	export BUN_INSTALL="$HOME/.bun"
	path=("$BUN_INSTALL/bin" $path)

	# bun completions
	if [[ -s $HOME/.bun/_bun ]]; then
		source "$HOME/.bun/_bun"
	fi
fi

# Antigravity
if [[ -d $HOME/.antigravity/antigravity/bin ]]; then
	path=($HOME/.antigravity/antigravity/bin $path)
fi

# 🛠️ 📦 zprofile.d 디렉터리 설정 파일 로드
if [[ -d $ZDOTDIR/zprofile.d ]]; then
	# .zsh로 끝나는 파일만 로드 (알파벳/숫자 순서)
	# (D)는 숨김 파일을 포함, (N)은 매칭 결과가 없어도 에러를 내지 않음
	for config_file in $ZDOTDIR/zprofile.d/*.zsh(DN); do
		source "$config_file"
	done
fi
unset config_file

# 개인 도구 경로, 우선순위 가장 높게 설정
# 개인 도구는 대부분 대화형 세션에서 내 편의를 위해 사용하는 용도긴 하다.
# 비대화형 스크립트에서는 표준 도구를 주로 사용할 것이므로 이 부분이 필요 없을 수도 있지만,
# 일단은 추가해 놓는다. 우선 순위를 최대한 높이기 위해 interactive 여부에 따라
# PATH 설정의 가장 마지막 단계에 실행되도록 양쪽에 다 추가함
if ! [[ -o interactive ]]; then
	path=($HOME/.jongwan/bin $path)
fi
