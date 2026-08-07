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
# 프롬프트에서 사용하기 위한 git 상태를 저장하는 변수를 정의하는 함수
# _ps_branch, _ps_unstaged_icon, _ps_staged_icon
if [[ -f $HOME/.config/shell/_ps_set_git_status.bash ]]; then
	source "$HOME/.config/shell/_ps_set_git_status.bash"

	# PROMPT_COMMAND은 PS1이 출력되기 직전에 실행되는 명령어를 지정하는 변수다.
	# _ps_set_git_status를 PS1 출력 직전에 실행되도록 하여 PS1에서 사용할 상태 변수를 갱신한다.
	PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}_ps_set_git_status"
fi

# 경로를 줄일 때 하위 4개 요소는 유지한다. Bash가 지원하는 기본 기능이다.
PROMPT_DIRTRIM=4

PS1=''
if [[ -n $SSH_CLIENT || -n $SSH_TTY ]]; then
	# 원격 접속 시에는 <user>@<host>를 추가로 표시
	# "ljw@jwlee-macbook-air🅑 ~/dev/jwlee/dotfiles (main ✗) $ " 형태
	PS1+='\[\e[32m\]\u\[\e[35m\]@\h\[\e[0m\]'
fi
# "🅑 ~/dev/jwlee/dotfiles (main ✗) $ " 형태

# 🅑 로 Bash임을 표시
PS1+='\[\e[1m\]$(XIT=$?; [[ $XIT != 0 ]] && printf "%s" "\[\e[31m\]"; printf "🅑")\[\e[0m\] '
# 현재 디렉토리 경로를 표시
PS1+='\[\e[36;4m\]\w\[\e[0m\]'
# shellcheck disable=SC2154
# (1) git 브랜치 정보가 있으면 공백을 두고 확장
PS1+='${_ps_branch:+ '
# (2) 괄호 열기
PS1+='\[\e[36;1m\]('
# - 브랜치명
PS1+='\[\e[33m\]$_ps_branch'
# shellcheck disable=SC2154
# - upstream과의 차이가 있으면 표시
PS1+='${_ps_has_upstream_diff:+ }${_ps_upstream_ahead:+\[\e[32m\]⇡${_ps_upstream_ahead}\[\e[0m\]}${_ps_upstream_behind:+\[\e[31m\]⇣${_ps_upstream_behind}\[\e[0m\]}'
# shellcheck disable=SC2154
# - staged/unstaged 변경 사항이 있으면 표시
PS1+='${_ps_unstaged_icon:+ \[\e[31m\]$_ps_unstaged_icon}${_ps_staged_icon:+ \[\e[32m\]$_ps_staged_icon}'
# (2) 괄호 닫기
PS1+='\[\e[36m\])\[\e[0m\]'
# (1) `${_ps_branch:+ ...` 구문 닫기
PS1+='}'
# 프롬프트 끝에 $ 표시
PS1+=' $ '

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
