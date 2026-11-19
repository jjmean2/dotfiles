#!/usr/bin/env bash
# agent-state tmux 어댑터. tmux.conf 의 `run-shell <이 파일>` 이 한 번 실행한다.
# 에이전트 훅(claude-plugins/agent-state)이 패널에 써 둔 사용자 옵션(@agent_state 등)을 읽어 보여 주기만 한다.
# 계약과 설계: docs/agent-state.md
#
# 만드는 것 (tmux.conf 의 포맷이 #{E:@agent_badge} 처럼 꺼내 쓴다. 이 파일을 빼면 조각이 비어 아무것도 그리지 않는다)
#   @agent_badge        탭(window-status-format)용. 그 윈도우의 모든 패널 중 가장 급한 상태 하나 (+ 대기 개수)
#   @agent_tab_style    탭 바탕(window-status-style)용. 대기·오류가 있는 윈도우는 탭 전체를 노랑·빨강으로, 아니면 빈 값
#   @agent_summary      상태바(status-right)용. 모든 세션을 통틀어 상태별 개수 "◆2 ✘1 ✔1 ⋯3" (0 인 것은 뺀다)
#   @agent_pane_badge   패널 테두리(pane-border-format)용. 그 패널의 상태
#   @agent_st           패널의 상태 식: @agent_state 가 있으면 그것, 없으면 진행 표시 #{pane_pb_state} 에서 (위 모든 조각이 쓴다)
#                       — 백그라운드 세션은 자기 tty 로 OSC 9;4 를 내고 데몬이 붙어 있는 패널로 넘겨 주므로 여기로 잡힌다
#   pane-focus-in 훅    다른 데서 들어오면 그 패널의 done 을 지운다 (봤으므로, bin/agent-state-ack)
#   prefix a            에이전트가 있는 패널만 모은 choose-tree (floating pane). Enter 로 그 패널로 간다
#   prefix M-a          나를 기다리는 다음 패널로 바로 가기 (waiting → error → done, 오래된 것부터)
#   prefix M-A          지금 패널의 표시 지우기 (Esc 로 거절·중단하면 훅이 오지 않아 남는 표시용)
#
# 설정 (run-shell 줄보다 앞에서 set -g, 없으면 기본값)
#   @agent-state-icon-{running,waiting,done,error}    ⋯ ◆ ✔ ✘
#   @agent-state-color-{running,waiting,done,error}   (글자색) #f9e2af #a6e3a1 #f38ba8   빈 값 = 색 안 바꿈
#   @agent-state-tab-paint        on      off 면 탭 바탕을 칠하지 않는다 (아이콘만)
#   @agent-state-tab-fg           #11111b 칠한 탭의 글자색
#   @agent-state-clear-on-focus   on      off 면 done 을 들어와도 지우지 않는다 (다음 프롬프트까지 남는다)
#   @agent-state-tree-key         a       빈 값이면 묶지 않는다
#   @agent-state-jump-key         M-a
#   @agent-state-clear-key        M-A
#   @agent-state-tree-size        85%,75% 모아 보기 창의 너비,높이
#   @agent-state-progress         on      off 면 진행 표시(OSC 9;4)를 상태로 읽지 않는다 (다른 프로그램의 진행 표시를 빼고 싶을 때)
# 비용: 주기 작업(#())이나 상주 프로세스가 없다. 포맷은 tmux 가 다시 그릴 때 안에서 계산하고, 스크립트는 키를 누르거나
#       done 패널에 들어갈 때만 뜬다.
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
tab_paint=$(optd @agent-state-tab-paint on)
tab_fg=$(optd @agent-state-tab-fg '#11111b')

# 색을 입힌 아이콘. 뒤의 #[default] 는 그 포맷의 바탕 스타일(window-status-style 등)로 되돌린다.
paint() { if [ -n "$1" ]; then printf '#[fg=%s]%s#[default]' "$1" "$2"; else printf '%s' "$2"; fi; }
# 탭용: $3 = 색을 빼는 조건. 바탕이 아이콘과 같은 색으로 칠해지는 탭(벨 탭, 대기·오류로 칠한 탭)에서는 아이콘이 묻히므로
# 색을 입히지 않고 탭 글자색을 쓴다.
paint_tab() {
  if [ -n "$1" ]; then printf '#{?%s,,#[fg=%s]}%s#[default]' "$3" "$1" "$2"; else printf '%s' "$2"; fi
}

# 패널의 상태 = 패널 옵션 @agent_state 가 있으면 그것(훅이 자기 패널을 알 때 — 이유까지 있다), 없으면 진행 표시
# #{pane_pb_state} 에서 읽는다(훅이 자기 tty 로 낸 OSC 9;4. 백그라운드 세션은 데몬이 붙어 있는 패널로 넘겨 준다).
#   indeterminate → running, paused → waiting, error → error, normal → done, hidden → 없음
# 다른 프로그램이 낸 OSC 9;4 도 에이전트로 보인다. 원치 않으면 @agent-state-progress off.
if [ "$(optd @agent-state-progress on)" = on ]; then
  st='#{?#{@agent_state},#{@agent_state},#{?#{==:#{pane_pb_state},paused},waiting,#{?#{==:#{pane_pb_state},error},error,#{?#{==:#{pane_pb_state},indeterminate},running,#{?#{==:#{pane_pb_state},normal},done,}}}}}'
else
  st='#{@agent_state}'
fi
tmux set -g @agent_st "$st"     # jump·ack 스크립트와 사람이 쓸 수 있게 (#{E:@agent_st})

# 탭: #{P:…} 로 윈도우의 모든 패널을 훑는다. 활성 패널만 보는 #{@agent_state} 로는 다른 패널의 에이전트를 놓친다.
# #{P:a,b} 의 쉼표는 "활성 패널용 포맷" 구분자라 구분자로 공백을 쓴다.
all="#{P:$st }"
n_wait="#{n:#{P:#{?#{==:$st,waiting},x,}}}"
# 칠한 탭 = 현재 윈도우가 아니고(현재 탭은 원래 색으로 "여기" 를 보여 준다) 대기·오류가 있는 탭.
painted='0'
[ "$tab_paint" != on ] || painted="#{&&:#{!=:#{window_active},1},#{m:*waiting*,$all}}"
painted_err='0'
[ "$tab_paint" != on ] || painted_err="#{&&:#{!=:#{window_active},1},#{m:*error*,$all}}"
nocolor_wait="#{||:#{window_bell_flag},$painted}"
nocolor_err="#{||:#{window_bell_flag},$painted_err}"
badge="#{?#{m:*waiting*,$all}, $(paint_tab "$c_wait" "$i_wait#{?#{e|>|:$n_wait,1},$n_wait,}" "$nocolor_wait"),"
badge+="#{?#{m:*error*,$all}, $(paint_tab "$c_err" "$i_err" "$nocolor_err"),"
badge+="#{?#{m:*done*,$all}, $(paint_tab "$c_done" "$i_done" '#{window_bell_flag}'),"
badge+="#{?#{m:*running*,$all}, $(paint_tab "$c_run" "$i_run" '#{window_bell_flag}'),}}}}"
tmux set -g @agent_badge "$badge"

# 탭 바탕. 값은 스타일 문자열이거나 빈 값이고, tmux.conf 의 window-status-style 이 "비었으면 원래 색" 으로 쓴다.
# 스타일 안의 쉼표는 조건 분기 구분자와 겹치므로 #, 로 쓴다.
if [ "$tab_paint" = on ]; then
  tmux set -g @agent_tab_style "#{?#{m:*waiting*,$all},fg=$tab_fg#,bg=$c_wait#,bold,#{?#{m:*error*,$all},fg=$tab_fg#,bg=$c_err#,bold,}}"
else
  tmux set -g @agent_tab_style ''
fi

# 상태바 요약: #{S:#{W:#{P:…}}} 로 모든 세션의 모든 윈도우의 모든 패널을 훑어 상태별로 센다. 탭에는 지금 세션의 윈도우만 보이므로
# 다른 세션(다른 프로젝트)의 에이전트가 기다리는 것은 여기서 보인다.
count() { printf '#{n:#{S:#{W:#{P:#{?#{==:%s,%s},x,}}}}}' "$st" "$1"; }
summary=''
for s in waiting error done running; do
  case $s in
    waiting) c=$c_wait i=$i_wait ;;
    error)   c=$c_err  i=$i_err ;;
    done)    c=$c_done i=$i_done ;;
    running) c=$c_run  i=$i_run ;;
  esac
  n=$(count "$s")
  summary+="#{?#{e|>|:$n,0},$(paint "$c" "$i$n") ,}"
done
tmux set -g @agent_summary "$summary"

pane="#{?#{==:$st,waiting},$(paint "$c_wait" "$i_wait") ,"
pane+="#{?#{==:$st,error},$(paint "$c_err" "$i_err") ,"
pane+="#{?#{==:$st,done},$(paint "$c_done" "$i_done") ,"
pane+="#{?#{==:$st,running},$(paint "$c_run" "$i_run") ,}}}}"
tmux set -g @agent_pane_badge "$pane"

# [43]: 훅은 배열이라 번호 없이 걸면 [0] 에 들어가 다른 설정과 덮어쓰거나, 다시 읽을 때마다 쌓인다. 고정 번호면 둘 다 없다.
if [ "$(optd @agent-state-clear-on-focus on)" = on ]; then
  # 조건이 맞을 때만 스크립트를 띄운다 (패널을 옮길 때마다 프로세스를 만들지 않게).
  tmux set-hook -g 'pane-focus-in[43]' "if -F '#{==:$st,done}' 'run-shell -b \"$DIR/bin/agent-state-ack #{pane_id}\"'"
else
  tmux set-hook -gu 'pane-focus-in[43]'
fi

key_tree=$(opt @agent-state-tree-key a)
key_jump=$(opt @agent-state-jump-key M-a)
key_clear=$(opt @agent-state-clear-key M-A)

# 모아 보기: choose-tree 를 floating pane 에서 연다 (tmux man 의 `new-pane -E; choose-tree -hk` 꼴).
#   -f <상태>             에이전트가 있는 패널만. 그런 패널이 없는 윈도우·세션은 트리에서 빠진다
#   -F                    패널 줄 = "상태 (이유)  경로", 윈도우·세션 줄 = 이름
#   -h -k                 모드를 담은 floating pane 은 숨기고, 모드가 끝나면 그 패널을 닫는다
# 정렬은 tmux 가 번호·이름·활동 시각만 지원해 "대기 먼저" 는 안 된다. 바로 가기는 prefix M-a.
if [ -n "$key_tree" ]; then
  size=$(optd @agent-state-tree-size '85%,75%')
  fs=$(optd @float-style 'bg=#24253a,fg=default')
  fb=$(optd @float-border-style 'fg=#b4befe')
  fl=$(optd @float-border-lines single)
  line="#{?pane_format,$st#{?@agent_reason, (#{@agent_reason}),}  #{pane_current_path},#{?window_format,#{window_name},#{session_name}}}"
  # '\;' : 셸에서 그냥 ; 를 넘기면 tmux 명령줄이 "이번 호출의 구분자" 로 먹어서 move-pane 이 키에 묶이지 않고 바로 실행된다.
  # \; 로 넘겨야 bind-key 가 묶을 명령 안의 구분자로 받는다.
  tmux bind-key "$key_tree" new-pane -A -E -x "${size%,*}" -y "${size#*,}" -s "$fs" -S "$fb" -R "$fb" -B "$fl" '\;' \
    move-pane -P centre '\;' \
    choose-tree -hk -f "$st" -F "$line"
fi
[ -z "$key_jump" ] || tmux bind-key "$key_jump" run-shell -b "$DIR/bin/agent-state-jump '#{client_name}' '#{pane_id}'"
[ -z "$key_clear" ] || tmux bind-key "$key_clear" run-shell -b "$DIR/bin/agent-state-ack '#{pane_id}'"
