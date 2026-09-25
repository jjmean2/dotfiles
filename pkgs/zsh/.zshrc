# shellcheck disable=SC1091
if [[ -r $HOME/.config/shell/rc.sh ]]; then
	source "$HOME/.config/shell/rc.sh"
fi

# shellcheck disable=SC1090
# .jongwan/bin/zsh-perf에서 명령 간의 실행 시간을 기록할 때 사용자의 명령을 대기하는 대기 시간이 명령 실행시간으로 잡히지 않도록 hook을 추가하는 설정
# ZSH_PERF_HOOK 환경 변수는 zsh-perf가 zsh 세션을 실행할 때 넣어주는 파일 경로로 zsh-perf로 실행한 zsh 세션에서만 적용될 예정
if [[ -n ${ZSH_PERF_HOOK-} ]]; then
  source "$ZSH_PERF_HOOK"
fi
