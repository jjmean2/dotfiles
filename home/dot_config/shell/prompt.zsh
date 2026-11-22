# vim:ft=zsh
# ==============================================================================
# zsh 프롬프트
# 위치: ~/.config/shell/prompt.zsh  (rc.zsh 가 읽는다. bash 프롬프트는 rc.bash 에 있다)
# ==============================================================================
#
# 생김새 (오른쪽은 RPROMPT):
#   (venv) user@host🅩 ~/dev/dotfiles (main|rebase-i 2/5 ⇡1⇣2 ✗) &1 $       ⏱ 12s 130 INT🚫
#   │      │        │  │             │    │            │    │  │  │        │      └ 직전 명령의 종료 코드와 시그널 이름
#   │      │        │  │             │    │            │    │  │  │        └ 직전 명령이 오래 걸렸으면 걸린 시간
#   │      │        │  │             │    │            │    │  │  └ root 면 빨간 #
#   │      │        │  │             │    │            │    │  └ 백그라운드(멈춘 것 포함) job 수
#   │      │        │  │             │    │            │    └ 상태 표식 하나: 없음(깨끗) / ✗ / ✓
#   │      │        │  │             │    │            └ upstream 보다 앞선 / 뒤처진 커밋 수
#   │      │        │  │             │    └ 진행 중인 작업 (rebase-i 2/5, merge, cherry, bisect …)
#   │      │        │  │             └ 브랜치. detached 면 마젠타로 태그나 커밋 해시
#   │      │        │  └ 현재 디렉터리 (PROMPT_DIRTRIM 만큼 줄임)
#   │      │        └ zsh 표시. 직전 명령이 실패하면 빨강
#   │      └ ssh 로 들어왔을 때만
#   └ Python 가상환경이 켜져 있을 때만
# 없는 것은 칸째로 사라진다. 평소와 다를 때만 나타나는 것만 넣었다 (늘 켜져 있는 표식은 눈에 들어오지 않는다).
#
# git 괄호 안은 "무엇이 있나" 의 목록이 아니라 다음에 할 일을 알려 주는 표시등이다. 세부는 git status 로 본다.
#   (main)       깨끗하다                    (main ⇡1) push 할 것이 있다      (main ⇣2) 받아 올 것이 있다
#   (main ✗)     stage 하지 않은 것이 있다 (바뀐 파일, untracked 파일, 풀지 않은 충돌)
#   (main ✓)     바뀐 것이 전부 stage 됐다. 커밋하면 된다
#   (a1b2c3d|rebase-i 2/5 ✗)  rebase 중이고 아직 풀 것이 있다. ✓ 로 바뀌면 이어 가면 된다 (git rebase --continue)
#
# git 상태를 얻는 길은 둘이다.
#   gitstatus  plugins.zsh 가 데몬(gitstatusd)을 띄웠으면 그것에게 묻는다. 20ms 안에 답이 오면 그대로 그리고,
#              늦으면 지난 결과를 흐린 회색으로 먼저 그린 뒤 답이 오는 대로 다시 그린다 (입력은 막지 않는다).
#   git status 데몬이 없거나(실행 파일이 없는 머신, JW_ZSH_PLUGINS_DISABLE 로 끔) 죽었으면 프롬프트마다
#              _ps_set_git_status.bash 가 git status 를 직접 부른다 (bash 와 같은 방식. 끝날 때까지 기다린다).
# 두 길 모두 같은 _ps_* 변수를 채우고, _jw_prompt_git_render 가 그 변수로 git 칸을 만든다.
# 지금 어느 쪽인지: `echo $_jw_git_engine`

zmodload zsh/datetime   # EPOCHREALTIME (명령 실행 시간)
autoload -Uz add-zsh-hook

# 직전 명령이 이 초 이상 걸렸으면 RPROMPT 에 걸린 시간을 보여 준다. 끄려면 -1
typeset -g JW_PROMPT_ELAPSED_MIN=${JW_PROMPT_ELAPSED_MIN:-3}

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

# ==============================================================================
# git 칸
# ==============================================================================

# 프롬프트에서 사용하기 위한 git 상태를 저장하는 변수를 정의하는 함수 (gitstatus 를 쓸 수 없을 때 쓴다)
if [[ -f $HOME/.config/shell/_ps_set_git_status.bash ]]; then
	source "$HOME/.config/shell/_ps_set_git_status.bash"
fi

typeset -g  _jw_git_engine=     # 처음 프롬프트에서 정한다: gitstatus 또는 sync
typeset -gi _jw_git_pending=0   # gitstatus 에 물은 것의 답을 아직 받지 못했다
typeset -gi _jw_git_requery=0   # 답을 기다리는 사이에 프롬프트가 다시 그려졌다 (답이 오면 다시 묻는다)
typeset -g  _jw_git_stale=      # 지금 보이는 git 칸이 지난 결과다 (흐리게 그린다)
typeset -g  _jw_prompt_git=     # PROMPT 에 들어가는 git 칸 문자열

# _ps_* 변수로 git 칸을 만든다. 저장소 밖이면 빈 문자열.
# PROMPT 안에서 ${…:+…} 로 조립하지 않고 문자열을 미리 만들어 두는 이유: 지난 결과를 흐리게 그릴 때 색을 한꺼번에
# 바꿔야 하고, 브랜치 이름의 % 를 막아야 한다 (PROMPT_SUBST 는 변수 값 속의 $(…) 는 다시 실행하지 않지만 % 는 해석한다).
_jw_prompt_git_render() {
	emulate -L zsh
	_jw_prompt_git=
	[[ -n $_ps_branch ]] || return 0

	local paren='%F{cyan}' branch='%F{yellow}' red='%F{red}' green='%F{green}'
	[[ -n $_ps_detached_color ]] && branch='%F{magenta}'
	if [[ -n $_jw_git_stale ]]; then
		paren='%F{8}' branch='%F{8}' red='%F{8}' green='%F{8}'
	fi

	local s=" %B${paren}(${branch}${_ps_branch//\%/%%}"
	[[ -n $_ps_action ]] && s+="${red}|${_ps_action}"
	[[ -n $_ps_has_upstream_diff ]] && s+=' '
	[[ -n $_ps_upstream_ahead ]] && s+="${green}⇡${_ps_upstream_ahead}"
	[[ -n $_ps_upstream_behind ]] && s+="${red}⇣${_ps_upstream_behind}"
	[[ -n $_ps_unstaged_icon ]] && s+=" ${red}${_ps_unstaged_icon}"
	[[ -n $_ps_staged_icon ]] && s+=" ${green}${_ps_staged_icon}"
	s+="${paren})%f%b"
	_jw_prompt_git=$s
}

# gitstatus 의 답(VCS_STATUS_*)을 _ps_* 변수로 옮긴다. 값의 뜻은 _ps_set_git_status.bash 와 같다.
# 개수는 세지 않고(plugins.zsh 의 gitstatus_start 기본값: 종류마다 1개까지만) 있다/없다만 쓴다.
_jw_prompt_git_from_gitstatus() {
	_ps_branch= _ps_detached_color= _ps_action=
	_ps_upstream_ahead= _ps_upstream_behind= _ps_has_upstream_diff=
	_ps_unstaged_icon= _ps_staged_icon=
	[[ $VCS_STATUS_RESULT == ok-* ]] || return 0

	if [[ -n $VCS_STATUS_LOCAL_BRANCH ]]; then
		_ps_branch=$VCS_STATUS_LOCAL_BRANCH
	else
		_ps_branch=${VCS_STATUS_TAG:-${VCS_STATUS_COMMIT[1,7]}}
		_ps_detached_color=35
	fi
	_ps_action=$VCS_STATUS_ACTION
	(( VCS_STATUS_COMMITS_AHEAD )) && _ps_upstream_ahead=$VCS_STATUS_COMMITS_AHEAD
	(( VCS_STATUS_COMMITS_BEHIND )) && _ps_upstream_behind=$VCS_STATUS_COMMITS_BEHIND
	(( VCS_STATUS_COMMITS_AHEAD || VCS_STATUS_COMMITS_BEHIND )) && _ps_has_upstream_diff=1
	# HAS_* 는 1(있음) 0(없음) -1(세지 않음: gitstatus_start -m 을 넘는 큰 저장소. 지금은 쓰지 않는다)
	if (( VCS_STATUS_HAS_UNSTAGED == 1 || VCS_STATUS_HAS_UNTRACKED == 1 || VCS_STATUS_HAS_CONFLICTED == 1 )); then
		_ps_unstaged_icon='✗'
	elif (( VCS_STATUS_HAS_STAGED == 1 )); then
		_ps_staged_icon='✓'
	fi
	return 0
}

# precmd: git 칸을 새로 만든다.
_jw_prompt_git_update() {
	emulate -L zsh

	if [[ -z $_jw_git_engine ]]; then
		# plugins.zsh 가 데몬을 띄우기만 하고(gitstatus_start -a) 돌아왔다. 여기서 준비가 끝나기를 기다린다.
		# 셸이 뜨는 동안 데몬도 같이 떠서 보통 바로 끝난다. 실패하면 gitstatus 가 까닭을 stderr 에 길게 적는다.
		_jw_git_engine=sync
		(( $+functions[gitstatus_start] )) && gitstatus_start JW && _jw_git_engine=gitstatus
	fi

	if [[ $_jw_git_engine == gitstatus ]]; then
		if gitstatus_check JW; then
			if (( _jw_git_pending )); then
				# 앞서 물은 것의 답이 아직 없다. 같은 이름으로 겹쳐 물으면 안 되므로(gitstatus_query 설명) 답이 오면 다시 묻는다
				_jw_git_requery=1
				_jw_git_stale=1
				_jw_prompt_git_render
				return 0
			fi
			# -t: 이만큼은 기다린다. 작은 저장소는 대개 이 안에 답이 와서 다시 그리지 않아도 된다 (깜빡이지 않는다)
			# -c: 늦으면 답이 왔을 때 이 함수를 부른다
			# stderr 를 버리는 이유: 데몬이 죽었으면 요청을 쓰다가 "write error: broken pipe" 가 나는데, 아래에서 따로 알린다
			if gitstatus_query -t 0.02 -c _jw_prompt_git_on_async JW 2>/dev/null; then
				if [[ $VCS_STATUS_RESULT == tout ]]; then
					# 지난 결과(_ps_* 를 그대로 둠)를 흐리게 그려 둔다
					_jw_git_pending=1
					_jw_git_stale=1
				else
					_jw_prompt_git_from_gitstatus
					_jw_git_stale=
				fi
				_jw_prompt_git_render
				return 0
			fi
		fi
		# 데몬이 죽었거나 답이 깨졌다 (gitstatus 가 스스로 데몬을 멈춘다). 이 셸에서는 git status 로 바꾼다.
		# 다시 쓰려면 새 셸을 연다 (exec zsh).
		print -ru2 -- '[prompt] gitstatusd 가 멈춰서 이 셸은 git status 로 git 칸을 그린다 (다시 쓰려면 exec zsh)'
		_jw_git_engine=sync
		_jw_git_pending=0
		_jw_git_requery=0
	fi

	_jw_git_stale=
	(( $+functions[_ps_set_git_status] )) && _ps_set_git_status
	_jw_prompt_git_render
}

# gitstatus 의 답이 늦게 왔을 때 불린다. 줄 편집기(ZLE)가 입력을 기다리는 사이에 데몬의 fd 에 답이 오면
# gitstatus 가 zle -F 로 걸어 둔 처리 함수가 이것을 부른다. 그래서 입력 중인 줄을 건드리지 않고 프롬프트만 다시 그린다.
_jw_prompt_git_on_async() {
	emulate -L zsh
	_jw_git_pending=0
	if (( _jw_git_requery )); then
		# 이 답은 그 뒤에 그려진 프롬프트보다 오래됐다 (그 사이 명령을 실행했거나 cd 했다). 버리고 지금 디렉터리로 다시 묻는다
		_jw_git_requery=0
		if gitstatus_query -t 0 -c _jw_prompt_git_on_async JW 2>/dev/null; then
			_jw_git_pending=1
			return 0
		fi
	fi
	_jw_prompt_git_from_gitstatus
	_jw_git_stale=
	_jw_prompt_git_render
	zle && zle .reset-prompt
}

# ==============================================================================
# 오른쪽 칸: 걸린 시간, 종료 코드
# ==============================================================================
typeset -g _jw_prompt_cmd_start=   # 명령을 실행한 시각 (preexec). 빈 문자열이면 실행한 명령이 없다 (빈 줄에서 Enter)
typeset -g _jw_prompt_right=       # RPROMPT 에 들어가는 문자열

_jw_prompt_preexec() {
	_jw_prompt_cmd_start=$EPOCHREALTIME
}

# 초를 짧게 적어 REPLY 에 넣는다: 3.2s, 42s, 1m05s, 2h03m
_jw_prompt_format_duration() {
	local -F t=$1
	local -i s=$t
	if (( t < 10 )); then
		printf -v REPLY '%.1fs' $t
	elif (( s < 60 )); then
		REPLY="${s}s"
	elif (( s < 3600 )); then
		printf -v REPLY '%dm%02ds' $(( s / 60 )) $(( s % 60 ))
	else
		printf -v REPLY '%dh%02dm' $(( s / 3600 )) $(( s % 3600 / 60 ))
	fi
}

# precmd: RPROMPT 를 새로 만든다. 종료 코드를 보므로 add-zsh-hook 으로 걸어도 된다 (zsh 는 precmd 함수마다 $? 를
# 직전 명령의 값으로 되돌려 준다. terminal/tmux.zsh 머리말 참고).
_jw_prompt_right_update() {
	local -i code=$?
	local s=

	if [[ -n $_jw_prompt_cmd_start ]]; then
		local -F elapsed=$(( EPOCHREALTIME - _jw_prompt_cmd_start ))
		_jw_prompt_cmd_start=
		if (( JW_PROMPT_ELAPSED_MIN >= 0 && elapsed >= JW_PROMPT_ELAPSED_MIN )); then
			_jw_prompt_format_duration $elapsed
			s+="%F{yellow}⏱ ${REPLY}%f"
		fi
	fi

	if (( code )); then
		# 128+n 은 시그널 n 으로 끝났다는 뜻이다 (130 = Ctrl-C 의 INT, 137 = KILL, 143 = TERM).
		# $signals 는 zsh 의 시그널 이름 배열로 0번(EXIT)부터 시작해서 시그널 n 은 n+1 번째다.
		local name=
		(( code > 128 && code - 128 < $#signals )) && name=${signals[code - 128 + 1]}
		s+="${s:+ }%F{red}${code}${name:+ $name}🚫%f"
	fi
	_jw_prompt_right=$s
}

# ==============================================================================
# 가상환경 칸
# ==============================================================================
# venv 의 activate 스크립트가 PS1 앞에 (이름) 을 덧붙이지 않게 한다. 대신 아래에서 그린다.
# mise 처럼 activate 없이 VIRTUAL_ENV 만 정하는 도구로 켠 가상환경도 같은 모양으로 보인다.
typeset -g VIRTUAL_ENV_DISABLE_PROMPT=1
typeset -g _jw_prompt_venv=

_jw_prompt_venv_update() {
	emulate -L zsh
	_jw_prompt_venv=
	[[ -n $VIRTUAL_ENV ]] || return 0
	local name=${VIRTUAL_ENV:t}
	# .venv 처럼 흔한 이름이면 그 위 디렉터리(대개 프로젝트) 이름을 쓴다
	[[ $name == (.|)(venv|env) ]] && name=${VIRTUAL_ENV:h:t}
	_jw_prompt_venv="%F{blue}(${name//\%/%%})%f "
}

# ==============================================================================
# 조립
# ==============================================================================
# 종료 코드를 보는 함수를 먼저 건다 (위 설명대로 순서는 상관없지만 읽기 쉽게)
add-zsh-hook precmd _jw_prompt_right_update
add-zsh-hook precmd _jw_prompt_venv_update
add-zsh-hook precmd _jw_prompt_git_update
add-zsh-hook preexec _jw_prompt_preexec

PROMPT='${_jw_prompt_venv}'
if [[ -n $SSH_CLIENT || -n $SSH_TTY ]]; then
	# 원격 접속 시에는 <user>@<host>를 추가로 표시
	PROMPT+='%F{green}%n%F{magenta}@%m%f'
fi
# 🅩 로 Zsh 임을 표시. 직전 명령이 실패했으면 빨강
PROMPT+='%B%(?:%f:%F{red})🅩%b '
# 현재 디렉토리 경로를 표시
PROMPT+='%F{cyan}%U${${${(M)PROMPT_DIRTRIM:#(+|)<1->}:+%($((PROMPT_DIRTRIM+3))~:%-1~/.../%$((PROMPT_DIRTRIM))~:%~)}:-%~}%u%f'
# git 칸 (저장소 밖이면 비어 있다)
PROMPT+='${_jw_prompt_git}'
# 백그라운드 job 이 있으면 &개수 (Ctrl-Z 로 멈춘 것 포함. `jobs` 로 목록, `fg` 로 돌아가기)
PROMPT+='%(1j. %F{yellow}&%j%f.)'
# 끝에 $. root 셸이면 빨간 #
PROMPT+=' %(!.%B%F{red}#%f%b.$) '

RPROMPT='${_jw_prompt_right}'
