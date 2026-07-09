# === PATH, FPATH 설정 ===
typeset -U path

# zsh에서는 변수 확장시 공백에서 word splitting 이 일어나지 않으므로 큰 따옴표로 감싸지 않아도 된다.
# 배열 변수의 경우에는 배열 요소를 경계로 요소가 나뉜다.
path=(/usr/local/bin $path)
path=($HOME/.local/bin $path)
path=($HOME/.jongwan/bin $path)

# === Zsh 설정 ===

# zsh 자동완성 (completion)
autoload -Uz compinit && compinit

# 파일이나 디렉터리 이름을 입력할 때 대소문자를 무시하고 찾아서 자동완성해주는 설정. 예를 들어 downloads라고 소문자로만 쳐도 대문자로 시작하는 Downloads/ 폴더를 찾아준다.
# 뒤에 복잡하게 똑같은 패턴이 반복되는 부분은 Zsh 자동완성 시스템이 1단계 매칭 실패 시 2단계, 3단계로 넘어가며 '부분 일치'나 '오타 교정'까지 시도하도록 규칙을 겹겹이 쌓아두는 부분
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*'

# 접두사(prefix)나 접미사(suffix)를 확장하여 부분적인 입력만으로도 영리하게 추천 후보를 띄우려는 설정
zstyle ':completion:*' list-suffixes
zstyle ':completion:*' expand prefix suffix

# ls 명령어를 치고 탭을 눌렀을 때도 방향키로 이동하며 파일을 선택할 수 있는 메뉴를 띄워줌
zstyle ':completion:ls:*' menu select

# 탭을 눌러 자동 완성 후보 메뉴가 떴을 때, 항목의 종류에 따라 글자 색상을 다르게 표현해 주는 설정
# di=34(디렉터리는 파란색), ex=31(실행 파일은 빨간색)처럼 일반적인 리눅스/macOS 터미널의 LS_COLORS 규격을 따름
zstyle ':completion:*:default' list-colors \
	"di=34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43"

# 유용한 autoload 함수들

# 색상별 escape sequence를 색상 이름 변수에 저장해주는 함수. 아래 프롬프트(PROMPT) 설정에서 색상을 적용할 때 사용한다.
autoload -Uz colors && colors

# bash 스타일로 word 구분, /도 word의 경계가 되도록 함
autoload -Uz select-word-style
select-word-style bash

# === 터미널 환경 설정 ===
# 프롬프트(Prompt) 설정
# https://mybyways.com/blog/macos-zsh-configuration
# PROMPT="%F{cyan}%U%~%u%f $ %F{green}%B"
# preexec () { print -Pn "%b%f" }
# RPROMPT="%(?..%F{red}%?🚫%f)"

# Without green coloring
PROMPT="%F{cyan}%U%~%u%f $ "

# 터미널 색상 활성화
export CLICOLOR=1
export LSCOLORS=gxBxhxDxfxhxhxhxhxcxcx

# cd 명령어 없이 디렉터리 이름만 입력해도 해당 디렉터리로 이동
setopt auto_cd

# === 키 바인딩 설정 ===
# Rebind \eq and \eQ from push-line to push-line-or-edit
# push-line-or-edit behaves like push-line on normal lines,
# (pushing the current line onto a stack and clearing the command line)
# but like edit-command-line on continuation lines (multi-line editing)
# "https://zsh.sourceforge.io/Guide/zshguide04.html#:~:text=Suppose%20you've%20already,the%20function%20zed"
bindkey '\eq' push-line-or-edit
bindkey '\eQ' push-line-or-edit

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey "^X^E" edit-command-line

# === alias 설정 ===
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

alias yarn-sdks='yarn dlx @yarnpkg/sdks vscode'
if [[ -f /Applications/MacVim.app/Contents/MacOS/Vim ]]; then
	alias mvim='/Applications/MacVim.app/Contents/MacOS/Vim -g'
fi

alias egit='LC_ALL=C git'

if [[ -f /usr/libexec/PlistBuddy ]]; then
	alias PlistBuddy='/usr/libexec/PlistBuddy'
fi

# help 명령어
unalias run-help
autoload run-help
HELPDIR="/usr/share/zsh/$ZSH_VERSION/help"
alias help=run-help

# === 도구 환경 설정 ===
# iTerm2 shell integration
if [[ -e $HOME/.iterm2_shell_integration.zsh ]]; then
	source "$HOME/.iterm2_shell_integration.zsh"

	# iTerm2 user variable
	# zsh: Place this in .zshrc after "source /Users/georgen/.iterm2_shell_integration.zsh".
	iterm2_print_user_vars() {
		iterm2_set_user_var gitBranch "$( (git branch 2>/dev/null) | grep '\*' | cut -c3-)"
	}

fi

# mise shell activation
if command -v mise &>/dev/null; then
	eval "$(mise activate zsh)"
fi

if command -v nvim &>/dev/null; then
	# 참고: VISUAL은 화면 전체를 사용하는 에디터를 의미하고, EDITOR는 한 줄씩 편집하던 옛날 방식(ed 등)과의 호환성을 위한 것인데, 현대에는 보통 둘 다 똑같이 설정합니다.
	# EDITOR만 설정해도 되는데, VISUAL, EDITOR 둘다 설정한 경우, edit-command-line 기능은 VISUAL 값을 따름
	export VISUAL='nvim'
	export EDITOR='nvim'

	bindkey -e
fi

# corepack 설정
# Disable automatic package.json#packageManager field setting when using corepack
# https://github.com/nodejs/corepack/blob/main/README.md#environment-variables
export COREPACK_ENABLE_AUTO_PIN=0

# fzf 키 바인딩 설정
# Use `fd` instead of `find` command for `fzf`, CTRL_T and ALT_C
if command -v fzf &>/dev/null; then
	if command -v fd &>/dev/null; then
		export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git --no-ignore'
		export FZF_CTRL_T_COMMAND='fd --hidden --exclude .git --no-ignore'
		export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git --no-ignore'
	fi

	# Set up fzf key bindings and fuzzy completion
	source <(fzf --zsh)

	# Use `fd` instead of `find` command for path completion (e.g. vim **<TAB>) and dir completion (e.g. cd **<TAB>)
	_fzf_compgen_path() {
		echo "$1"
		fd --hidden --follow --exclude ".git" --no-ignore . "$1"
	}

	_fzf_compgen_dir() {
		fd --type d --hidden --follow --exclude ".git" --no-ignore . "$1"
	}
fi

# bun completions
if [[ -s $HOME/.bun/_bun ]]; then
	source "$HOME/.bun/_bun"
fi

# fasd initialization (Select one between two ways of configuration)
# "Default" configuration
# https://github.com/clvv/fasd
# eval "$(fasd --init auto)"

# "Fast init with cache" configration
fasd_cache="$HOME/.fasd-init-zsh"
if [ "$(command -v fasd)" -nt "$fasd_cache" -o ! -s "$fasd_cache" ]; then
	# `>` means it will overwrite even if "$fasd_cache" file exists
	# https://unix.stackexchange.com/questions/45201/bash-what-does-do
	fasd --init auto >|"$fasd_cache"
fi
source "$fasd_cache"
unset fasd_cache

# SDKMAN
#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
if [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
	export SDKMAN_DIR="$HOME/.sdkman"
	source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

# Antigravity
if [[ -d $HOME/.antigravity/antigravity/bin ]]; then
	path=($HOME/.antigravity/antigravity/bin $path)
fi

# Google Cloud SDK
# The next line updates PATH for the Google Cloud SDK.
if [[ -f $HOME/dev/toolbox/google-cloud-sdk/path.zsh.inc ]]; then
	source "$HOME/dev/toolbox/google-cloud-sdk/path.zsh.inc"

fi

# The next line enables shell command completion for gcloud.
if [[ -f $HOME/dev/toolbox/google-cloud-sdk/completion.zsh.inc ]]; then
	source "$HOME/dev/toolbox/google-cloud-sdk/completion.zsh.inc"
fi

# swiftly
if [[ -f $HOME/.swiftly/env.sh ]]; then
	source "$HOME/.swiftly/env.sh"
fi

# iPhone ShellFish 앱
if [[ -e $HOME/.shellfishrc ]]; then
	source "$HOME/.shellfishrc"
fi

# cargo
if [[ -f $HOME/.cargo/env ]]; then
	source "$HOME/.cargo/env"
fi

# java version
if [[ -f /usr/libexec/java_home ]]; then
	# export JAVA_HOME="$(/usr/libexec/java_home -v 11)"
fi

# === zshrc.d 디렉터리의 설정 파일 로드 ===
if [[ -d $HOME/.jongwan/etc/zshrc.d ]]; then
	# .zsh로 끝나는 파일만 로드 (알파벳/숫자 순서)
	# (D)는 숨김 파일을 포함, (N)은 매칭 결과가 없어도 에러를 내지 않음
	for config_file in "$HOME"/.jongwan/etc/zshrc.d/*.zsh(DN); do
		source "$config_file"
	done
fi

# === zsh 플랫폼별, 로컬 설정 로드 ===
source_zsh_variants ~/.zshrc
