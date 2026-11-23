# shellcheck shell=bash
# tmux-dev worktree(prefix W) 피커의 "키마다 도는" 콜백과 그것이 쓰는 작은 함수들. libexec/tmux-dev-worktree 가 source 한다.
#
# 왜 따로 두나: fzf 의 change 이벤트는 키를 누를 때마다 동기(transform)로 이 콜백을 띄운다. 그 시간만큼 fzf 가 다음 키를
# 받지 못한다. 진입 스크립트는 1700줄이 넘고 lib 도 넷이라 bash 가 읽기만 해도 20ms 를 넘겼고(빈 bash 는 2ms), 마커 계산이
# CPU 를 쓰는 동안에는 몇 배로 늘어 입력이 멈춘 것처럼 느껴졌다. 그래서 진입 스크립트는 --on change|result 를 이 파일과
# common.sh·picker.sh 만 읽은 뒤 바로 처리하고 끝낸다 (나머지 정의를 읽지 않는다). 여기의 함수는 그 밖의 콜백도 함께 쓴다.
#
# 규칙: 여기서는 git·tmux 를 띄우지 않는다 (classify 의 없는 경로 판정에서 git 한 번만 예외. result 는 백그라운드다).
# 저장소 변수(MAIN, WT_LIST …)도 쓰지 않는다: 빠른 길에서는 비어 있어 set -u 로 조용히 죽는다. test/tmux-dev/run 이 확인한다.
# 필요한 값은 피커가 뜰 때 상태에 써 둔 것(session, base, root, mode)을 picker_ctx 로 읽는다.

: "${IN_REPO:=}"   # 진입 스크립트의 repo_try 가 저장소를 찾았으면 1. 빠른 길에서는 늘 비어 있다

# 콜백·목록·미리보기는 피커가 띄운 것이라 피커가 정해 둔 값을 상태에서 읽는다 (pick 이 쓴 session·base·root). 프로세스를
# 띄우지 않는다. 상태가 없으면(셸에서 부른 --list 등) 아무것도 바꾸지 않는다: 지금 디렉토리, 인자로 받은 값 그대로.
picker_ctx() {
  st_get session; SESSION=${SESSION:-$ST}
  st_get base; BASE=${BASE:-$ST}
  st_get root; [ -n "$ST" ] && [ -d "$ST" ] && cd "$ST"
  return 0
}

default_base() {  # origin/HEAD 가 가리키는 브랜치의 로컬 사본 → main → master → HEAD
  local b
  if b=$(git symbolic-ref -q --short refs/remotes/origin/HEAD 2>/dev/null); then
    b=${b#origin/}; git show-ref -q --verify "refs/heads/$b" && { echo "$b"; return; }
  fi
  for b in main master; do git show-ref -q --verify "refs/heads/$b" && { echo "$b"; return; }; done
  echo HEAD
}

base() { echo "${BASE:-$(default_base)}"; }

modes() { if [ -n "$IN_REPO" ]; then echo worktree subdirectory directory; else echo subdirectory directory; fi; }

cur_mode() { st_get mode; MODE=${ST:-}; [ -n "$MODE" ] || { if [ -n "$IN_REPO" ]; then MODE=worktree; else MODE=subdirectory; fi; }; }

hint() {
  if [ "$1" = worktree ]; then printf '%s' "${D}enter open · alt-enter new · ctrl-x clean up · tab select · ctrl-t merged · alt-m mode · alt-h keys${R}"
  else printf '%s' "${D}enter open · alt-enter new · alt-l layout · alt-m mode · alt-h keys${R}"; fi
}

create_hint() {  # $1 검색어 $2 모드. 검색어가 있으면 늘 보이는 만들기 안내
  local q=${1%/}
  if [ "$2" = worktree ]; then printf '%s' "alt-enter create branch ${B}'$q'${R} from $(base) ${D}· enter open · alt-h keys${R}"
  else printf '%s' "alt-enter create directory ${B}'$q'${R} ${D}· enter open · alt-h keys${R}"; fi
}

footer_now() {  # 지금 모드의 푸터 (검색어에 따라)
  local q=${FZF_QUERY:-}; cur_mode
  if [ -z "$q" ]; then hint "$MODE"
  elif [ "$MODE" != worktree ] && pathish "$q"; then
    if [ "${FZF_MATCH_COUNT:-1}" -eq 0 ]; then classify "$q" dir; printf '%s' "$J_SAY"
    else printf '%s' "enter open the item ${D}· alt-enter create at the typed path${R}"; fi
  else create_hint "$q" "$MODE"; fi
}

on_change() {  # 디렉토리 모드의 경로 모양 검색어는 접두 일치로
  local out=""
  st_get select_merged; [ "$ST" = 1 ] && { printf 'rebind(result)'; return 0; }   # ctrl-t 가 검색어를 지운 것: result 를 기다린다
  cur_mode
  # 이전 검색어로 돌던 푸터 판정(result 의 bg-transform)을 버린다. 그것은 디렉토리 모드에서만 돈다. bg-cancel 은 돌고 있는
  # bg-transform 을 모두 끊어서 피커가 뜰 때 띄운 백그라운드 fetch 도 죽이므로, worktree 모드에서는 보내지 않는다
  [ "$MODE" != worktree ] && out="bg-cancel+"
  if [ "$MODE" != worktree ] && pathish "${FZF_QUERY:-}"; then printf '%srebind(result)+first+%s' "$out" "$(search_action "$FZF_QUERY")"
  else printf '%sunbind(result)+first+%s' "$out" "$(act change-footer "$(footer_now)")"; fi
}

on_result() {
  st_get select_merged; if [ "$ST" = 1 ]; then st_del select_merged; printf 'unbind(result)+'; select_merged_actions; return 0; fi
  cur_mode; [ "$MODE" != worktree ] && pathish "${FZF_QUERY:-}" && act change-footer "$(footer_now)"; return 0
}

select_merged_actions() {
  local i=0 n=0 out="" _name disp kind _rest
  while IFS=$US read -r _name disp kind _rest; do   # 탭을 US 로 (on_cleanup_many 와 같은 이유)
    i=$((i + 1))
    case $kind in worktree|prunable|branch) ;; *) continue ;; esac
    case $disp in *"${G}merged${R}"*) out+="pos($i)+select+"; n=$((n + 1)) ;; esac   # 색까지 맞춘다: 경로·제목의 "unmerged" 같은 글자에 걸리지 않게
  done < <(tr '\t' '\037' < "$TMUX_DEV_STATE/rows")
  [ "$n" -gt 0 ] || { nope "${Y}nothing merged${R}"; return; }
  printf 'deselect-all+%sfirst+%s' "$out" "$(act change-footer "${G}selected $n merged${R} ${D}· ctrl-x clean up · tab toggle · ctrl-t deselect all${R}")"
}

# --- 고르기 (enter) ---------------------------------------------------------------
# 고르는 것도 상태만 쓰고 fzf 를 끝낸다(accept). 저장소 문맥이 필요 없어 빠른 길에서 돈다: 마커 계산이 git 으로 CPU 를
# 쓰는 동안에도 enter 가 바로 먹게.
busy() { st_get busy; [ "$ST" = 1 ] || return 1; printf 'bell'; }   # 정리 중이면 벨만 (푸터는 틱이 그린다)
decide() {  # $1 종류 $2 경로 $3 브랜치 [$4 만들기 dir] [$5 위치 피커에서 고른 부모] → 결정 파일을 쓰고 fzf 를 끝낸다
  local l="" s=""; st_get layout; [ -n "$ST" ] && IFS=$'\t' read -r l s <<< "$ST"
  st_set decision "$1$US$2$US$3$US$l$US$s$US${4:-}$US${5:-}"
  printf 'accept'
}
# 만들어야 하는 것은 만들기 확인 목록을 겹쳐 띄운다. 거기서 고르면 after-create 가 결정하고, esc 면 메인 목록이 그대로 남는다
confirm_create() {  # $1 종류 $2 경로 $3 브랜치 [$4 커서를 둘 행: 1 create, 2 create with layout]
  st_set target "$1$US$2$US$3"; st_set create_start "${4:-1}"; st_del layout create_choice
  printf 'execute(%s --choose-create)+transform(%s --on after-create)' "$SELF" "$SELF"
}
# worktree 모드의 행을 대상으로: 바로 열 것이면 결정, 만들어야 하면 확인 목록
worktree_target() {  # $1 종류 $2 경로 $3 브랜치 [$4 확인 목록의 커서 행]
  case $1 in
    worktree) decide worktree "$2" "$3" ;;
    prunable|branch|remote) confirm_create "$1" "$2" "$3" "${4:-1}" ;;
    *) printf 'bell' ;;
  esac
}
# 디렉토리 모드의 열 대상: 커서 항목, 아니면 경로 모양 검색어가 가리키는 있는 디렉토리. 없으면 안내 액션을 출력하고 1
dir_target() {  # $1 커서 항목의 경로
  local q=${FZF_QUERY:-}
  if [ -n "$1" ]; then J_PATH=$1; return 0; fi
  if pathish "$q"; then
    classify "$q" dir
    case $J_KIND in open|worktree) return 0 ;; esac
    nope "$J_SAY"; return 1
  fi
  if [ -n "$q" ]; then nope "${Y}no match${R} · $(create_hint "$q" "$MODE")"; else nope "$(hint "$MODE")"; fi
  return 1
}
on_enter() {  # $1 종류 $2 경로 $3 브랜치
  busy && return
  cur_mode; st_del layout
  if [ "$MODE" = worktree ]; then
    [ -n "${1:-}" ] || { local q=${FZF_QUERY:-}; if [ -n "$q" ]; then nope "${Y}no match${R} · $(create_hint "$q" worktree)"; else nope "$(hint worktree)"; fi; return; }
    worktree_target "$1" "${2:-}" "${3:-}"
  else
    dir_target "${2:-}" || return 0
    decide dir "$J_PATH" ""
  fi
}
