# 디렉토리 탐색과 미리보기. tmux-dev project(prefix S → 세션)와 tmux-dev worktree 의 dir 모드
# (prefix W → 지금 세션의 윈도우)가 함께 source 한다. 같은 탐색을 쓰고, 다른 것은 "무엇을 여나" 뿐이다. bash 용.
#
# 탐색 범위는 미리 정하지 않는다. 시작점은 홈($TMUX_DEV_SCAN_ROOT, 기본 $HOME) 하나이고 깊이 제한이 없다.
# 빼는 것은 두 가지다.
#   - 숨김 디렉토리. 저장소 탐색은 .git 만 예외로 들어간다. 숨김 아래는 대부분 도구 캐시·데이터라
#     홈 전체가 13초 → 1.4초로 준다 (2026-11-07 실측, session-picker.md). 숨김 아래를 열려면 경로를 직접 친다.
#   - ignore 파일($TMUX_DEV_IGNORE, ~/.config/tmux-dev/ignore)의 패턴. gitignore 문법이고 fd --ignore-file 로
#     넘긴다. / 로 시작하는 패턴은 탐색 시작점(홈) 기준이다. 파일이 없으면 Library, node_modules 를 뺀다.
# 디렉토리 탐색은 .gitignore 도 따른다(빌드 산출물 등). 저장소 탐색은 따르지 않는다(무시된 곳의 저장소도 찾는다).

SCAN_ROOT=${TMUX_DEV_SCAN_ROOT:-$HOME}
FD=$(command -v fd || command -v fdfind || true)   # 데비안·우분투 패키지는 fdfind 이름으로 설치된다

ignore_args() {  # fd 에 넘길 제외 인자를 IGNORE_ARGS 배열에
  IGNORE_ARGS=()
  if [ -f "$TMUX_DEV_IGNORE" ]; then IGNORE_ARGS=(--ignore-file "$TMUX_DEV_IGNORE")
  else IGNORE_ARGS=(--exclude Library --exclude node_modules); fi
}
need_fd() { [ -n "$FD" ] || die "fd is required (brew install fd)"; }

# 저장소 = .git 이 디렉토리인 곳 (메인 체크아웃). .git 이 파일인 워크트리·서브모듈은 --type d 로 빠진다.
# 숨김 중 .git 만 들어가도록 .git 이 아닌 숨김 이름을 모두 뺀다. --prune 은 .git 안으로 내려가지 않게 한다.
scan_repos() {  # 한 줄에 절대 경로 하나. 찾는 대로 흘려 보낸다
  need_fd; ignore_args
  "$FD" --base-directory "$SCAN_ROOT" --absolute-path --type d --hidden --no-ignore --prune --glob .git \
    --exclude '.[!g]*' --exclude '.g[!i]*' --exclude '.gi[!t]*' --exclude '.git?*' "${IGNORE_ARGS[@]}" 2>/dev/null \
    | sed 's|/\.git/*$||'
}
scan_dirs() {   # 한 줄에 절대 경로 하나 (숨김 제외, .gitignore 존중)
  need_fd; ignore_args
  "$FD" --base-directory "$SCAN_ROOT" --absolute-path --type d "${IGNORE_ARGS[@]}" 2>/dev/null | sed 's|/$||'
}

# prefix W 의 dir 모드용: "<~경로><TAB><절대경로>". 후보가 많아(홈 전체 수만 개) git 조회는 하지 않는다.
list_dirs() {
  scan_dirs | awk -v home="$HOME" -v OFS='\t' '{ d = $0; if (index(d, home "/") == 1) d = "~" substr(d, length(home) + 1); else if (d == home) d = "~"; print d, $0 }'
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
