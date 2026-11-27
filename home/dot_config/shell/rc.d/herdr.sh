# shellcheck shell=sh
# Herdr 패널 안의 셸에서만 적용한다. Herdr 는 자기가 만든 패널에 HERDR_ENV=1 을 넣는다.
#
# agent-state 플러그인(claude-plugins/agent-state)의 데스크톱 알림을 끈다. Herdr 가 에이전트 상태를 스스로 감지해
# 알림(ui.toast)을 보내므로 둘 다 켜 두면 같은 일로 두 번 온다. 상태 기록(레코드 파일)은 그대로 남는다.
# 플러그인 옵션 notify_on 을 따로 정해 두었다면 그것이 이 값보다 우선한다 (bin/agent-state 의 notify).
# 설계: docs/herdr.md
if [ "${HERDR_ENV-}" = 1 ]; then
	export AGENT_STATE_NOTIFY_ON=off
fi
