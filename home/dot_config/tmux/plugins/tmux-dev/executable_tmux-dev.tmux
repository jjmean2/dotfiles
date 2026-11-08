#!/usr/bin/env bash
# tmux-dev 진입 스크립트. tmux.conf 의 `run-shell <이 파일>` 이 한 번 실행하고, 이 스크립트는
# tmux bind-key 로 키를 등록한다. 그게 "tmux 플러그인" 의 전부다: tmux 에 플러그인 API 는 없고,
# run-shell 이 돌린 스크립트가 tmux 명령을 부를 뿐이다 (TPM 도 이 파일을 실행해 주는 설치기다).
#
# 설정은 tmux 사용자 옵션으로, run-shell 줄보다 앞에 둔다. 없으면 기본값.
#   set -g @tmux-dev-project-key  S         prefix S: 프로젝트 → 세션 (소문자 s 는 순정 세션 목록)
#   set -g @tmux-dev-worktree-key W         prefix W: 워크트리·디렉토리 → 윈도우 (소문자 w 는 순정 윈도우 트리)
#   set -g @tmux-dev-popup-size   85%,75%   피커 창 너비,높이
#   set -g @tmux-dev-layout       ide       새 세션·윈도우의 패널 배치 (ide: 왼쪽 셸 / 오른쪽 nvim, plain: 셸 하나)
#
# 두 피커 모두 modal floating pane 으로 뜬다 (display-popup 은 tmux 3.9 부터 floating pane 을 여는 호환 명령으로만 남는다).
# run-shell 로 런처(libexec/tmux-dev-open)를 부르고, 런처가 키를 누른 클라이언트·패널·디렉토리를 피커에 넘긴다. 크기·레이아웃
# 옵션은 키를 누를 때 읽는다. 피커가 끝나면 피커 패널도 닫힌다. prefix W 는 패널이 아니라 세션의 디렉토리를 기준으로 한다.
set -eu
DIR=$(cd "$(dirname "$0")" && pwd)
opt() { local v; v=$(tmux show-option -gqv "$1"); printf '%s' "${v:-$2}"; }

key_project=$(opt @tmux-dev-project-key S)
key_worktree=$(opt @tmux-dev-worktree-key W)
# #{q:...} 는 셸에 넘길 수 있게 특수 문자를 이스케이프한다 (경로에 공백·따옴표가 있어도 한 인자).
# -b: 런처는 패널을 띄우고 바로 끝나지만, 명령 큐를 붙잡지 않게 백그라운드로.
# 레이아웃은 런처가 전역 기본값(@tmux-dev-layout)을 환경변수로 넘긴다. 명령줄 --layout 으로 넘기지 않는 이유: 스크립트가
# "명령줄에서 명시한 값" 과 "전역 기본값" 을 구분해야 저장소별 git config tmux-dev.layout 이 그 사이에 끼어들 수 있다 (lib/layout.sh).
tmux bind-key "$key_project" run-shell -b \
  "$DIR/bin/tmux-dev open project '#{client_name}' '#{pane_id}' #{q:pane_current_path}"
tmux bind-key "$key_worktree" run-shell -b \
  "$DIR/bin/tmux-dev open worktree '#{client_name}' '#{pane_id}' #{q:pane_current_path}"
