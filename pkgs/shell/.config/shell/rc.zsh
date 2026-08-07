# ==================================================
# 🕹️ 터미널 UX 설정 (환경 변수, 옵션 등)
# ==================================================

# 색상별 escape sequence를 색상 이름 변수에 저장해주는 함수
# e.g. `echo "$fg[red]Red Text$reset_color"` 같은 식으로 색상을 쓸 수 있게 해준다.
autoload -Uz colors && colors
setopt PROMPT_SUBST

# # region: 프롬프트(Prompt) 설정
autoload -Uz add-zsh-hook

# 프롬프트에서 사용하기 위한 git 상태를 저장하는 변수를 정의하는 함수
# _ps_branch, _ps_unstaged_icon, _ps_staged_icon
if [[ -f $HOME/.config/shell/_ps_set_git_status.bash ]]; then
	source "$HOME/.config/shell/_ps_set_git_status.bash"

	# precmd hook은 PROMPT가 출력되기 직전 시점에 실행될 함수를 등록하는 hook이다.
	# _ps_set_git_status를 PROMPT 출력 직전에 실행되도록 하여 PROMPT에서 사용할 상태 변수를 갱신한다.
	add-zsh-hook precmd _ps_set_git_status
fi

# Zsh는 이 변수를 기본 지원하지 않지만, PROMPT 평가시
# - 파라미터 패턴 매칭
#   - ${(M)name:#pattern} (name 파라미터 값이 pattern과 매칭되면 name 값으로 확장, 아니면 null)
# - 중첩 파라미터 확장:
#   - ${${${name}:+setword}:-unsetword} (name 값이 비어 있지 않으면, setword로 확장, 비어 있으면 unsetword로 확장)
# - 산술 확장:
#   - $((expression)) (expression을 산술식으로 연산한 결과로 확장)
# - 프롬프트 삼항식 조건분기 escape 문법:
#   - %(n~:true-text:false-text) (현재 디렉토리 요소 개수가 n 이상이면 true-text, 아니면 false-text로 확장)
# 등을 이용해 PROMPT_DIRTRIM 값에서 지정한 만큼 경로를 줄이도록 작성함
PROMPT_DIRTRIM=4

PROMPT=''
if [[ -n $SSH_CLIENT || -n $SSH_TTY ]]; then
	# 원격 접속 시에는 <user>@<host>를 추가로 표시
	# "ljw@jwlee-macbook-air🅩 ~/dev/jwlee/dotfiles (main ✗) $ " 형태
	PROMPT+='%F{green}%n%F{magenta}@%m%f'
fi
# "🅩 ~/dev/jwlee/dotfiles (main ✗) $ " 형태
# 🅩 로 Zsh 임을 표시.
PROMPT+='%B%(?:%f:%F{red})🅩%b '
# 현재 디렉토리 경로를 표시
PROMPT+='%F{cyan}%U${${${(M)PROMPT_DIRTRIM:#(+|)<1->}:+%($((PROMPT_DIRTRIM+3))~:%-1~/.../%$((PROMPT_DIRTRIM))~:%~)}:-%~}%u%f'
# (1) git 브랜치 정보가 있으면 공백을 두고 확장
PROMPT+='${_ps_branch:+ '
# (2) 괄호 열기
PROMPT+='%B%F{cyan\}('
# - 브랜치명
PROMPT+='%F{yellow\}$_ps_branch%f'
# - upstream과의 차이가 있으면 표시
PROMPT+='${_ps_has_upstream_diff:+ }${_ps_upstream_ahead:+%F{green\}⇡${_ps_upstream_ahead}%f}${_ps_upstream_behind:+%F{red\}⇣${_ps_upstream_behind}%f}'
# - staged/unstaged 변경 사항이 있으면 표시
PROMPT+='${_ps_unstaged_icon:+ %F{red\}$_ps_unstaged_icon}${_ps_staged_icon:+ %F{green\}$_ps_staged_icon}'
# (2) 괄호 닫기
PROMPT+='%F{cyan\})%f%b'
# (1) ${_ps_branch:+ ... 구문 닫기
PROMPT+='}'
# 프롬프트 끝에 $ 표시
PROMPT+=' $ '

# 에러로 끝난 경우, 우측에서 직전 명령의 종료 코드 확인하기
RPROMPT="%(?..%F{red}%?🚫%f)"

# PROMPT="%F{yellow}%n%f%F{green}@%m%f %F{cyan}%U%~%u%f $ "
#
# Without green coloring
# PROMPT="%F{cyan}%U%~%u%f $ "
#
# green coloring을 추가하려면 위 대신 아래 설정 사용
# https://mybyways.com/blog/macos-zsh-configuration
# PROMPT="%F{cyan}%U%~%u%f $ %F{green}%B"
# preexec() { print -Pn "%b%f"; }
# RPROMPT="%(?..%F{red}%?🚫%f)"
# endregion

# cd 명령어 없이 디렉터리 이름만 입력해도 해당 디렉터리로 이동
setopt auto_cd

# ==================================================
# 🕹️ 함수 autoload
# ==================================================

#region: option-backspace 삭제 범위 설정
# Meta(Option)-Backspace 로 slash까지만 지우도록 설정
# https://unix.stackexchange.com/questions/258656/how-can-i-have-two-keystrokes-to-delete-to-either-a-slash-or-a-word-in-zsh/258661#answer-666457
# bindkey '^[^?' vi-backward-kill-word

# bash 스타일로 word 구분, /도 word의 경계가 되도록 함
autoload -Uz select-word-style
select-word-style bash
#endregion

# https://zsh.sourceforge.io/Doc/Release/User-Contributions.html#Recent-Directories
# autoload -Uz chpwd_recent_dirs cdr add-zsh-hook
# add-zsh-hook chpwd chpwd_recent_dirs

# ==================================================
# 🕹️ alias 설정
# ==================================================
# help 명령어
if alias run-help >/dev/null; then
	unalias run-help
fi
autoload -Uz run-help
HELPDIR="/usr/share/zsh/$ZSH_VERSION/help"
alias help=run-help

# ==================================================
# 🕹️ Bindkey (키 바인딩) 설정
# ==================================================

# \eq와 \eQ를 push-line에서 push-line-or-edit로 재바인딩
# push-line-or-edit 는 일반적인 줄에서는 push-line처럼 동작하고 (현재 줄을 스택에 넣고 명령줄을 지움),
# 연속 줄에서는 edit-command-line처럼 동작함 (멀티라인 편집)
# "https://zsh.sourceforge.io/Guide/zshguide04.html#:~:text=Suppose%20you've%20already,the%20function%20zed"
bindkey '\eq' push-line-or-edit
bindkey '\eQ' push-line-or-edit
bindkey '\eOP' where-is

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey "^X^E" edit-command-line

# ==================================================
# 🪄 iTerm2 shell integration
# ==================================================
# iTerm2 shell integration
if [ "$TERM_PROGRAM" = "iTerm.app" ] || [ "$LC_TERMINAL" = "iTerm2" ]; then
	if [ -e "$HOME/.config/shell/iterm2/iterm2_shell_integration.zsh" ]; then
		. "$HOME/.config/shell/iterm2/iterm2_shell_integration.zsh"
	fi

	iterm2_print_user_vars() {
		iterm2_set_user_var gitBranch "$( (git branch 2>/dev/null) | grep '\*' | cut -c3-)"
	}
fi
# ==================================================
# 🪄 Zsh 자동 완성 시스템 초기화 (compinit)
# ==================================================

# region: zsh 자동완성 (completion)
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
# endregion
