# shellcheck shell=bash

# prompt 설정을 위한 다음 전역 변수들을 설정한다. (prompt string)
# - _ps_branch: 현재 브랜치 명
# - _ps_staged_icon: Staged 변경 사항이 있으면 ✓, 없으면 빈 문자열
# - _ps_unstaged_icon: Unstaged 변경 사항이 있으면 ✗, 없으면 빈 문자열
# - _ps_upstream_ahead: Upstream보다 앞선 커밋 수 (0이면 빈 문자열)
# - _ps_upstream_behind: Upstream보다 뒤처진 커밋 수 (0이면 빈 문자열)
# 이 변수들을 Prompt 변수(PS1/PROMPT)에서 사용한다.
_ps_set_git_status() {
	# 프롬프트에서 사용해야 하므로 매번 초기화해야 한다.
	_ps_branch=""
	_ps_staged_icon=""
	_ps_unstaged_icon=""
	_ps_upstream_ahead=""
	_ps_upstream_behind=""
	_ps_has_upstream_diff=""

	local line tag index_status work_status
	local branch="" oid=""
	local has_staged=0
	local has_unstaged=0

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

		# Untracked (?) 또는 Conflict (u) 감지
		if [[ "$tag" == "?" || "$tag" == "u" ]]; then
			has_unstaged=1
			break # Unstaged 확정이므로 루프 즉시 탈출 (속도 최적화)
		fi

		# Tracked 파일 변경 감지 (1: 일반, 2: 이름변경/복사)
		if [[ "$tag" == "1" || "$tag" == "2" ]]; then
			# Staged 영역 (X)
			index_status="${line:2:1}"
			# Unstaged 영역 (Y) - v2에서는 변경 없으면 '.' 표시
			work_status="${line:3:1}"

			if [[ "$work_status" != "." ]]; then
				has_unstaged=1
				break # Unstaged 확정이므로 루프 즉시 탈출 (속도 최적화)
			fi

			if [[ "$index_status" != "." ]]; then
				has_staged=1
			fi
		fi
	done < <(git --no-optional-locks status --porcelain=v2 --branch 2>/dev/null)

	# Git 저장소가 아니거나 브랜치가 없으면 종료
	[[ -z "$branch" ]] && return

	if [[ "$branch" == "(detached)" ]]; then
		# Detached HEAD 상태이면 커밋 해시 7자리를 브랜치 대신 표시
		_ps_branch="${oid:0:7}" # 7자리 짧은 해시
	else
		_ps_branch="$branch"
	fi

	if [[ "$has_unstaged" -eq 1 ]]; then
		_ps_unstaged_icon="✗"
	elif [[ "$has_staged" -eq 1 ]]; then
		_ps_staged_icon="✓"
	fi

}
