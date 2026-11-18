#!/usr/bin/env bash
# agent-state tmux 어댑터. tmux.conf 의 `run-shell <이 파일>` 이 한 번 실행한다.
# 에이전트 훅(claude-plugins/agent-state)이 패널에 써 둔 사용자 옵션(@agent_state 등)을 읽어 보여 주기만 한다.
# 계약과 설계: docs/agent-state.md
#
# 만드는 것
#   @agent_badge        탭(window-status-format)용 포맷 조각. 그 윈도우의 모든 패널 중 가장 급한 상태 하나 (+ 대기 개수)
#   @agent_pane_badge   패널 테두리(pane-border-format)용 포맷 조각. 그 패널의 상태
#   pane-focus-in 훅    다른 데서 들어오면 그 패널의 done 을 idle 로 (봤으므로)
#   prefix a            나를 기다리는 다음 패널로 가기 (waiting → error → done, 오래된 것부터)
#   prefix M-a          지금 패널의 표시 지우기 (Esc 로 거절·중단하면 훅이 오지 않아 남는 표시용)
# tmux.conf 의 포맷이 #{E:@agent_badge} 처럼 꺼내 쓴다. 이 파일을 빼면 조각이 비어 아무것도 그리지 않는다.
#
# 설정 (run-shell 줄보다 앞에서 set -g, 없으면 기본값)
#   @agent-state-icon-{running,waiting,done,error}    ⋯ ◆ ✔ ✘
#   @agent-state-color-{running,waiting,done,error}   (탭 글자색) #f9e2af #a6e3a1 #f38ba8   빈 값 = 색 안 바꿈
#   @agent-state-clear-on-focus   on      off 면 done 을 들어와도 지우지 않는다 (다음 프롬프트까지 남는다)
#   @agent-state-jump-key         a       빈 값이면 묶지 않는다
#   @agent-state-clear-key        M-a     빈 값이면 묶지 않는다
set -eu
DIR=$(cd "$(dirname "$0")" && pwd)
# opt: 설정 안 했으면 기본값, 빈 값으로 설정했으면 빈 값 (키를 끌 때). -v 없이 물으면 설정 안 한 옵션은 아무 줄도 안 나온다.
opt() { if [ -n "$(tmux show-option -gq "$1")" ]; then tmux show-option -gqv "$1"; else printf '%s' "$2"; fi; }
optd() { local v; v=$(tmux show-option -gqv "$1"); printf '%s' "${v:-$2}"; }   # 빈 값도 기본값으로

i_run=$(optd @agent-state-icon-running '⋯')
i_wait=$(optd @agent-state-icon-waiting '◆')
i_done=$(optd @agent-state-icon-done '✔')
i_err=$(optd @agent-state-icon-error '✘')
c_run=$(tmux show-option -gqv @agent-state-color-running)
c_wait=$(optd @agent-state-color-waiting '#f9e2af')
c_done=$(optd @agent-state-color-done '#a6e3a1')
c_err=$(optd @agent-state-color-error '#f38ba8')

# 색을 입힌 아이콘. 뒤의 #[default] 는 그 포맷의 바탕 스타일(window-status-style 등)로 되돌린다.
paint() { if [ -n "$1" ]; then printf '#[fg=%s]%s#[default]' "$1" "$2"; else printf '%s' "$2"; fi; }
# 탭용: 벨이 울린 탭은 바탕이 노랗게(window-status-bell-style) 바뀌어 노란 ◆ 가 묻히므로, 그때는 색을 입히지 않고 탭 글자색을 쓴다.
paint_tab() { if [ -n "$1" ]; then printf '#{?window_bell_flag,,#[fg=%s]}%s#[default]' "$1" "$2"; else printf '%s' "$2"; fi; }

# 탭: #{P:…} 로 윈도우의 모든 패널을 훑는다. 그냥 #{@agent_state} 는 활성 패널 값만 읽어 다른 패널의 에이전트를 놓친다.
# #{P:a,b} 의 쉼표는 "활성 패널용 포맷" 구분자라 구분자로 공백을 쓴다.
all='#{P:#{@agent_state} }'
n_wait='#{n:#{P:#{?#{==:#{@agent_state},waiting},x,}}}'
badge="#{?#{m:*waiting*,$all}, $(paint_tab "$c_wait" "$i_wait#{?#{e|>|:$n_wait,1},$n_wait,}"),"
badge+="#{?#{m:*error*,$all}, $(paint_tab "$c_err" "$i_err"),"
badge+="#{?#{m:*done*,$all}, $(paint_tab "$c_done" "$i_done"),"
badge+="#{?#{m:*running*,$all}, $(paint_tab "$c_run" "$i_run"),}}}}"
tmux set -g @agent_badge "$badge"

pane="#{?#{==:#{@agent_state},waiting},$(paint "$c_wait" "$i_wait") ,"
pane+="#{?#{==:#{@agent_state},error},$(paint "$c_err" "$i_err") ,"
pane+="#{?#{==:#{@agent_state},done},$(paint "$c_done" "$i_done") ,"
pane+="#{?#{==:#{@agent_state},running},$(paint "$c_run" "$i_run") ,}}}}"
tmux set -g @agent_pane_badge "$pane"

# [43]: 훅은 배열이라 번호 없이 걸면 [0] 에 들어가 다른 설정과 덮어쓰거나, 다시 읽을 때마다 쌓인다. 고정 번호면 둘 다 없다.
if [ "$(optd @agent-state-clear-on-focus on)" = on ]; then
  tmux set-hook -g 'pane-focus-in[43]' "if -F '#{==:#{@agent_state},done}' 'set -p @agent_state idle'"
else
  tmux set-hook -gu 'pane-focus-in[43]'
fi

key_jump=$(opt @agent-state-jump-key a)
key_clear=$(opt @agent-state-clear-key M-a)
[ -z "$key_jump" ] || tmux bind-key "$key_jump" run-shell -b "$DIR/bin/agent-state-jump '#{client_name}' '#{pane_id}'"
[ -z "$key_clear" ] || tmux bind-key "$key_clear" if -F '#{@agent_state}' 'set -p @agent_state idle'
