#!/usr/bin/env bash
# agent-state tmux 어댑터. tmux.conf 의 `run-shell <이 파일>` 이 한 번 실행한다 (7번 섹션의 "확장").
# 에이전트 훅(claude-plugins/agent-state)이 패널에 써 둔 사용자 옵션(@agent_state 등)을 읽어 보여 주기만 한다.
# 계약과 설계: docs/agent-state.md
#
# tmux.conf 의 상태바·탭·패널 테두리(기본 층)는 이 어댑터를 모른다. 기본 층이 비워 둔 확장 슬롯(@slot_*)에
# 이 어댑터가 자기 조각의 참조를 등록하고, 기본 층은 그 자리를 펼칠 뿐이다 (슬롯 계약: tmux.conf 4번 섹션 "확장 슬롯").
#
# 만드는 것 (조각의 내용은 아래 옵션에, 슬롯에는 그 참조만 넣는다. 끄면 옵션이 비어 아무것도 그리지 않는다)
#   @agent_badge        → @slot_tab        탭용. 그 윈도우의 모든 패널 중 가장 급한 상태 하나 (+ 대기 개수)
#   @agent_tab_alert    → @slot_tab_alert  탭 바탕용. 대기가 있는 윈도우는 attn, 오류는 err, 아니면 빈 값.
#                                          기본 층이 그 탭의 바탕을 신호색으로 칠한다 (어떻게 칠할지는 기본 층이 정한다)
#   @agent_summary      → @slot_right      상태바용. 모든 세션을 통틀어 상태별 개수 "◆2 ✘1 ✔1 ⋯3" (0 인 것은 뺀다)
#   @agent_pane_badge   → @slot_pane       패널 테두리용. 그 패널의 상태
#   @agent_st           패널의 상태 식: @agent_state 가 있으면 그것, 없으면 진행 표시 #{pane_pb_state} 에서 (위 모든 조각이 쓴다)
#                       — 백그라운드 세션은 자기 tty 로 OSC 9;4 를 내고 데몬이 붙어 있는 패널로 넘겨 주므로 여기로 잡힌다
#   pane-focus-in 훅    다른 데서 들어오면 그 패널의 done 을 지운다 (봤으므로, bin/agent-state-ack)
#   prefix a            에이전트가 있는 패널만 모은 choose-tree (floating pane). Enter 로 그 패널로 간다
#   prefix M-a          나를 기다리는 다음 패널로 바로 가기 (waiting → error → done, 오래된 것부터)
#   prefix M-A          지금 패널의 표시 지우기 (Esc 로 거절·중단하면 훅이 오지 않아 남는 표시용)
#
# 켜고 끄기
#   agent-state.tmux off    조각을 비우고 키·훅을 푼다. 화면은 이 어댑터를 처음부터 읽지 않은 것과 같아진다.
#   agent-state.tmux on     다시 켠다.
#   둘 다 스위치 @agent-state-enable 을 적어 둔다. 그래서 끈 뒤 tmux.conf 를 다시 읽어도(prefix R) 꺼진 채로 남는다.
#   인자 없이 부르면(tmux.conf) 스위치를 따른다. 스위치가 없으면 켠다.
#
# 설정 (run-shell 줄보다 앞에서 set -g, 없으면 기본값)
#   @agent-state-enable           on      off 면 아무것도 등록하지 않는다 (위)
#   @agent-state-icon-{running,waiting,done,error}    ⋯ ◆ ✔ ✘
#   @agent-state-color-{running,waiting,done,error}   (아이콘 글자색)   빈 값 = 색 안 바꿈
#                                 기본값은 tmux.conf 팔레트의 신호색 @c_run @c_attn @c_ok @c_err 이다 (참조로 넣으므로
#                                 팔레트를 바꾸면 따라간다). 팔레트가 없는 설정에서는 #3b9eff #ffc400 #22e06b #ff3d5a.
#                                 탭 바탕을 칠하는 색은 여기가 아니라 기본 층이 정한다 (@c_attn, @c_err).
#   @agent-state-tab-paint        on      off 면 탭 바탕을 칠하게 하지 않는다 (아이콘만)
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
# tok: 기본 층에 팔레트 토큰이 있으면 그 참조(#{@c_x})를, 없으면 내 기본값을 낸다.
tok() { if [ -n "$(tmux show-option -gqv "$1")" ]; then printf '#{%s}' "$1"; else printf '%s' "$2"; fi; }
# reg: 슬롯에 참조를 덧붙인다. 이미 들어 있으면 다시 넣지 않는다 (이 스크립트만 다시 돌려도 쌓이지 않게).
reg() { local cur; cur=$(tmux show-option -gqv "$1"); case $cur in *"$2"*) ;; *) tmux set-option -ga "$1" "$2" ;; esac; }

key_tree=$(opt @agent-state-tree-key a)
key_jump=$(opt @agent-state-jump-key M-a)
key_clear=$(opt @agent-state-clear-key M-A)

# 끄기: 조각을 비우고 키·훅을 푼다. 슬롯에 남은 참조는 빈 값으로 펼쳐진다.
unload() {
  local o
  for o in @agent_badge @agent_tab_alert @agent_summary @agent_pane_badge @agent_st; do tmux set-option -g "$o" ''; done
  tmux set-hook -gu 'pane-focus-in[43]'
  [ -z "$key_tree" ]  || tmux unbind-key "$key_tree"  2>/dev/null || true
  [ -z "$key_jump" ]  || tmux unbind-key "$key_jump"  2>/dev/null || true
  [ -z "$key_clear" ] || tmux unbind-key "$key_clear" 2>/dev/null || true
}

case "${1:-}" in
  off) tmux set-option -g @agent-state-enable off ;;
  on)  tmux set-option -g @agent-state-enable on ;;
esac
if [ "$(optd @agent-state-enable on)" != on ]; then unload; exit 0; fi

i_run=$(optd @agent-state-icon-running '⋯')
i_wait=$(optd @agent-state-icon-waiting '◆')
i_done=$(optd @agent-state-icon-done '✔')
i_err=$(optd @agent-state-icon-error '✘')
c_run=$(opt @agent-state-color-running "$(tok @c_run '#3b9eff')")
c_wait=$(opt @agent-state-color-waiting "$(tok @c_attn '#ffc400')")
c_done=$(opt @agent-state-color-done "$(tok @c_ok '#22e06b')")
c_err=$(opt @agent-state-color-error "$(tok @c_err '#ff3d5a')")
tab_paint=$(optd @agent-state-tab-paint on)

# 색을 입힌 아이콘. 뒤의 #[default] 는 그 포맷의 바탕 스타일(window-status-style 등)로 되돌린다.
paint() { if [ -n "$1" ]; then printf '#[fg=%s]%s#[default]' "$1" "$2"; else printf '%s' "$2"; fi; }
# 굵게 + 색. 모아 보기의 상태 글자용 (목록에서 눈에 먼저 들어오게)
paint_b() { if [ -n "$1" ]; then printf '#[fg=%s]#[bold]%s#[default]' "$1" "$2"; else printf '#[bold]%s#[default]' "$2"; fi; }
# 탭용: 기본 층이 그 탭의 바탕을 밝은 색으로 칠했으면(@tab_filled: 벨 탭, 주의가 올라온 탭) 색을 입히지 않고 탭 글자색을 쓴다.
# 아이콘이 바탕과 같은 색이라 묻히기 때문이다. 기본 층에 그 식이 없으면 빈 값이라 늘 색을 입힌다.
paint_tab() { if [ -n "$1" ]; then printf '#{?#{E:@tab_filled},,#[fg=%s]}%s#[default]' "$1" "$2"; else printf '%s' "$2"; fi; }

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
badge="#{?#{m:*waiting*,$all}, $(paint_tab "$c_wait" "$i_wait#{?#{e|>|:$n_wait,1},$n_wait,}"),"
badge+="#{?#{m:*error*,$all}, $(paint_tab "$c_err" "$i_err"),"
badge+="#{?#{m:*done*,$all}, $(paint_tab "$c_done" "$i_done"),"
badge+="#{?#{m:*running*,$all}, $(paint_tab "$c_run" "$i_run"),}}}}"
tmux set -g @agent_badge "$badge"

# 탭 바탕: 주의 단계만 낸다 (대기 = attn, 오류 = err). 기본 층이 보고 있지 않은 탭을 그 단계의 신호색으로 칠한다
# (보고 있는 탭은 "여기" 를 보여 주는 원래 색 그대로다).
if [ "$tab_paint" = on ]; then
  tmux set -g @agent_tab_alert "#{?#{m:*waiting*,$all},attn,#{?#{m:*error*,$all},err,}}"
else
  tmux set -g @agent_tab_alert ''
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

# 슬롯에 등록한다. 기본 층에 슬롯이 없는 설정에서는 옵션만 생기고 아무도 읽지 않는다.
# @slot_tab_alert 는 값 하나짜리라, 비어 있거나 이미 내 것일 때만 쓴다.
reg @slot_tab   '#{E:@agent_badge}'
reg @slot_right '#{E:@agent_summary}'
reg @slot_pane  '#{E:@agent_pane_badge}'
case "$(tmux show-option -gqv @slot_tab_alert)" in
  ''|'#{E:@agent_tab_alert}') tmux set-option -g @slot_tab_alert '#{E:@agent_tab_alert}' ;;
esac

# [43]: 훅은 배열이라 번호 없이 걸면 [0] 에 들어가 다른 설정과 덮어쓰거나, 다시 읽을 때마다 쌓인다. 고정 번호면 둘 다 없다.
if [ "$(optd @agent-state-clear-on-focus on)" = on ]; then
  # 조건이 맞을 때만 스크립트를 띄운다 (패널을 옮길 때마다 프로세스를 만들지 않게).
  tmux set-hook -g 'pane-focus-in[43]' "if -F '#{==:$st,done}' 'run-shell -b \"$DIR/bin/agent-state-ack #{pane_id}\"'"
else
  tmux set-hook -gu 'pane-focus-in[43]'
fi

# 모아 보기: choose-tree 를 floating pane 에서 연다 (tmux man 의 `new-pane -E; choose-tree -hk` 꼴).
#   -f <상태>             에이전트가 있는 패널만. 그런 패널이 없는 윈도우·세션은 트리에서 빠진다
#   -F                    패널 줄 = "아이콘 상태 (이유)  경로", 윈도우·세션 줄 = 이름. 상태는 상태바와 같은 색 + 굵게
#                         (choose-tree 도 줄을 format_draw 로 그려 #[fg=…] 가 먹는다. 커서 줄은 선택 색이 이긴다)
#   -h -k                 모드를 담은 floating pane 은 숨기고, 모드가 끝나면 그 패널을 닫는다
#   new-pane -O + if      이미 떠 있으면 다시 눌러도 쌓이지 않는다 (아래)
# 정렬은 tmux 가 번호·이름·활동 시각만 지원해 "대기 먼저" 는 안 된다. 바로 가기는 prefix M-a.
if [ -n "$key_tree" ]; then
  size=$(optd @agent-state-tree-size '85%,75%')
  fs=$(optd @float-style 'bg=#24253a,fg=default')
  fb=$(optd @float-border-style 'fg=#b4befe')
  fl=$(optd @float-border-lines single)
  st_col="#{?#{==:$st,waiting},$(paint_b "$c_wait" "$i_wait waiting"),"
  st_col+="#{?#{==:$st,error},$(paint_b "$c_err" "$i_err error"),"
  st_col+="#{?#{==:$st,done},$(paint_b "$c_done" "$i_done done"),"
  st_col+="#{?#{==:$st,running},$(paint_b "$c_run" "$i_run running"),}}}}"
  line="#{?pane_format,$st_col#{?@agent_reason, (#{@agent_reason}),}  #{pane_current_path},#{?window_format,#{window_name},#{session_name}}}"
  # 한 번만 뜨게: prefix s·w 는 지금 패널에 choose-tree 를 열고, 이미 그 모드면 tmux 가 다시 열지 않는다(window_pane_set_mode).
  # 여기는 누를 때마다 새 패널을 만드므로 그 보호가 없어 모아 보기 안에서 prefix a 를 다시 누르면 패널이 쌓였다.
  #   -O       modal floating pane (tmux-dev 피커와 같다). 창마다 하나뿐이고 늘 활성 패널이다
  #   if -F    활성 패널이 modal 이면(= 이미 떠 있다) 아무것도 안 한다. 없으면 "window already has a modal pane" 오류가 뜬다
  # 묶을 명령은 if 에 문자열 하나로 넘기고 tmux 가 키를 누를 때 파싱한다. 값마다 작은따옴표로 싼다(값에 작은따옴표는 없다).
  open="new-pane -O -E -x '${size%,*}' -y '${size#*,}' -s '$fs' -S '$fb' -R '$fb' -B '$fl' ; move-pane -P centre ;"
  open+=" choose-tree -hk -f '$st' -F '$line'"
  tmux bind-key "$key_tree" if-shell -F '#{pane_modal_flag}' '' "$open"
fi
[ -z "$key_jump" ] || tmux bind-key "$key_jump" run-shell -b "$DIR/bin/agent-state-jump '#{client_name}' '#{pane_id}'"
[ -z "$key_clear" ] || tmux bind-key "$key_clear" run-shell -b "$DIR/bin/agent-state-ack '#{pane_id}'"
