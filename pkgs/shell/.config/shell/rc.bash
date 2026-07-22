# shellcheck shell=bash disable=SC1091
# ==================================================
# 🕹️ 터미널 UX 설정 (환경 변수, 옵션 등)
# ==================================================

# region: 프롬프트(Prompt) 설정
# Zsh의 %F{cyan}%U%~%u%f $ 대응 (안시 이스케이프 색상 사용)
# \e[4m = 밑줄 시작, \e[24m = 밑줄 끝, \e[36m = 청록색
# PS1="\[\e[36;4m\]\w\[\e[24;0m\] $ "

PS1="\[\033[01;32m\]\u@\h\[\033[00m\] \[\033[01;34m\]\W\[\033[00m\]$ "

# green coloring 버전 대응 (주석 해제 후 사용)
# PS1="\[\e[36;4m\]\w\[\e[24;0m\] $ \[\e[32;1m\]"
# trap 'echo -ne "\e[0m"' DEBUG
# endregion

# cd 명령어 없이 디렉터리 이름만 입력해도 이동 (Bash 4.0 이상)
shopt -s autocd

# ==================================================
# 🕹️ 함수 / 색상 변수 설정
# ==================================================

# Zsh의 colors 대응: ANSI 이스케이프 코드 변수 정의
RED='\[\e[31m\]'
GREEN='\[\e[32m\]'
YELLOW='\[\e[33m\]'
BLUE='\[\e[34m\]'
CYAN='\[\e[36m\]'
RESET='\[\e[0m\]'

# ==================================================
# 🕹️ Bindkey (키 바인딩) 및 단축키 설정
# ==================================================
if [ -r "$HOME/.config/shell/inputrc" ]; then
	bind -f "$HOME/.config/shell/inputrc"
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
