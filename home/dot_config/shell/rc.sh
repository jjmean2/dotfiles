# shellcheck shell=bash disable=SC1091,SC1090

# # 대화형 쉘의 초기화 스크립트 (뼈대)
#
# 구조: 이 파일에는 다른 것이 기대는 것과 셸 자체의 설정만 순서대로 둔다.
#   1. PATH        mise 활성화 → 개인 도구
#   2. 셸 공통     에디터, alias, 함수
#   3. 셸 전용     rc.zsh / rc.bash (프롬프트, 옵션, 키, 완성 시스템 초기화)
#   4. rc.d/       도구별 대화형 초기화 (fzf, fasd 등). 프롬프트와 완성 시스템이 준비된 뒤에 읽힌다
#   5. terminal/   터미널별 셸 통합 (iTerm2, tmux). 프롬프트와 훅이 다 갖춰진 뒤 맨 나중에 얹는다
#   6. 맨 끝이어야 하는 것 (SDKMAN)
# 도구 하나의 초기화는 rc.d/<도구>.sh 에, 터미널 하나의 통합은 terminal/<터미널>.<셸> 에 따로 두고,
# 각 파일이 자기 조건(도구가 깔렸는지, 그 터미널 안인지)을 스스로 확인한다. 이 머신에만 필요한 것은
# 관리 밖 rc.d/<이름>.local.sh 에 둔다. 읽는 순서와 규칙은 load-dir.sh.

# ==================================================
# 🕹️ PATH 설정
# ==================================================

# cd를 할 때마다 PATH를 변경하는 hook을 등록한다.
# 이 방식은 대화형 세션에서만 사용하고,
# 비대화형 세션에서는 shims 방식을 쓰도록 profile.sh 에서 설정함
# mise shell activation
if command -v mise >/dev/null 2>&1; then
	if [ -n "$ZSH_VERSION" ]; then
		eval "$(mise activate zsh)"
	elif [ -n "$BASH_VERSION" ]; then
		eval "$(mise activate bash)"
	fi
fi

# jw-ephemeral 이 설치한 필수 도구 (profile.sh 참고). 위 mise activate 가 PATH 를 다시 짜면 시스템 도구가
# 앞으로 올 수 있어서 여기서 다시 앞에 넣는다.
if [ -d "${XDG_STATE_HOME:-$HOME/.local/state}/jw-ephemeral/bin" ]; then
	PATH="${XDG_STATE_HOME:-$HOME/.local/state}/jw-ephemeral/bin:$PATH"
fi

# 개인 도구 경로, 우선순위 가장 높게 설정 (+ tmux-dev 플러그인의 bin: tmux-dev project|worktree)
PATH="$HOME/.jongwan/bin:$HOME/.config/tmux/plugins/tmux-dev/bin:$PATH"

# ==================================================
# 🕹️ 터미널 설정
# ==================================================
if command -v nvim >/dev/null 2>&1; then
	# 참고:
	# VISUAL은 화면 전체를 사용하는 에디터를 의미하고,
	# EDITOR는 한 줄씩 편집하던 옛날 방식(ed 등)과의 호환성을 위한 것인데,
	# 현대에는 보통 둘 다 똑같이 설정합니다.
	# EDITOR만 설정해도 되는데, VISUAL, EDITOR 둘다 설정한 경우, edit-command-line 기능은 VISUAL 값을 따름
	# export VISUAL='nvim'
	export EDITOR='nvim'

	# 플러그인 없는 nvim (~/.config/nvim-lite). LazyVim 이 있는 머신에서도 가볍게 열고 싶을 때 쓴다.
	# LazyVim 이 없는 머신에서는 profile.sh 가 NVIM_APPNAME 을 정해 두어 nvim 자체가 이것이다.
	alias nvim-lite='NVIM_APPNAME=nvim-lite nvim'

	if [ -n "$ZSH_VERSION" ]; then
		bindkey -e
	elif [ -n "$BASH_VERSION" ]; then
		:
	fi
fi

# 터미널 색상 활성화
export CLICOLOR=1
export LSCOLORS=gxBxhxDxfxhxhxhxhxcxcx

# ==================================================
# 🕹️ alias 설정
# ==================================================
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

alias egit='LC_ALL=C git'
alias grep='grep --color=auto'

if command -v yarn >/dev/null 2>&1; then
	alias yarn-sdks='yarn dlx @yarnpkg/sdks vscode'
fi

if [ -f /Applications/MacVim.app/Contents/MacOS/Vim ]; then
	alias mvim='/Applications/MacVim.app/Contents/MacOS/Vim -g'
fi

if [ -f '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome' ]; then
	alias chrome='"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"'
fi


if [ -f /usr/libexec/PlistBuddy ]; then
	alias PlistBuddy='/usr/libexec/PlistBuddy'
fi

# Shell Title
# alias title='printf "\033]0;%s\007"'
#printf "\033]0;`date "+%a %d %b %Y %I:%M %p"`\007"

# ==================================================
# 🕹️ 함수 정의 모음 (functions.sh 와 functions.d/)
# ==================================================
if [ -f "$HOME/.config/shell/functions.sh" ]; then
	. "$HOME/.config/shell/functions.sh"
fi

# ==================================================
# 🛠️ Shell 별 전용 설정 로드 (프롬프트, 키, completion 시스템 초기화는 여기서 진행)
# ==================================================

if [ -n "$ZSH_VERSION" ]; then
	[ -f "$HOME/.config/shell/rc.zsh" ] && . "$HOME/.config/shell/rc.zsh"
elif [ -n "$BASH_VERSION" ]; then
	[ -f "$HOME/.config/shell/rc.bash" ] && . "$HOME/.config/shell/rc.bash"
fi

# ==================================================
# 🛠️ 도구별 대화형 초기화: rc.d/
# ==================================================
_jw_dir="$HOME/.config/shell/rc.d"
. "$HOME/.config/shell/load-dir.sh"

# ==================================================
# 🪄 터미널별 셸 통합: terminal/
# ==================================================
# 셸이 대화하는 터미널마다 파일 하나 (iterm2.zsh, tmux.zsh 등). 터미널을 더하려면 파일을 넣는다.
# Ghostty 는 띄우는 셸에 통합을 스스로 주입하므로 파일이 없다.
_jw_dir="$HOME/.config/shell/terminal"
. "$HOME/.config/shell/load-dir.sh"

# ==================================================
# 🛠️ 맨 끝이어야 하는 것
# ==================================================

# SDKMAN
#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
	export SDKMAN_DIR="$HOME/.sdkman"
	. "$HOME/.sdkman/bin/sdkman-init.sh"
fi
