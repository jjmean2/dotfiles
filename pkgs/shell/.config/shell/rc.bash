# shellcheck shell=bash disable=SC1091
# ==================================================
# 🕹️ 터미널 UX 설정 (환경 변수, 옵션 등)
# ==================================================
# Zsh의 colors 대응: ANSI 이스케이프 코드 변수 정의
# 아래 PS1(프롬프트) 설정에서 사용됨
if [[ -f $HOME/.config/shell/colors.bash ]]; then
	source "$HOME/.config/shell/colors.bash"
	define_colors
fi

# region: 프롬프트(Prompt) 설정
# Prompt에서 사용할 git 상태 관련 변수 함수 정의
if [[ -f $HOME/.config/shell/_ps_set_git_status.bash ]]; then
	source "$HOME/.config/shell/_ps_set_git_status.bash"

	# PROMPT_COMMAND은 PS1이 출력되기 직전에 실행되는 명령어를 지정하는 변수다.
	# _ps_set_git_status를 PS1 출력 직전에 실행되도록 하여 PS1에서 사용할 상태 변수를 갱신한다.
	PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}_ps_set_git_status"
fi

# shellcheck disable=SC2154
PS1='$(XIT=$?; [[ $XIT != 0 ]] && printf "%s" "\[\e[31;1m\]"; printf "🅑") \[\e[36;4m\]\w\[\e[0m\]${_ps_branch:+ \[\e[36;1m\](\[\e[33m\]$_ps_branch${_ps_unstaged_icon:+ \[\e[31m\]$_ps_unstaged_icon}${_ps_staged_icon:+ \[\e[32m\]$_ps_staged_icon}\[\e[36m\])\[\e[0m\]} $ '

if [[ -n $SSH_CLIENT || -n $SSH_TTY ]]; then
	PS1='\[\e[32m\]\u\[\e[35m\]@\h\[\e[0m\]$(XIT=$?; [[ $XIT != 0 ]] && printf "%s" "\[\e[31;1m\]"; printf "🅑") \[\e[36;4m\]\w\[\e[0m\]${_ps_branch:+ \[\e[36;1m\](\[\e[33m\]$_ps_branch${_ps_unstaged_icon:+ \[\e[31m\]$_ps_unstaged_icon}${_ps_staged_icon:+ \[\e[32m\]$_ps_staged_icon}\[\e[36m\])\[\e[0m\]} $ '
fi

# Zsh의 %F{cyan}%U%~%u%f $ 대응 (안시 이스케이프 색상 사용)
# \e[4m = 밑줄 시작, \e[24m = 밑줄 끝, \e[36m = 청록색
# PS1="\[\e[36;4m\]\w\[\e[24;0m\] $ "

# green coloring 버전 대응 (주석 해제 후 사용)
# PS1="\[\e[36;4m\]\w\[\e[24;0m\] $ \[\e[32;1m\]"
# trap 'echo -ne "\e[0m"' DEBUG

# endregion

# cd 명령어 없이 디렉터리 이름만 입력해도 이동 (Bash 4.0 이상)
shopt -s autocd

# ==================================================
# 🕹️ 함수 / 색상 변수 설정
# ==================================================

# ==================================================
# 🕹️ Bindkey (키 바인딩) 및 단축키 설정
# ==================================================
if [ -r "$HOME/.config/shell/inputrc" ]; then
	bind -f "$HOME/.config/shell/inputrc"
fi

# ==================================================
# 🪄 iTerm2 shell integration
# ==================================================
# iTerm2 shell integration
if [ "$TERM_PROGRAM" = "iTerm.app" ] || [ "$LC_TERMINAL" = "iTerm2" ]; then
	if [ -e "$HOME/.config/shell/iterm2/iterm2_shell_integration.bash" ]; then
		. "$HOME/.config/shell/iterm2/iterm2_shell_integration.bash"
	fi

	iterm2_print_user_vars() {
		iterm2_set_user_var gitBranch "$( (git branch 2>/dev/null) | grep '\*' | cut -c3-)"
	}
fi

# ==================================================
# 🪄 Bash 자동 완성 및 Readline 바인딩 초기화
# ==================================================

# bash-completion 설정
# hombrew가 설치된 경우, /opt/homebrew/etc/profile.d/bash_completion.sh 등 homebrew가 설치한 경로의 bash_completion.sh 파일이 로드되고,
# hombrew가 설치되지 않은 리눅스 환경에서는 /etc/profile.d/bash_completion.sh 파일이 로드된다.
if [ -r "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh" ]; then
	. "$HOMEBREW_PREFIX/etc/profile.d/bash_completion.sh"
elif [ -r /etc/profile.d/bash_completion.sh ]; then
	. /etc/profile.d/bash_completion.sh
elif [ -r /etc/bash_completion ]; then
	. /etc/bash_completion
fi

# LS_COLORS 설정 (Zsh의 list-colors 대응)
export LS_COLORS="di=34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43"
