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
	# "user@host🅩 ~/dev/dotfiles (main ✗) $ " 형태
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
PROMPT+='${${_ps_detached_color:+%F{magenta\}}:-%F{yellow\}}$_ps_branch%f'
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

# ==================================================
# 🕹️ 셸 옵션
# ==================================================
# 켜 둔 옵션 목록: `setopt` (기본값과 다른 것만 나온다). 옵션 설명: `man zshoptions`

# cd 명령어 없이 디렉터리 이름만 입력해도 해당 디렉터리로 이동
setopt auto_cd

# cd 할 때마다 떠난 디렉터리를 디렉터리 스택에 쌓는다. `cd -<Tab>` 으로 최근 디렉터리 목록에서 고르고,
# `dirs -v` 로 스택을 본다. 같은 디렉터리는 한 번만 쌓고, pushd 가 스택을 출력하지 않게 한다.
setopt auto_pushd pushd_ignore_dups pushd_silent

# 대화형 셸에서도 # 뒤를 주석으로 읽는다 (예: 붙여 넣은 명령의 주석, `ls # 나중에 지우기`)
setopt interactive_comments

# extended_glob 은 전역으로 켜지 않는다. 켜면 ^ # ~ 가 glob 문자가 되어 `git reset HEAD^` 가
# "no matches found" 로 멈춘다. 필요한 함수 안에서만 `setopt localoptions extended_glob` 으로 켠다 (아래 compinit 부분).

# ==================================================
# 🕹️ 히스토리
# ==================================================
# 직전 명령 검색(↑, Ctrl-R) 과 입력 제안(zsh-autosuggestions) 이 모두 이 파일을 데이터로 쓴다.
#
# 파일 위치를 직접 정하는 이유: macOS 는 /etc/zshrc 가 ~/.zsh_history 로 정해 주지만(크기는 1000 줄),
# Linux 배포판의 기본 설정은 대개 HISTFILE 을 정하지 않아서 히스토리가 셸을 닫으면 사라진다.
HISTFILE=${ZDOTDIR:-$HOME}/.zsh_history
# 메모리에 둘 줄 수와 파일에 남길 줄 수. 중복을 지우므로(아래) 실제로는 서로 다른 명령 5만 개다.
HISTSIZE=50000
SAVEHIST=50000

# 명령마다 시작 시각과 걸린 시간을 같이 적는다 (`: 1763300000:3;make` 꼴). `history -i` 로 시각과 함께 본다.
setopt extended_history
# 명령을 실행할 때마다 파일에 바로 쓰고, 다른 셸이 쓴 줄도 읽어 온다. 그래서 tmux 의 다른 pane 에서
# 방금 친 명령이 이 pane 의 Ctrl-R 과 ↑ 에도 나온다 (셸을 닫을 때 한꺼번에 쓰는 기본 동작 대신).
setopt share_history
# 같은 명령을 다시 치면 옛 줄을 지우고 새 줄만 남긴다 (`git status` 가 수십 줄 쌓이지 않게)
setopt hist_ignore_all_dups
# 공백으로 시작한 명령은 기록하지 않는다 (토큰이 든 명령 등. 바로 직전 줄로는 잠깐 남는다)
setopt hist_ignore_space
# 기록할 때 명령 안의 불필요한 공백을 줄인다 (같은 명령이 공백 차이로 따로 남지 않게)
setopt hist_reduce_blanks

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

# zmv: 패턴으로 여러 파일의 이름을 한꺼번에 바꾼다 (zsh 동봉 함수, `man zshcontrib` 의 zmv)
#   zmv -n '(*).jpeg' '$1.jpg'   먼저 -n 으로 무엇이 어떻게 바뀌는지만 본다 (실제로 옮기지 않는다)
#   zmv '(*).jpeg' '$1.jpg'      괄호로 잡은 부분이 $1, $2 … 가 된다. 두 인자 모두 작은따옴표로 감싼다
#   mmv *.jpeg *.jpg             아래 alias. 따옴표 없이 * 끼리 대응시킨다 (zmv 머리말에 있는 쓰는 법)
# 바꾼 이름끼리 겹치거나 이미 있는 파일을 덮게 되면 아무것도 옮기지 않고 멈춘다.
autoload -Uz zmv
alias mmv='noglob zmv -W'

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

# Option+← / Option+→ (ESC[1;3D / ESC[1;3C) 로 단어 이동.
# Ghostty 의 기본 esc:b / esc:f 변환을 끄고(config.ghostty 참고) 방향키를 그대로 받으므로
# 여기서 연결한다. select-word-style bash 가 적용되어 / 도 단어 경계가 된다.
bindkey '^[[1;3D' backward-word
bindkey '^[[1;3C' forward-word

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey "^X^E" edit-command-line

# ↑ / ↓: 지금 입력한 앞부분으로 시작하는 히스토리만 오간다 (zsh 동봉 위젯).
# 예: `git ` 까지 치고 ↑ → git 으로 시작한 명령만 차례로. 빈 줄에서는 원래처럼 바로 앞 명령.
# 앞부분은 커서 앞까지다. 첫 ↑ 뒤 커서가 줄 끝으로 가도 같은 앞부분으로 계속 찾는다.
# 여러 줄 입력 안에서는 먼저 줄 사이를 움직인다. Ctrl-P / Ctrl-N 은 원래 동작(앞뒤 명령) 그대로 둔다.
# 방향키는 터미널 모드에 따라 ESC[A 또는 ESCOA 로 오므로 둘 다 묶는다.
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search

# Option+, : Option+. (insert-last-word, 앞 명령의 마지막 단어 넣기) 다음에 누르면 그 명령의 한 단어 앞으로 바꾼다.
# 예: `cp a.txt b.txt` 뒤에 `vi ` Option+. → b.txt, 이어서 Option+, → a.txt → cp.
# Option+. 를 여러 번 누르면 더 앞 명령으로 가고, Option+, 는 고른 명령 안에서 움직인다.
# (Ghostty 는 왼쪽 Option 만 Alt 로 보낸다. config.ghostty 의 macos-option-as-alt)
autoload -Uz copy-earlier-word
zle -N copy-earlier-word
# Option+, 의 bindkey 는 아래 compinit 뒤에 있다 (compinit 이 이 키를 가져가므로)
# Option+. 를 같은 일을 하는 사용자 위젯으로 바꿔 묶는다. copy-earlier-word 는 직전 위젯($LASTWIDGET)을
# 인자와 함께 다시 불러 단어를 고르는데, zsh-autosuggestions 가 내장 위젯을 감쌀 때는 인자를 버려서
# (`zle .insert-last-word` 로만 부른다) 한 명령 앞으로 넘어가 버린다. 사용자 위젯은 인자를 그대로 넘긴다.
# 이름은 copy-earlier-word 가 알아보도록 insert-last-word 로 끝나야 한다. (plugins.zsh 의 CLEAR_WIDGETS 도 짝이다)
_jw-insert-last-word() { zle .insert-last-word -- "$@"; }
zle -N jw-insert-last-word _jw-insert-last-word
bindkey '^[.' jw-insert-last-word
bindkey '^[_' jw-insert-last-word

# 붙여 넣은 내용이 URL(http:// https:// ssh:// file:// …)로 시작하면 작은따옴표로 감싼다 (zsh 동봉 위젯).
# 예: curl 뒤에 https://x.com/a?b=1&c=2 를 붙여 넣으면 ? 가 glob 으로, & 가 백그라운드 실행으로 읽혀 깨지던 것을 막는다.
# 줄 중간에 붙여 넣어도 붙여 넣은 내용이 URL 로 시작하면 감싼다. 감싸지 않으려면 Option+2 를 누른 뒤 붙여 넣는다.
# (Option+1 뒤 붙여 넣기는 URL 이 아니어도 감싼다)
autoload -Uz bracketed-paste-url-magic
zle -N bracketed-paste bracketed-paste-url-magic

# 터미널별 셸 통합(iTerm2, tmux)은 여기가 아니라 terminal/ 에 있고, rc.sh 가 맨 나중에 읽는다.

# ==================================================
# 🪄 Zsh 자동 완성 시스템 초기화 (compinit)
# ==================================================

# region: zsh 자동완성 (completion)

_should_skip_compinit_check() {
	setopt localoptions extended_glob

	local dump="${ZDOTDIR:-$HOME}/.zcompdump"
	# 파일이 실제로 존재하고(.), 수정된 지 24시간 이내(m-1)라면 참(0) 반환
	# (파일이 없거나 24시간이 지났다면 N 플래그로 인해 빈 문자열이 되어 거짓)
	[[ -n "$dump"(#qN.m-1) ]]
	# "$dump" ( #q  N  .  m-1 )
	#  ──┬──   ──────────┬────
	#    │               └─ 글롭 수식어 (검사 조건)
	#    └─ 대상 파일 경로
	#
	# - `(#q...)`` : Glob Qualifier 진입 플래스
	#  - 괄호 안의 문자를 Glob Qualifier로 해석하라는 지시자
	# - `N`` : NullGlob, 조건 불일치 시 에러를 내지 않고 빈 문자열(Null)을 반환
	# - `.` : Plain file일반 파일(regular file)만 매칭. (c.f. `/`는 디렉토리, `@`는 심볼릭 링크)
	# - `m-1` : Modification Time, `m`은 파일의 수정 시각 기준으로 필터링, 기본 단위를 1일(24시간)
	#   - `m1`: 정확히 1일 전 (24~48시간 전)
	#   - `m-1`: 수정된 지 1일보다 더 오래된 것 (24시간 초과)
	#   - `m-1`: 수정된 지 1일 이내인 것 (24시간 미만)
	#   - `mh-12`: 수정된 지 12시간 이내 (`h` = hours)
	#   - `mm-1200`: 수정된 지 1200분(20시간) 이내 (`m` = minutes)
}

autoload -Uz compinit
if _should_skip_compinit_check; then
	compinit -C
else
	compinit
fi
unfunction _should_skip_compinit_check

# Option+, (copy-earlier-word, 위 Bindkey 부분) 는 compinit 뒤에 묶는다.
# compinit 은 Option+, 와 Option+/ 를 히스토리 단어 완성(_history-complete-newer/older)에 묶는다. 처음 만들 때는
# 키가 비어 있을 때만 묶지만, 그 결과를 ~/.zcompdump 에 조건 없는 `bindkey '^[,' …` 줄로 적어 두고 다음 셸부터
# 그 덤프를 읽는다. 그래서 이 키를 비워 두던 시절에 만든 덤프가 있는 머신에서는 앞에서 묶은 것이 덮인다.
# (Option+/ 는 그대로 둔다: 입력 중인 단어를 히스토리에 있던 단어로 완성)
bindkey '^[,' copy-earlier-word

# 파일이나 디렉터리 이름을 입력할 때 대소문자를 무시하고 찾아서 자동완성해주는 설정. 예를 들어 downloads라고 소문자로만 쳐도 대문자로 시작하는 Downloads/ 폴더를 찾아준다.
# 뒤에 복잡하게 똑같은 패턴이 반복되는 부분은 Zsh 자동완성 시스템이 1단계 매칭 실패 시 2단계, 3단계로 넘어가며 '부분 일치'나 '오타 교정'까지 시도하도록 규칙을 겹겹이 쌓아두는 부분
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*' 'm:{[:lower:][:upper:]}={[:upper:][:lower:]} l:|=* r:|=*'

# 접두사(prefix)나 접미사(suffix)를 확장하여 부분적인 입력만으로도 영리하게 추천 후보를 띄우려는 설정
zstyle ':completion:*' list-suffixes
zstyle ':completion:*' expand prefix suffix

# 탭을 눌러 후보가 여러 개면 방향키로 고르는 메뉴를 띄운다 (모든 명령에서)
zstyle ':completion:*' menu select
# 후보를 종류(파일, 옵션, 브랜치 …)별로 묶고 묶음마다 [종류] 제목을 붙인다
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}[%d]%f'

# 탭을 눌러 자동 완성 후보 메뉴가 떴을 때, 항목의 종류에 따라 글자 색상을 다르게 표현해 주는 설정
# di=34(디렉터리는 파란색), ex=31(실행 파일은 빨간색)처럼 일반적인 리눅스/macOS 터미널의 LS_COLORS 규격을 따름
zstyle ':completion:*:default' list-colors \
	"di=34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43"
# endregion
