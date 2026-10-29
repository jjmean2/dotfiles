# shellcheck shell=sh
# 1. 셸 시작 시 터미널(tty) 상태 저장 (-t 0 체크로 스크립트 실행 시 오류 방지)
if [ -t 0 ]; then
	INITIAL_STTY_SETTINGS=$(stty -g)
	export INITIAL_STTY_SETTINGS
fi

# 2. 초기 상태로 복구하는 함수
reset_stty() {
	if [ -n "$INITIAL_STTY_SETTINGS" ]; then
		stty "$INITIAL_STTY_SETTINGS"
		echo "터미널 상태가 초기 설정으로 복구되었습니다."
	else
		stty sane
		echo "저장된 초기 설정이 없어 'stty sane'으로 초기화했습니다."
	fi
}

# 3. 짧게 쓸 수 있는 alias (선택 사항)
alias restty='reset_stty'
