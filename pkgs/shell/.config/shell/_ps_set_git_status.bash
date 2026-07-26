# shellcheck shell=bash

# prompt 설정을 위한 다음 전역 변수들을 설정한다. (prompt string)
# - _ps_branch: 현재 브랜치 명
# - _ps_staged_icon: Staged 변경 사항이 있으면 ✓, 없으면 빈 문자열
# - _ps_unstaged_icon: Unstaged 변경 사항이 있으면 ✗, 없으면 빈 문자열
# 이 변수들을 Prompt 변수(PS1/PROMPT)에서 사용한다.
_ps_set_git_status() {
	# 프롬프트에서 사용해야 하므로 매번 초기화해야 한다.
	_ps_branch=""
	_ps_staged_icon=""
	_ps_unstaged_icon=""
	# 1. 브랜치 명/커밋 해시 가져오기
	local branch
	# 다음을 써도 된다.
	# branch="$(git --no-optional-locks branch --show-current 2>/dev/null)"
	# 위의 명령 치환 방식은 fork한 서브쉘 내에서 다시 git 실행을 위해 fork를 하므로 fork가 2회가 된다.
	# 서브쉘이 git 출력값을 저장하고 메인 쉘로 보내주는 중간 다리 역할을 해야 하기 때문이다.
	# 다음과 같이 하면 서브쉘 내에서 fork 없이 바로 exec로 git을 실행하므로 fork 횟수가 1회다.
	# read 명령 실행 중에 메인쉘의 STDIN과 git 프로세스의 STDOUT만 파이프로 연결하면 되기에
	# 서브쉘에서 다시 fork를 해서 서브쉘을 남겨둘 필요가 없는 것이다.
	# read 명령 실행 완료 후에는 메인쉘의 STDIN을 다시 원래대로 복원한다.
	read -r branch < <(git --no-optional-locks branch --show-current 2>/dev/null)
	[[ -z "$branch" ]] && return

	_ps_branch="$branch"

	local has_staged=0
	local has_unstaged=0
	local line index_status work_status

	# 2. porcelain 결과 한 줄씩 파싱
	while IFS= read -r line; do
		[[ -z "$line" ]] && continue
		index_status="${line:0:1}" # Staged 영역 (X)
		work_status="${line:1:1}"  # Unstaged 영역 (Y)

		# Unstaged / Untracked 감지 (?? 포함)
		if [[ "$work_status" != " " || "$index_status" == "?" ]]; then
			has_unstaged=1
			# Unstaged가 하나라도 나오면 ✗ 확정이므로 루프 즉시 탈출 (속도 최적화)
			break
		fi

		# Staged 감지
		if [[ "$index_status" != " " ]]; then
			has_staged=1
		fi
	done < <(git --no-optional-locks status --porcelain 2>/dev/null)

	# 3. 우선순위에 따른 아이콘 결정
	if [[ $has_unstaged -eq 1 ]]; then
		_ps_unstaged_icon="✗"
	elif [[ $has_staged -eq 1 ]]; then
		_ps_staged_icon="✓"
	fi
}
