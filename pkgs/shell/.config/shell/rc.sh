# shellcheck shell=bash disable=SC1091,SC1090

# ==================================================
# 🕹️ PATH 설정
# ==================================================

# cd를 할 때마다 PATH를 변경하는 hook을 등록한다.
# 이 방식은 대화형 세션에서만 사용하고,
# 비대화형 세션에서는 shims 방식을 쓰도록 .zshenv에서 설정함
# mise shell activation
if command -v mise >/dev/null 2>&1; then
	if [ -n "$ZSH_VERSION" ]; then
		eval "$(mise activate zsh)"
	elif [ -n "$BASH_VERSION" ]; then
		eval "$(mise activate bash)"
	fi
fi

# 개인 도구 경로, 우선순위 가장 높게 설정
PATH="$HOME/.jongwan/bin:$PATH"

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
# 🕹️ 도구 초기화
# ==================================================

# fasd 초기화
# if command -v fasd >/dev/null 2>&1; then
# 	# https://github.com/clvv/fasd
# 	eval "$(fasd --init auto)"
# fi

# fasd 초기화 최적화
if command -v fasd >/dev/null 2>&1; then
  if [ -n "$ZSH_VERSION" ]; then
    _fasd_cache="$HOME/.fasd-init-zsh"
  elif [ -n "$BASH_VERSION" ]; then
    _fasd_cache="$HOME/.fasd-init-bash"
  fi

  # https://github.com/clvv/fasd
  if [ ! -s "$_fasd_cache" ] || [ "$(command -v fasd)" -nt "$_fasd_cache" ]; then
    fasd --init auto >| "$_fasd_cache" 2>/dev/null
  fi
  [ -s "$_fasd_cache" ] && . "$_fasd_cache"
  unset _fasd_cache
fi

# fzf 초기화
if command -v fzf >/dev/null 2>&1; then
	# fzf 키 바인딩 설정
	# Use `fd` instead of `find` command for `fzf`, CTRL_T and ALT_C
	if command -v fd >/dev/null 2>&1; then
		export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git --no-ignore'
		export FZF_CTRL_T_COMMAND='fd --hidden --exclude .git --no-ignore'
		export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git --no-ignore'
	fi

	if [ -n "$ZSH_VERSION" ]; then
		# Set up fzf key bindings and fuzzy completion
		source <(fzf --zsh)
	elif [ -n "$BASH_VERSION" ]; then
		# Set up fzf key bindings and fuzzy completion
		eval "$(fzf --bash)"

	fi

	if command -v fd >/dev/null 2>&1; then
		# Use `fd` instead of `find` command for path completion (e.g. vim **<TAB>) and dir completion (e.g. cd **<TAB>)
		_fzf_compgen_path() {
			echo "$1"
			fd --hidden --follow --exclude ".git" --no-ignore . "$1"
		}

		_fzf_compgen_dir() {
			fd --type d --hidden --follow --exclude ".git" --no-ignore . "$1"
		}
	fi
fi


# iPhone ShellFish 앱
if [ -e "$HOME/.shellfishrc" ]; then
	. "$HOME/.shellfishrc"
fi

# 함수 정의 모음
if [ -f "$HOME/.config/shell/functions.sh" ]; then
	. "$HOME/.config/shell/functions.sh"
fi

# ==================================================
# 🛠️ Shell 별 전용 설정 로드 (completion 설정은 여기서 진행)
# ==================================================

if [ -n "$ZSH_VERSION" ]; then
	[ -f "$HOME/.config/shell/rc.zsh" ] && . "$HOME/.config/shell/rc.zsh"
elif [ -n "$BASH_VERSION" ]; then
	[ -f "$HOME/.config/shell/rc.bash" ] && . "$HOME/.config/shell/rc.bash"
fi

# ==================================================
# 🛠️ rc.d/ 스크립트 로드
# ==================================================

# rc.d/ 내 파일을 lexical 순서로 순회하며, 확장자에 맞는 shell에서만 sourcing
if [ -d "$HOME/.config/shell/rc.d" ]; then
	for _rc_file in "$HOME/.config/shell/rc.d"/*; do
		[ -e "$_rc_file" ] || continue
		case "$_rc_file" in
		*.zsh)
			[ -n "$ZSH_VERSION" ] && . "$_rc_file"
			;;
		*.bash)
			[ -n "$BASH_VERSION" ] && . "$_rc_file"
			;;
		*.sh)
			. "$_rc_file"
			;;
		esac
	done
	unset _rc_file
fi

# ==================================================
# 🛠️ 각 도구에서 진행하는 completion
# ==================================================

# Google Cloud SDK
# The next line enables shell command completion for gcloud.
if [ -n "$ZSH_VERSION" ]; then
	[ -f "$HOME/dev/toolbox/google-cloud-sdk/completion.zsh.inc" ] &&
		. "$HOME/dev/toolbox/google-cloud-sdk/completion.zsh.inc"
elif [ -n "$BASH_VERSION" ]; then
	[ -f "$HOME/dev/toolbox/google-cloud-sdk/completion.bash.inc" ] &&
		. "$HOME/dev/toolbox/google-cloud-sdk/completion.bash.inc"
fi

# SDKMAN
#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
if [ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
	export SDKMAN_DIR="$HOME/.sdkman"
	. "$HOME/.sdkman/bin/sdkman-init.sh"
fi

