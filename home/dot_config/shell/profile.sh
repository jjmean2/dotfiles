# shellcheck shell=sh disable=SC1091,SC1090

# # 로그인 쉘의 초기화 스크립트 (뼈대)
# - PATH 설정 (외부 도구 찾기)
# - FPATH 설정 (autoload 함수, 자동완성 함수 찾기)
# - 그외 여러 가지 환경변수 설정 (여러 도구에서 사용할 변수들)
# - 외부 패키지 도구들이 위의 설정들을 진행하는 초기화 스크립트 source

# shebang을 이용한 스크립트형 실행 파일이나 외부 도구에서 zsh를 이용해 실행할 때
# 필요에 따라 -l 옵션만 붙여서 실행하면 이 설정이 적용되도록 하기 위함이다.
# 대화형 세션에만 유용하고 설정이 무거울 수 있는 것들은 rc.sh 에서 처리한다.
# 패키지 매니저 설정은 그 패키지로 설치한 도구들을 찾기 위해서 필요하므로 여기서 처리한다.
#
# 구조: 이 파일에는 다른 것이 기대는 것만 순서대로 둔다 (기본 PATH → brew → mise → 개인 도구 PATH).
# 도구 하나의 환경(PATH 한 줄, 환경변수)은 profile.d/<도구>.sh 에 따로 두고, 각 파일이 그 도구가
# 깔려 있는지 스스로 확인한다. 이 머신에만 필요한 것은 관리 밖 profile.d/<이름>.local.sh 에 둔다.
# 읽는 순서와 규칙은 load-dir.sh.

# ==================================================
# 🛠️ 기본 환경변수 설정
# ==================================================
# fastlane 명령시 에러나지 않도록?
# https://docs.fastlane.tools/getting-started/ios/setup/#set-up-environment-variables
#export LANG=en_US.UTF-8
#export LANGUAGE=en_US.UTF-8
#export LC_ALL=en_US.UTF-8

# ==================================================
# 🛠️ PATH 설정 (뼈대: 아래 profile.d 의 도구들이 기대는 것)
# ==================================================
export PATH

PATH="/usr/local/bin:$PATH"

# Homebrew로 설치된 도구들을 찾을 수 있게 한다. ($HOMEBREW_PREFIX 도 여기서 정해진다)
# setup for homebrew
if [ -f /opt/homebrew/bin/brew ]; then
	eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -f /usr/local/bin/brew ]; then
	eval "$(/usr/local/bin/brew shellenv)"
fi

# mise로 설치한 도구들을 찾을 수 있게 한다. interactive session이라면 여기 대신
# rc.sh 에서 디렉토리 변경 hook 에서 동적으로 PATH를 처리하도록 한다.
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

# 임시 서버 래퍼(저장소 루트의 jw-ephemeral)가 sudo 없이 설치한 필수 도구. 래퍼로 설치한 서버에만 있고,
# jw-ephemeral uninstall 이 디렉터리째 지운다. 시스템 도구보다 앞에 둔다.
if [ -d "${XDG_STATE_HOME:-$HOME/.local/state}/jw-ephemeral/bin" ]; then
	PATH="${XDG_STATE_HOME:-$HOME/.local/state}/jw-ephemeral/bin:$PATH"
fi

# nvim 설정 고르기: LazyVim(~/.config/nvim)이 없고 플러그인 없는 nvim-lite 만 있으면 그것을 쓴다.
# features.ide 를 끈 머신(임시 서버·dev container)이 그렇다. NVIM_APPNAME 은 nvim 이 읽을 설정·데이터
# 디렉터리 이름을 정한다 (:h NVIM_APPNAME). 비대화형(git 의 EDITOR 등)에도 필요해서 profile 에 둔다.
if [ ! -e "${XDG_CONFIG_HOME:-$HOME/.config}/nvim/init.lua" ] &&
	[ -e "${XDG_CONFIG_HOME:-$HOME/.config}/nvim-lite/init.lua" ]; then
	export NVIM_APPNAME=nvim-lite
fi

# ==================================================
# 🛠️ Zsh 전용 설정 로드 (fpath)
# ==================================================
if [ -n "$ZSH_VERSION" ]; then
	[ -f "$HOME/.config/shell/profile.zsh" ] && . "$HOME/.config/shell/profile.zsh"
fi

# ==================================================
# 🛠️ 도구별 환경: profile.d/
# ==================================================
# PATH 는 나중에 넣은 것이 앞에 오므로, 나중에 읽힌 파일의 도구가 같은 이름의 명령에서 이긴다.
_jw_dir="$HOME/.config/shell/profile.d"
. "$HOME/.config/shell/load-dir.sh"

# ==================================================
# 🛠️ 개인 도구 PATH 설정
# ==================================================
# 개인 도구 경로, 우선순위 가장 높게 설정
# 개인 도구는 대부분 대화형 세션에서 내 편의를 위해 사용하는 용도긴 하다.
# 비대화형 스크립트에서는 표준 도구를 주로 사용할 것이므로 이 부분이 필요 없을 수도 있지만,
# 일단은 추가해 놓는다. 우선 순위를 최대한 높이기 위해 interactive 여부에 따라
# PATH 설정의 가장 마지막 단계에 실행되도록 양쪽에 다 추가함
# tmux-dev 플러그인(~/.config/tmux/plugins/tmux-dev)의 명령도 셸에서 쓸 수 있게 bin 을 함께 넣는다
case $- in
*i*) ;;
*) PATH="$HOME/.jongwan/bin:$HOME/.config/tmux/plugins/tmux-dev/bin:$PATH" ;;
esac
