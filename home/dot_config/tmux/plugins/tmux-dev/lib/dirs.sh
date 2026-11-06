# 디렉토리 검색과 미리보기. tmux-dev project 의 dir 모드(prefix S → 세션)와 tmux-dev worktree 의 dir 모드
# (prefix W → 지금 세션의 윈도우)가 함께 source 한다. 같은 검색 범위를 쓰고, 다른 것은 "무엇을 여나" 뿐이다. bash 용.
#
# 검색 범위는 목록 파일($TMUX_DEV_CONFIG, ~/.config/tmux-dev/projects)의 두 줄로 정한다. 없으면 기본값.
#   search <경로>:<깊이>   뒤질 범위. 여러 줄 가능 (기본 ~:4)
#   exclude <이름>...      건너뛸 디렉토리 이름 (기본 .git node_modules Library .Trash .cache)

DEFAULT_SEARCH="$HOME:4"
DEFAULT_EXCLUDES=".git node_modules Library .Trash .cache"

config_lines() {  # 목록 파일에서 주석·빈 줄을 뺀 줄
  [ -f "$TMUX_DEV_CONFIG" ] || return 0
  sed -e 's/[[:space:]]*#.*$//' -e '/^[[:space:]]*$/d' "$TMUX_DEV_CONFIG"
}
config_search()   { local s; s=$(config_lines | sed -n 's/^search[[:space:]]\{1,\}//p'); printf '%s\n' "${s:-$DEFAULT_SEARCH}"; }
config_excludes() { local e; e=$(config_lines | sed -n 's/^exclude[[:space:]]\{1,\}//p' | tr '\n' ' '); printf '%s\n' "${e:-$DEFAULT_EXCLUDES}"; }

# 검색 범위의 디렉토리를 "<~경로><TAB><절대경로>" 로. fd 로 평탄하게 뒤진다 (없으면 find). 후보가 많아 git 조회는 하지 않는다.
list_dirs() {
  local entry root depth ex p args=()
  for ex in $(config_excludes); do args+=(--exclude "$ex"); done
  while IFS= read -r entry; do
    root=$(expand_tilde "${entry%:*}"); depth=${entry##*:}
    [ -d "$root" ] || continue
    if command -v fd >/dev/null; then
      fd --type d --hidden --max-depth "$depth" "${args[@]+"${args[@]}"}" --absolute-path . "$root" 2>/dev/null
    else
      find "$root" -mindepth 1 -maxdepth "$depth" -type d 2>/dev/null
    fi
  done < <(config_search) | sed 's|/$||' | while IFS= read -r p; do [ -n "$p" ] && printf '%s\t%s\n' "$(abbrev_home "$p")" "$p"; done
}

# git 브랜치 이름. 후보마다 git 을 띄우면 팝업이 느려지므로 .git/HEAD 를 직접 읽는다.
# 저장소가 아니면 빈 문자열, detached 면 짧은 해시.
git_branch() {
  local g=$1/.git line
  [ -e "$g" ] || return 0
  if [ -f "$g" ]; then                       # worktree: "gitdir: <경로>"
    IFS= read -r line < "$g" || return 0
    g=${line#gitdir: }
    [[ $g = /* ]] || g=$1/$g
  fi
  [ -f "$g/HEAD" ] || return 0
  IFS= read -r line < "$g/HEAD" || return 0
  case $line in
    "ref: refs/heads/"*) printf '%s' "${line#ref: refs/heads/}" ;;
    "ref: "*)            printf '%s' "${line#ref: }" ;;
    *)                   printf '%s' "${line:0:7}" ;;
  esac
}

dir_preview() {  # 저장소면 브랜치와 최근 커밋, 그리고 내용
  local d=$1
  [ -d "$d" ] || return 0
  if [ -e "$d/.git" ]; then
    printf '%s%s%s\n\n' "$B" "$(git_branch "$d")" "$R"
    git -C "$d" log --oneline --color=always -8 2>/dev/null; echo
  fi
  ls -1Ap "$d" 2>/dev/null | head -40
}

# 친 글자를 디렉토리로: ~ 를 풀고, 상대 경로는 지금 디렉토리 기준(팝업은 패널의 디렉토리에서 열린다, display-popup -d).
# 없으면 만들지 묻는다. 결과는 출력. 취소면 1.
query_dir() {
  local t; t=$(expand_tilde "$1")
  [ -n "$t" ] || return 1
  [[ $t = /* ]] || t=$PWD/$t
  if [ ! -d "$t" ]; then
    printf '%s 가 없습니다. 만들까요? [y/N] ' "$(abbrev_home "$t")" >&2
    local ans; IFS= read -r ans || return 1
    case $ans in y|Y) mkdir -p "$t" ;; *) return 1 ;; esac
  fi
  (cd "$t" && pwd)
}
