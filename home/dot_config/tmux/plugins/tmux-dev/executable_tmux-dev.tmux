#!/usr/bin/env bash
# tmux-dev 진입 스크립트. tmux.conf 의 `run-shell <이 파일>` 이 한 번 실행하고, 이 스크립트는
# tmux bind-key 로 키를 등록한다. 그게 "tmux 플러그인" 의 전부다: tmux 에 플러그인 API 는 없고,
# run-shell 이 돌린 스크립트가 tmux 명령을 부를 뿐이다 (TPM 도 이 파일을 실행해 주는 설치기다).
#
# 설정은 tmux 사용자 옵션으로, run-shell 줄보다 앞에 둔다. 없으면 기본값.
#   set -g @tmux-dev-project-key  S         prefix S: 프로젝트 → 세션 (소문자 s 는 순정 세션 목록)
#   set -g @tmux-dev-worktree-key W         prefix W: 워크트리·디렉토리 → 윈도우 (소문자 w 는 순정 윈도우 트리)
#   set -g @tmux-dev-popup-size   85%,75%   팝업 너비,높이
#   set -g @tmux-dev-layout       ide       새 세션·윈도우의 패널 배치 (ide: 왼쪽 셸 / 오른쪽 nvim, plain: 셸 하나)
#
# 팝업은 -d 로 현재 패널의 디렉토리에서 열린다. 그래서 후보 대신 상대 경로를 쳐도 그 기준으로 풀리고,
# worktree 는 그 패널이 속한 저장소를 본다. -E 는 명령이 끝나면 팝업을 닫는다.
set -eu
DIR=$(cd "$(dirname "$0")" && pwd)
opt() { local v; v=$(tmux show-option -gqv "$1"); printf '%s' "${v:-$2}"; }

key_project=$(opt @tmux-dev-project-key S)
key_worktree=$(opt @tmux-dev-worktree-key W)
size=$(opt @tmux-dev-popup-size '85%,75%'); w=${size%,*}; h=${size#*,}
layout=$(opt @tmux-dev-layout ide)

# 레이아웃은 전역 기본값으로 환경변수에 넘긴다 (-e). 명령줄 --layout 으로 넘기지 않는 이유: 스크립트가 "명령줄에서
# 명시한 값" 과 "전역 기본값" 을 구분해야 저장소별 git config tmux-dev.layout 이 그 사이에 끼어들 수 있다 (lib/layout.sh).
tmux bind-key "$key_project"  display-popup -E -d '#{pane_current_path}' -w "$w" -h "$h" -T ' project '  \
  -e "TMUX_DEV_LAYOUT=$layout" "$DIR/bin/tmux-dev project"
tmux bind-key "$key_worktree" display-popup -E -d '#{pane_current_path}' -w "$w" -h "$h" -T ' worktree ' \
  -e "TMUX_DEV_LAYOUT=$layout" "$DIR/bin/tmux-dev worktree"
