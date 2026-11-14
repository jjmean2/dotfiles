# shellcheck shell=bash
# tmux-dev 피커 공용 (bash). prefix S(libexec/tmux-dev-project)와 prefix W(libexec/tmux-dev-worktree)가 source 한다.
# common.sh, dirs.sh, layout.sh 를 먼저 source 해야 한다 (색, die, scan_dirs, dir_preview, choose_layout 를 쓴다).
#
# 피커는 fzf 하나이고, fzf 가 이벤트마다 같은 스크립트를 다시 부른다(콜백. 액션 한 줄을 출력한다). 그래서 이 lib 는
#   - 콜백끼리 상태를 주고받는 상태 디렉토리 (st_*)
#   - 액션 문자열을 안전하게 만드는 도구 (act, nope, search_action)
#   - 경로 판정 (classify, name_ok)과 기록 파일 (hist_*)
#   - 화면 모양 (picker_tabs, style_opts: tmux 의 떠 있는 창 테두리와 같은 fzf 테두리)
#   - 겹쳐 뜨는 두 목록: 위치 피커(choose_location_step, alt-enter 로 새로 만들 때)와 레이아웃 목록(choose_layout_step)
# 을 둔다. 겹쳐 뜨는 목록의 콜백은 부른 쪽 스크립트($SELF)의 인자 처리로 돌아온다. 그래서 그 스크립트는 다음을 이 lib 의
# 함수로 넘겨야 한다:
#   --on loc-enter <경로> → on_loc_enter   --on loc-layout <경로> → on_loc_layout   --on loc-after-layout → on_loc_after_layout
#   --choose-layout → choose_layout_step   --choose-location → choose_location_step   --loc-preview <경로> → loc_preview
#   --layout-art <이름> → layout_art (lib/layout.sh)
# 상태 키 (부른 쪽과 공유): mode, name, near, loc, pending, near_pick, layout. 모드가 repo 면 새로 만드는 것이 저장소다.
# 설계와 판단 근거: 저장소의 docs/tmux-dev/design/session-picker.md (구현 구조 절)

# shellcheck disable=SC2034  # 부른 쪽 스크립트가 쓴다
US=$'\x1f'         # tmux·git 포맷 출력의 칸 구분자 (빈 칸이 있을 수 있다)
: "${RECENT_MAX:=20}"
TMUX_DEV_PARENTS="${TMUX_DEV_PARENTS:-${TMUX_DEV_HISTORY%/*}/parents}"   # 위치 피커로 무언가를 만든 부모 디렉토리 (최근 순)

# --- 작은 도구 -------------------------------------------------------------------
# fzf 액션 한 개. 인자에 괄호가 있어도 깨지지 않게, 인자에 없는 구분 기호 쌍을 고른다 (man fzf: ACTION ARGUMENT)
act() {
  local name=$1 text=$2 pair
  for pair in '()' '[]' '{}' '<>' '~~' '!!' '@@' '##' '%%' '^^' '&&' '**' ';;' '||'; do
    case $text in *"${pair:0:1}"*|*"${pair:1:1}"*) continue ;; esac
    printf '%s%s%s%s' "$name" "${pair:0:1}" "$text" "${pair:1:1}"; return
  done
  printf '%s:%s' "$name" "$text"   # 마지막 수단. 액션 줄의 맨 끝에만 써야 한다
}
home_disp() { case $1 in "$HOME") printf '~' ;; "$HOME"/*) printf '~%s' "${1#"$HOME"}" ;; *) printf '%s' "$1" ;; esac; }
# 경로 모양 검색어: / 나 ~/ 로 시작하거나 ~ 하나
pathish() { case ${1:-} in /*|'~'|'~/'*) return 0 ;; *) return 1 ;; esac; }
# ~ 를 풀고 . .. // 끝 슬래시를 글자로만 정리한다 (파일시스템을 보지 않는다). 절대 경로가 아니면 1
norm_path() {
  local p=$1 seg out=""
  case $p in '~') p=$HOME ;; '~/'*) p=$HOME/${p#'~/'} ;; esac
  [[ $p = /* ]] || return 1
  local -a parts=()
  local IFS=/
  for seg in $p; do
    case $seg in ''|.) ;; ..) [ ${#parts[@]} -gt 0 ] && unset "parts[$((${#parts[@]} - 1))]" ;; *) parts+=("$seg") ;; esac
  done
  for seg in "${parts[@]+"${parts[@]}"}"; do out+="/$seg"; done
  printf '%s' "${out:-/}"
}
canon_dir() { (cd "$1" 2>/dev/null && pwd -P); }
# 워크트리의 메인 체크아웃. .git 파일의 "gitdir: <메인>/.git/worktrees/<이름>" 에서 역산한다 (git 프로세스 없음)
worktree_main() {
  local g=$1/.git line
  [ -f "$g" ] || return 0
  IFS= read -r line < "$g" || return 0
  g=${line#gitdir: }; [[ $g = /* ]] || g=$1/$g
  case $g in */.git/worktrees/*) g=${g%/.git/worktrees/*}; [ -d "$g/.git" ] && printf '%s' "$g" ;; esac
  return 0
}

# --- 상태 (피커 하나당 디렉토리 하나) ----------------------------------------------
# fzf 가 띄우는 콜백은 매번 새 프로세스라 상태를 파일로 주고받는다. 경로는 환경변수로 물려받는다.
# 읽기·쓰기는 bash 내장(read, printf 리다이렉션)이라 프로세스를 더 띄우지 않는다.
st_get() { ST=""; [ -f "${TMUX_DEV_STATE:-/nonexistent}/$1" ] && IFS= read -r ST < "$TMUX_DEV_STATE/$1" || true; }
st_set() { printf '%s\n' "$2" > "$TMUX_DEV_STATE/$1"; }
st_del() { local k; for k in "$@"; do rm -f "$TMUX_DEV_STATE/$k"; done; }
picker_state_init() {  # $1 이름 → TMUX_DEV_STATE 를 만들고 내보내며, 끝날 때 지운다. 비정상 종료 흔적은 1시간 뒤 치운다
  TMUX_DEV_STATE=$(mktemp -d "${TMPDIR:-/tmp}/$1.XXXXXX"); export TMUX_DEV_STATE
  # shellcheck disable=SC2064  # 지금 값의 디렉토리를 지운다
  trap "rm -rf '$TMUX_DEV_STATE'" EXIT
  find "${TMPDIR:-/tmp}" -maxdepth 1 -name "$1.*" -type d -mmin +60 -exec rm -rf {} + 2>/dev/null || true
}

# --- 기록 파일 ("<epoch>\t<경로>" 한 줄씩, 뒤가 최근) ------------------------------------
# 옛 형식(경로만)도 읽는다. 쓸 때는 같은 경로를 지우고 맨 뒤에 붙인 뒤 상한만 남긴다.
hist_paths() {  # $1 파일 → 최근 순, 중복 없이
  [ -f "$1" ] || return 0
  { tail -r "$1" 2>/dev/null || tac "$1"; } | awk -F'\t' '{ p = NF > 1 ? $2 : $1; if (p != "" && !seen[p]++) print p }'
}
hist_record() {  # $1 파일 $2 경로 $3 상한(줄)
  mkdir -p "$(dirname "$1")"
  local tmp; tmp=$(mktemp "$1.XXXXXX")
  { [ -f "$1" ] && awk -F'\t' -v p="$2" '{ q = NF > 1 ? $2 : $1; if (q != p) print (NF > 1 ? $0 : "0\t" $1) }' "$1"
    printf '%s\t%s\n' "$(date +%s)" "$2"; } | tail -n "$3" > "$tmp" && mv -f "$tmp" "$1"
}

# --- 행 ------------------------------------------------------------------------
# 행: "<~경로>\t<표시>\t<실제 경로>". fzf 는 1·2칸을 보여 주고(--with-nth 1,2) 1칸(경로)만 검색한다(--nth 1).
# 표시를 경로 뒤에 두어야 경로 접두 일치(^~/...)가 맞는다.
row() { printf '%s\t%s\t%s\n' "$(home_disp "$1")" "$2" "$1"; }
dir_rows() {  # SCAN_ROOT 아래 디렉토리 전부를 행으로 (표시 없음. 수만 개라 행마다 프로세스를 띄우지 않는다)
  scan_dirs | awk -v home="$HOME" -v OFS='\t' '{ d = $0; if (index(d, home "/") == 1) d = "~" substr(d, length(home) + 1); else if (d == home) d = "~"; print d, "", $0 }'
}

# --- 판정: 경로 모양 검색어 ----------------------------------------------------------
# 결과: J_KIND (block | open | worktree | create), J_PATH (실제 경로, create 면 만들 경로), J_CREATE (dir | repo),
#       J_SAY (푸터에 보여 줄 판정). 있는 디렉토리는 목록에 있었든 없었든 묻지 않고 연다(생성이 아니므로).
classify() {  # $1 경로 글자 $2 모드
  local p a rest="" top d extra=""
  J_KIND=block J_PATH="" J_CREATE="" J_SAY=""
  p=$(norm_path "$1") || { J_SAY="${Y}not an absolute path${R}"; return; }
  d=$(home_disp "$p")
  if [ -e "$p" ] && [ ! -d "$p" ]; then J_SAY="${Y}a file already exists: $d${R}"; return; fi
  if [ -d "$p" ]; then
    J_PATH=$(canon_dir "$p"); d=$(home_disp "$J_PATH")
    if [ -f "$J_PATH/.git" ]; then J_KIND=worktree; J_SAY="enter go to worktree: $d"
    else
      J_KIND=open; J_SAY="enter open: $d"
      [ "$2" = repo ] && [ ! -d "$J_PATH/.git" ] && J_SAY+=" ${D}(not a repository; no git init)${R}"
    fi
    return
  fi
  a=$p; while [ ! -e "$a" ]; do rest="/$(basename "$a")$rest"; a=$(dirname "$a"); done   # 있는 가장 가까운 조상
  [ -d "$a" ] || { J_SAY="${Y}a parent is a file: $(home_disp "$a")${R}"; return; }
  [ -w "$a" ] || { J_SAY="${Y}not writable: $(home_disp "$a")${R}"; return; }
  [ "$rest" = "/$(basename "$p")" ] || extra=" · with missing parents"
  top=$(git -C "$a" rev-parse --show-toplevel 2>/dev/null || true)
  a=$(canon_dir "$a"); [ "$a" = / ] && a=""; J_PATH=$a$rest; d=$(home_disp "$J_PATH")
  J_KIND=create
  if [ "$2" = repo ]; then
    J_CREATE=repo; extra=" (git init)$extra"
    [ -n "$top" ] && extra+=" · ${Y}inside repository $(home_disp "$top")${R}"
  else J_CREATE=dir; fi
  J_SAY="${D}does not exist${R} · alt-enter create: $d$extra"
}
# 새로 만들 이름 (경로 모양이 아닌 검색어). 위치 피커에서 고른 디렉토리 아래에 붙는다. a/b 처럼 / 를 넣어도 된다
name_ok() {
  local n=${1%/}
  case $n in ''|/*|'~'*) return 1 ;; esac
  case "/$n/" in */../*|*/./*|*//*) return 1 ;; esac
  return 0
}

# --- 화면 ------------------------------------------------------------------------
# 맨 위 헤더(--header-first)에 그리는 모드 탭. $1 지금 모드, 나머지는 모드 목록. 이름은 부른 쪽의 mode_name 이 정한다.
# 지금 모드는 굵게. 클릭하면 그 모드로 간다(click-header 의 FZF_CLICK_HEADER_WORD 를 mode_name 과 비교).
# 이름 사이는 탭 문자다: fzf 는 클릭한 단어를 --delimiter 로 자르는데, 행 칸 구분 때문에 --delimiter '\t' 라서
# 공백으로 띄우면 탭 이름들이 한 단어로 온다. 화면에는 --tabstop 2 로 두 칸 간격이다.
# 탭 이름은 영어다: fzf 의 클릭 단어 계산이 한글 같은 여러 바이트 글자 뒤에서 어긋난다 (session-picker.md 화면 절).
picker_tabs() {
  local cur=$1 m out=""; shift
  for m in "$@"; do
    if [ "$m" = "$cur" ]; then out+="${B}$(mode_name "$m")${R}"$'\t'; else out+="${D}$(mode_name "$m")${R}"$'\t'; fi
  done
  printf '%s' "${out%$'\t'}"
}
# tmux 의 떠 있는 창 테두리와 같은 모양으로 그린다 (피커 창은 테두리 없이 띄운다). 런타임에 읽어 tmux.conf 를 따라간다.
# 읽는 곳: @float-border-lines·@float-border-style (tmux.conf 가 팝업과 floating pane 공용으로 둔다), 없으면 popup-border-*.
# popup-* 옵션은 tmux 3.9 에서 없어진다.
float_opt() { local v; v=$(tmux show -gqv "@float-$1" 2>/dev/null); [ -n "$v" ] || v=$(tmux show -gqv "popup-$1" 2>/dev/null); printf '%s' "$v"; }
float_border() {
  BORDER=rounded BCOLOR=""
  [ -n "${TMUX:-}" ] || return 0
  case $(float_opt border-lines) in
    rounded) BORDER=rounded ;; double) BORDER=double ;; heavy) BORDER=bold ;; *) BORDER=sharp ;;
  esac
  local fg; fg=$(float_opt border-style | sed -n 's/.*fg=\([^,]*\).*/\1/p')
  case $fg in   # fzf 가 모르는 색 이름을 넘기면 fzf 가 뜨지 않으므로 아는 꼴만 넘긴다
    colour[0-9]*|color[0-9]*) BCOLOR=${fg#colo*r} ;;
    '#'[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]|[0-9]|[0-9][0-9]|[0-9][0-9][0-9]) BCOLOR=$fg ;;
    black|red|green|yellow|blue|magenta|cyan|white) BCOLOR=$fg ;;
  esac
}
style_opts() {  # STYLE 배열: 피커와 겹쳐 뜨는 목록(위치, 레이아웃)이 같이 쓴다
  float_border
  STYLE=(--border "$BORDER" --border-label-pos 3 --input-border "$BORDER" --list-border "$BORDER" --reverse --height=100%)
  [ -n "$BCOLOR" ] && STYLE+=(--color "border:$BCOLOR,label:$BCOLOR")
  return 0
}

# --- 콜백 도구 -------------------------------------------------------------------
nope() { printf 'bell+%s' "$(act change-footer "$1")"; }   # 할 일이 없을 때: 벨과 안내만
search_action() {  # 경로 모양 검색어 → 경로 접두 일치. /Users/<나>/... 도 ~/... 로 맞춘다. 공백은 fzf 검색 문법대로 \ 로
  local q=$1
  case $q in "$HOME") q='~' ;; "$HOME"/*) q="~${q#"$HOME"}" ;; esac
  q=${q// /\\ }
  printf 'search:^%s' "$q"    # search: 꼴은 액션 줄의 맨 끝이어야 한다
}

# --- 레이아웃 목록 (alt-l 로 겹쳐 뜬다) ----------------------------------------------
choose_layout_step() {  # execute 안에서 돈다. 고른 것을 상태에 쓴다. esc·ctrl-c 면 아무것도 안 쓴다
  local create path can="" picked
  st_get pending; IFS=$'\t' read -r create path <<< "$ST"
  { [ -d "$path/.git" ] || [ "$create" = repo ]; } && can=save
  style_opts
  # shellcheck disable=SC2034  # choose_layout(lib/layout.sh)이 읽는다
  LAYOUT_ESC=abort
  # shellcheck disable=SC2034
  LAYOUT_FZF_OPTS=("${STYLE[@]}" --border-label " layout · $(home_disp "$path") ")
  picked=$(choose_layout "$SELF --layout-art" "$can") || return 0
  st_set layout "$picked"
}

# --- 위치 피커 (alt-enter 로 겹쳐 뜬다) ------------------------------------------------
# 행은 메인 목록과 같은 꼴. 최근에 무언가를 만든 부모(◷) → 커서 항목의 부모(↳) → 디렉토리 탐색(SCAN_ROOT 아래).
# LOC_ROOT 가 있으면 최근 부모·커서 옆도 그 아래만 (prefix W 의 subdirectory 모드). 없으면 제한 없음 (prefix S).
under_loc_root() { [ -z "${LOC_ROOT:-}" ] && return 0; case $1 in "$LOC_ROOT"|"$LOC_ROOT"/*) return 0 ;; *) return 1 ;; esac; }
loc_rows() {
  {
    local p n=0
    while IFS= read -r p; do [ "$n" -lt "$RECENT_MAX" ] || break; [ -d "$p" ] && under_loc_root "$p" || continue; row "$p" "${D}◷${R}"; n=$((n + 1)); done < <(hist_paths "$TMUX_DEV_PARENTS")
    st_get near; [ -n "$ST" ] && [ -d "$ST" ] && under_loc_root "$ST" && row "$ST" "${D}↳ next to the item${R}"
    [ -n "${LOC_ROOT:-}" ] && row "$LOC_ROOT" "${D}⌂ session directory${R}"   # 탐색은 그 아래만 나오므로 시작점 자체를 넣는다
    dir_rows
  } | awk -F'\t' '!seen[$3]++ { print; fflush() }'
}
loc_preview() {  # $1 고를 부모 → 만들어질 경로와 판정, 그 아래 부모의 내용
  local mode name; st_get name; name=$ST; st_get mode; mode=${ST:-repo}
  [ -d "${1:-}" ] || return 0
  classify "$1/$name" "$mode"
  case $J_KIND in
    create)  printf '%swill create%s  %s\n' "$B" "$R" "$(home_disp "$J_PATH")"; printf '%s\n' "${J_SAY#*: }" | sed 's/^[^ ]* *//' ;;
    open|worktree) printf '%salready exists%s  %s  %s(enter opens it)%s\n' "$Y" "$R" "$(home_disp "$J_PATH")" "$D" "$R" ;;
    *) printf '%s\n' "$J_SAY" ;;
  esac
  echo; dir_preview "$1"
}
on_loc_enter() {  # 위치 피커의 enter: 만들 수 있으면(또는 이미 있으면) 고르고 끝, 막히면 안내
  local mode name; st_get name; name=$ST; st_get mode; mode=${ST:-repo}
  [ -n "${1:-}" ] || { printf 'bell'; return; }
  classify "$1/$name" "$mode"
  [ "$J_KIND" = block ] && { nope "$J_SAY"; return; }
  st_set loc "$1"; printf 'accept'
}
on_loc_layout() {  # 위치 피커의 alt-l: 레이아웃을 겹쳐 띄우고, 고르면 위치도 고른 것으로 끝낸다
  local mode name; st_get name; name=$ST; st_get mode; mode=${ST:-repo}
  [ -n "${1:-}" ] || { printf 'bell'; return; }
  classify "$1/$name" "$mode"
  [ "$J_KIND" = block ] && { nope "$J_SAY"; return; }
  st_set pending "${J_CREATE:-none}"$'\t'"$J_PATH"; st_set near_pick "$1"; st_del layout
  printf 'execute(%s --choose-layout)+transform(%s --on loc-after-layout)' "$SELF" "$SELF"
}
on_loc_after_layout() {  # 레이아웃에서 esc 면 위치 피커에 그대로 남는다
  st_get layout; [ -n "$ST" ] || return 0
  st_get near_pick; st_set loc "$ST"; printf 'accept'
}
choose_location_step() {  # execute 안에서 돈다. 고른 부모는 상태 loc 에 남는다 (esc 면 남기지 않는다)
  local name what="directory"; st_get name; name=$ST; st_get mode; [ "${ST:-repo}" = repo ] && what="repository"
  style_opts
  fzf --ansi --delimiter '\t' --with-nth 1,2 --nth 1 --tabstop 2 --scheme path --tiebreak pathname,index \
      "${STYLE[@]}" --border-label " new $what '$name': where? " --prompt 'location> ' \
      --footer "${D}enter create here · alt-l create with a layout · esc back${R}" --footer-border line \
      --preview "$SELF --loc-preview {3}" --preview-window 'right,45%,border-left' \
      --bind 'change:first' --bind 'esc:abort' \
      --bind "enter:transform($SELF --on loc-enter {3})" \
      --bind "double-click:transform($SELF --on loc-enter {3})" \
      --bind "alt-l:transform($SELF --on loc-layout {3})" \
      --bind 'alt-p:change-preview-window(down,40%,border-top|hidden|right,45%,border-left)' \
      < <(loc_rows) > /dev/null || true
}
