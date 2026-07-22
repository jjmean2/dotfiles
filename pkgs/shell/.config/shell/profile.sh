# shellcheck shell=sh disable=SC1091

# # 로그인 쉘의 초기화 스크립트
# - PATH 설정 (외부 도구 찾기)
# - FPATH 설정 (autoload 함수, 자동완성 함수 찾기)
# - 그외 여러 가지 환경변수 설정 (여러 도구에서 사용할 변수들)
# - 외부 패키지 도구들이 위의 설정들을 진행하는 초기화 스크립트 source

# shebang을 이용한 스크립트형 실행 파일이나 외부 도구에서 zsh를 이용해 실행할 때
# 필요에 따라 -l 옵션만 붙여서 실행하면 이 설정이 적용되도록 하기 위함이다.
# 대화형 세션에만 유용하고 설정이 무거울 수 있는 것들은 .zshrc에서 처리한다.
# 패키지 매니저 설정은 그 패키지로 설치한 도구들을 찾기 위해서 필요하므로 여기서 처리한다.

# ==================================================
# 🛠️ 기본 환경변수 설정
# ==================================================
# fastlane 명령시 에러나지 않도록?
# https://docs.fastlane.tools/getting-started/ios/setup/#set-up-environment-variables
#export LANG=en_US.UTF-8
#export LANGUAGE=en_US.UTF-8
#export LC_ALL=en_US.UTF-8

# ==================================================
# 🛠️ PATH 설정 및 도구 초기화 스크립트 로드
# ==================================================
export PATH

PATH="/usr/local/bin:$PATH"

# Homebrew로 설치된 도구들을 찾을 수 있게 한다.
# setup for homebrew
if [ -f /opt/homebrew/bin/brew ]; then
	eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -f /usr/local/bin/brew ]; then
	eval "$(/usr/local/bin/brew shellenv)"
fi

# mise로 설치한 도구들을 찾을 수 있게 한다. interactive session이라면 여기 대신
# .zshrc에서 디렉토리 변경 hook 에서 동적으로 PATH를 처리하도록 한다.
# setup for non-interactive sessions of mise
# https://mise.en.dev/dev-tools/shims.html#how-to-add-mise-shims-to-path
if command -v mise >/dev/null 2>&1; then
	case "$-" in
	*i*) ;;
	*)
		if [ -n "$ZSH_VERSION" ]; then
			eval "$(mise activate zsh --shims)"
		elif [ -n "$BASH_VERSION" ]; then
			eval "$(mise activate bash --shims)"
		fi
		;;
	esac
fi

PATH="$HOME/.local/bin:$PATH"

# swiftly
if [ -f "$HOME/.swiftly/env.sh" ]; then
	. "$HOME/.swiftly/env.sh"
fi

# SDKMAN
#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
	export SDKMAN_DIR="$HOME/.sdkman"
	. "$HOME/.sdkman/bin/sdkman-init.sh"
fi

# cargo
if [ -f "$HOME/.cargo/env" ]; then
	. "$HOME/.cargo/env"
fi

# Toolbox App
if [ -d "$HOME/Library/Application Support/JetBrains/Toolbox/scripts" ]; then
	PATH="$HOME/Library/Application Support/JetBrains/Toolbox/scripts:$PATH"
fi

if [ -d "$HOME/.pixi/bin" ]; then
	PATH="$HOME/.pixi/bin:$PATH"
fi

if [ -d "$HOMEBREW_PREFIX/share/git-core/contrib/diff-highlight" ]; then
	PATH="$HOMEBREW_PREFIX/share/git-core/contrib/diff-highlight:$PATH"
fi

# LM Studio CLI (lms)
if [ -d "$HOME/.lmstudio/bin" ]; then
	PATH="$HOME/.lmstudio/bin:$PATH"
fi

# mozjpeg KEG-only
if [ -d "$HOMEBREW_PREFIX/opt/mozjpeg/bin" ]; then
	PATH="$HOMEBREW_PREFIX/opt/mozjpeg/bin:$PATH"
fi

# Antigravity
if [ -d "$HOME/.antigravity/antigravity/bin" ]; then
	PATH="$HOME/.antigravity/antigravity/bin:$PATH"
fi

if [ -d "$HOME/.bun" ]; then
	# bun global install
	export BUN_INSTALL="$HOME/.bun"
	PATH="$BUN_INSTALL/bin:$PATH"

	# bun completions
	if [ -s "$HOME/.bun/_bun" ]; then
		. "$HOME/.bun/_bun"
	fi
fi

if [ -d "$HOME/Library/Android/sdk" ]; then
	# Android SDK tools
	export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
	PATH="$ANDROID_SDK_ROOT/emulator:$PATH"
	PATH="$ANDROID_SDK_ROOT/platform-tools:$PATH"
	PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$PATH"
fi

if [ -d "$HOMEBREW_PREFIX/opt/llvm" ]; then
	# clang, clang++ 등을 연결하기 위함. 최신 기능이 필요없다면, 다음 라인들은 주석처리할 것
	PATH="$HOMEBREW_PREFIX/opt/llvm/bin:$PATH"
	export LDFLAGS="-L$HOMEBREW_PREFIX/opt/llvm/lib"
	export CPPFLAGS="-I$HOMEBREW_PREFIX/opt/llvm/include"
	export CMAKE_PREFIX_PATH="$HOMEBREW_PREFIX/opt/llvm"
fi

# Google Cloud SDK
# The next line updates PATH for the Google Cloud SDK.
if [ -n "$ZSH_VERSION" ]; then
	[ -f "$HOME/dev/toolbox/google-cloud-sdk/path.zsh.inc" ] &&
		. "$HOME/dev/toolbox/google-cloud-sdk/path.zsh.inc"
elif [ -n "$BASH_VERSION" ]; then
	[ -f "$HOME/dev/toolbox/google-cloud-sdk/path.bash.inc" ] &&
		. "$HOME/dev/toolbox/google-cloud-sdk/path.bash.inc"
fi

if [ -d "$HOME/Library/pnpm" ] || return 0; then
	export PNPM_HOME="$HOME/Library/pnpm"
	PATH="$PNPM_HOME/bin:$PATH"
fi

# ==================================================
# 🛠️ 그 외 환경변수 설정
# ==================================================

# corepack 설정
# Disable automatic package.json#packageManager field setting when using corepack
# https://github.com/nodejs/corepack/blob/main/README.md#environment-variables
if command -v corepack >/dev/null 2>&1; then
	export COREPACK_ENABLE_AUTO_PIN=0
fi

if [ -d "$HOME/vcpkg" ]; then
	export VCPKG_ROOT="$HOME/vcpkg"
fi

# ==================================================
# 🛠️ Zsh 전용 설정 로드
# ==================================================
if [ -n "$ZSH_VERSION" ]; then
	[ -f "$HOME/.config/shell/profile.zsh" ] && . "$HOME/.config/shell/profile.zsh"
fi

# ==================================================
# 🛠️ 개인 도구 PATH 설정
# ==================================================
# 개인 도구 경로, 우선순위 가장 높게 설정
# 개인 도구는 대부분 대화형 세션에서 내 편의를 위해 사용하는 용도긴 하다.
# 비대화형 스크립트에서는 표준 도구를 주로 사용할 것이므로 이 부분이 필요 없을 수도 있지만,
# 일단은 추가해 놓는다. 우선 순위를 최대한 높이기 위해 interactive 여부에 따라
# PATH 설정의 가장 마지막 단계에 실행되도록 양쪽에 다 추가함
case $- in
*i*) ;;
*) PATH="$HOME/.jongwan/bin:$PATH" ;;
esac
