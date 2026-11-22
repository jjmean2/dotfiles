# shellcheck shell=bash

# 프롬프트에 쓸 git 상태를 다음 전역 변수에 채운다. (prompt string)
# bash 프롬프트(rc.bash)가 쓰고, zsh 는 gitstatus 를 쓸 수 없을 때만 이것으로 대신한다 (prompt.zsh).
# zsh 가 gitstatus 로 채울 때도 같은 변수에 같은 값을 넣으므로 두 경로의 표시가 같다.
# - _ps_branch: 브랜치 이름. 브랜치가 아니면(detached) 그 커밋을 가리키는 태그, 없으면 커밋 해시 7자리
# - _ps_detached_color: detached 이면 35 (ANSI 마젠타), 아니면 빈 문자열
# - _ps_action: 진행 중인 작업과 단계. 예: "rebase-i 2/5", "merge", "cherry", "bisect". 없으면 빈 문자열
#               이름은 gitstatus 와 같다 (zsh 의 vcs_info 에서 온 이름). 아래 _ps_git_action 참고
# - _ps_upstream_ahead / _ps_upstream_behind: upstream 보다 앞선 / 뒤처진 커밋 수 (0이면 빈 문자열)
# - _ps_has_upstream_diff: 위 둘 중 하나라도 있으면 1
# - _ps_conflicted_icon: 충돌난 파일이 있으면 ≠
# - _ps_unstaged_icon: 추적 중인 파일에 stage 하지 않은 변경이 있으면 ✗
# - _ps_staged_icon: stage 한 변경이 있으면 ✓ (✗ 와 함께 나올 수 있다)
# - _ps_untracked_icon: 추적하지 않는 파일이 있으면 ?
# - _ps_stashes: stash 개수 (0이면 빈 문자열)
_ps_set_git_status() {
	# 프롬프트에서 사용해야 하므로 매번 초기화해야 한다.
	_ps_branch=""
	_ps_detached_color=""
	_ps_action=""
	_ps_upstream_ahead=""
	_ps_upstream_behind=""
	_ps_has_upstream_diff=""
	_ps_conflicted_icon=""
	_ps_unstaged_icon=""
	_ps_staged_icon=""
	_ps_untracked_icon=""
	_ps_stashes=""

	local line tag index_status work_status
	local branch="" oid=""
	local has_staged=0 has_unstaged=0 has_untracked=0 has_conflicted=0

	# git status --porcelain=v2 --branch 호출 (단 1회의 subshell/fork 실행)
	while IFS= read -r line; do
		[[ -z "$line" ]] && continue

		# 1. 헤더 정보 파싱 (# 으로 시작)
		if [[ "$line" == "#"* ]]; then
			if [[ "$line" == "# branch.head "* ]]; then
				branch="${line#\# branch.head }"
			elif [[ "$line" == "# branch.oid "* ]]; then
				oid="${line#\# branch.oid }"
			elif [[ "$line" == "# branch.ab "* ]]; then
				local ab="${line#\# branch.ab +}"
				local ahead="${ab%% *}"
				local behind="${ab#* -}"

				[[ "$ahead" -gt 0 ]] && _ps_upstream_ahead="$ahead"
				[[ "$behind" -gt 0 ]] && _ps_upstream_behind="$behind"
				if [[ -n "$_ps_upstream_ahead" || -n "$_ps_upstream_behind" ]]; then
					_ps_has_upstream_diff=1
				fi
			fi
			continue
		fi

		# 2. 파일 변경 사항 파싱
		# porcelain=v2에서 # branch.* 헤더는 항상 최상단에 출력되므로,
		# 파일 상태를 읽는 시점에는 이미 브랜치 및 upstream 정보 파싱이 끝난 상태다.
		tag="${line:0:1}"
		case "$tag" in
		'?') has_untracked=1 ;;
		u) has_conflicted=1 ;;
		1 | 2)
			# 1: 일반 변경, 2: 이름 바꿈/복사. 셋째 글자가 stage 쪽(X), 넷째가 작업 트리 쪽(Y). 변경이 없으면 '.'
			index_status="${line:2:1}"
			work_status="${line:3:1}"
			[[ "$index_status" != "." ]] && has_staged=1
			[[ "$work_status" != "." ]] && has_unstaged=1
			;;
		esac

		# 네 가지를 모두 찾았으면 더 읽을 필요가 없다 (변경 파일이 많은 저장소에서 루프를 일찍 끝낸다)
		((has_staged && has_unstaged && has_untracked && has_conflicted)) && break
	done < <(git --no-optional-locks status --porcelain=v2 --branch 2>/dev/null)

	# Git 저장소가 아니거나 브랜치가 없으면 종료
	[[ -z "$branch" ]] && return

	if [[ "$branch" == "(detached)" ]]; then
		# Detached HEAD: 그 커밋을 가리키는 태그를, 없으면 커밋 해시 7자리를 브랜치 대신 표시
		# (detached 일 때만 git 을 한 번 더 부른다)
		_ps_branch="$(git describe --tags --exact-match HEAD 2>/dev/null)"
		[[ -n "$_ps_branch" ]] || _ps_branch="${oid:0:7}"
		# magenta
		_ps_detached_color=35
	else
		_ps_branch="$branch"
	fi

	((has_conflicted)) && _ps_conflicted_icon="≠"
	((has_unstaged)) && _ps_unstaged_icon="✗"
	((has_staged)) && _ps_staged_icon="✓"
	((has_untracked)) && _ps_untracked_icon="?"

	# 진행 중인 작업과 stash 는 status 출력에 없어서 .git 안의 파일을 직접 본다.
	# 워크트리에서는 작업 상태가 그 워크트리의 git 디렉터리에, stash 는 공용 디렉터리에 있다.
	local git_dir="" common_dir=""
	{
		IFS= read -r git_dir
		IFS= read -r common_dir
	} < <(git rev-parse --git-dir --git-common-dir 2>/dev/null)
	[[ -n "$git_dir" ]] || return

	_ps_git_action "$git_dir"

	# stash 하나가 refs/stash 의 reflog 한 줄이다
	if [[ -r "$common_dir/logs/refs/stash" ]]; then
		local n=0
		while IFS= read -r line; do
			n=$((n + 1))
		done <"$common_dir/logs/refs/stash"
		((n > 0)) && _ps_stashes="$n"
	fi
}

# git 디렉터리 안의 파일로 진행 중인 작업을 알아내 _ps_action 에 넣는다.
# 판단 순서와 이름은 libgit2 의 git_repository_state 와 gitstatus 의 RepoState (src/git.cc) 를 따랐다.
# rebase 중이면 몇 번째 커밋을 적용하고 있는지(next/last)를 붙인다.
_ps_git_action() {
	local d="$1" action="" next="" last=""
	if [[ -d "$d/rebase-merge" ]]; then
		if [[ -f "$d/rebase-merge/interactive" ]]; then action="rebase-i"; else action="rebase-m"; fi
		[[ -r "$d/rebase-merge/msgnum" ]] && read -r next <"$d/rebase-merge/msgnum"
		[[ -r "$d/rebase-merge/end" ]] && read -r last <"$d/rebase-merge/end"
	elif [[ -d "$d/rebase-apply" ]]; then
		if [[ -f "$d/rebase-apply/rebasing" ]]; then
			action="rebase"
		elif [[ -f "$d/rebase-apply/applying" ]]; then
			action="am"
		else
			action="am/rebase"
		fi
		[[ -r "$d/rebase-apply/next" ]] && read -r next <"$d/rebase-apply/next"
		[[ -r "$d/rebase-apply/last" ]] && read -r last <"$d/rebase-apply/last"
	elif [[ -f "$d/MERGE_HEAD" ]]; then
		action="merge"
	elif [[ -f "$d/REVERT_HEAD" ]]; then
		if [[ -f "$d/sequencer/todo" ]]; then action="revert-seq"; else action="revert"; fi
	elif [[ -f "$d/CHERRY_PICK_HEAD" ]]; then
		if [[ -f "$d/sequencer/todo" ]]; then action="cherry-seq"; else action="cherry"; fi
	elif [[ -f "$d/BISECT_LOG" ]]; then
		action="bisect"
	fi
	[[ -n "$action" && -n "$next" && -n "$last" ]] && action+=" $next/$last"
	_ps_action="$action"
}
