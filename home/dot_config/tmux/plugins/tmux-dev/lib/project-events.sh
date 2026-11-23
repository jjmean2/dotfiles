# shellcheck shell=bash
# tmux-dev project(prefix S) 피커의 "키마다 도는" 콜백과 그것이 쓰는 작은 함수들. libexec/tmux-dev-project 가 source 한다.
#
# 왜 따로 두나: lib/worktree-events.sh 와 같은 이유다. fzf 의 change 이벤트는 키를 누를 때마다 동기(transform)로 콜백을
# 띄우고, 그 시간만큼 fzf 가 다음 키를 받지 못한다. 진입 스크립트는 --on change|result|enter 를 이 파일과 common.sh·
# picker.sh 만 읽은 뒤 바로 처리하고 끝낸다 (dirs.sh·layout.sh 와 나머지 정의를 읽지 않는다). 여기의 함수는 그 밖의
# 콜백도 함께 쓴다.
#
# 규칙: 여기서는 외부 프로세스를 띄우지 않는다 (dirname·basename 같은 작은 도구도). 보안 에이전트(EDR)가 프로세스
# 실행마다 검사를 붙이는 머신에서는 그 하나하나가 수십 ms 다. 예외는 classify 의 없는 경로 판정(git·dirname·basename)
# 뿐이고, 그것은 경로 모양 검색어의 result(백그라운드)와 enter 에서만 돈다. test/tmux-dev/run 이 확인한다.

hint() { printf '%s' "${D}enter open · alt-enter new · alt-l layout · alt-m mode · alt-h keys${R}"; }
create_hint() {  # 검색어가 있으면 늘 보이는 만들기 안내 (결과가 있어도 alt-enter 는 친 이름으로 만든다)
  local q=${1%/} what="directory"; st_get mode; [ "${ST:-repo}" = repo ] && what="repository"
  printf '%s' "alt-enter create $what ${B}'$q'${R} ${D}· enter open · alt-h keys${R}"
}
footer_now() {  # 메인 목록의 푸터
  local q=${FZF_QUERY:-}
  if [ -z "$q" ]; then hint
  elif pathish "$q"; then
    if [ "${FZF_MATCH_COUNT:-1}" -eq 0 ]; then local mode; st_get mode; mode=${ST:-repo}; classify "$q" "$mode"; printf '%s' "$J_SAY"
    else printf '%s' "enter open the item ${D}· alt-enter create at the typed path${R}"; fi
  else create_hint "$q"; fi
}
decide() {  # $1 경로 $2 만들기(none|dir|repo) [$3 위치 피커에서 고른 부모] → 결정 파일을 쓰고 fzf 를 끝낸다
  local l="" s=""; st_get layout; [ -n "$ST" ] && IFS=$'\t' read -r l s <<< "$ST"
  st_set decision "$1$US$2$US$l$US$s$US${3:-}"   # 빈 칸이 있으므로 US. 탭이면 read 가 연속 탭을 하나로 합친다
  printf 'accept'
}
# 열 대상을 정한다: 커서 항목, 아니면 경로 모양 검색어가 가리키는 있는 디렉토리. J_KIND/J_PATH 를 채운다.
# 열 것이 없으면 안내 액션을 출력하고 1 (만들기는 alt-enter 의 몫이다)
open_target() {  # $1 커서 항목의 실제 경로 (없으면 빈 값)
  local mode q=${FZF_QUERY:-}; st_get mode; mode=${ST:-repo}
  stale_pick "$1" && return 1
  if [ -n "$1" ]; then J_PATH=$1; if [ -f "$1/.git" ]; then J_KIND=worktree; else J_KIND=open; fi; return 0; fi
  if pathish "$q"; then
    classify "$q" "$mode"
    case $J_KIND in open|worktree) return 0 ;; esac
    nope "$J_SAY"; return 1
  fi
  if [ -n "$q" ]; then nope "${Y}no match${R} · $(create_hint "$q")"; else nope "$(hint)"; fi
  return 1
}
on_enter() {
  st_del layout
  open_target "${1:-}" || return 0
  decide "$J_PATH" none
}
on_change() {
  local out="bg-cancel+"   # 이전 검색어로 돌던 푸터 판정(bg-transform)을 버린다. 늦게 끝난 낡은 결과가 덮지 않게
  if pathish "${FZF_QUERY:-}"; then printf '%srebind(result)+first+%s' "$out" "$(search_action "$FZF_QUERY")"
  else printf '%sunbind(result)+first+%s' "$out" "$(act change-footer "$(footer_now)")"; fi
}
on_result() { pathish "${FZF_QUERY:-}" && act change-footer "$(footer_now)"; return 0; }  # 경로 모양 검색어일 때만 묶인다
