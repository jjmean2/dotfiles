#!/bin/bash
# Claude Code 상태 줄. zsh/bash 프롬프트와 같은 모양의 경로(밑줄 cyan, 마지막 4단계)와
# "(브랜치 ⇡앞섬 ⇣뒤처짐 ✗/✓)" git 상태에, 모델·effort 와 컨텍스트 사용량을 붙인다.
# PR 은 Claude Code 의 footer 배지가 이미 보여 주므로 넣지 않는다.
#
# 켜기: ~/.claude/settings.json 에
#   "statusLine": {"type": "command", "command": "bash \"$HOME/.claude/statusline-command.sh\""}
# 입력: stdin 의 세션 JSON (https://code.claude.com/docs/en/statusline). jq 가 필요하다.

input=$(cat)

# Orca 의 statusline 연동을 살려 둔다 (rate-limit 정보를 넘기기만 하고 출력은 없다).
orca="$HOME/.orca/agent-hooks/claude-statusline.sh"
if [ -f "$orca" ] && [ -r "$orca" ] && [ -x "$orca" ]; then
  printf '%s' "$input" | /bin/sh "$orca" >/dev/null 2>&1 || true
fi

# 필드는 jq 한 번으로 읽는다. 구분자는 공백이 아닌 \x1f 라서 빈 필드가 앞으로 당겨지지 않는다.
US=$'\x1f'
IFS=$US read -r cwd model effort ctx < <(
  printf '%s' "$input" | jq -r --arg us "$US" '[
    (.workspace.current_dir // .cwd // ""),
    (.model.display_name // ""),
    (.effort.level // ""),
    (.context_window.used_percentage | if . == null then "" else floor end)
  ] | map(tostring) | join($us)' 2>/dev/null
)
[ -z "$cwd" ] && cwd=$PWD

ESC=$'\033'
R="${ESC}[0m"
DIM="${ESC}[2m"
SEP="${DIM} · ${R}"

# 경로: ~ 로 줄이고 마지막 $1 단계만 남긴다 (PROMPT_DIRTRIM 과 같은 동작).
path_disp() {
  local keep=$1 disp=$cwd n i out
  case "$cwd" in
    "$HOME") disp="~" ;;
    "$HOME"/*) disp="~/${cwd#"$HOME"/}" ;;
  esac
  local -a parts
  IFS='/' read -r -a parts <<<"${disp#/}"
  n=${#parts[@]}
  if [ "$n" -gt "$keep" ]; then
    out="..."
    for ((i = n - keep; i < n; i++)); do out+="/${parts[i]}"; done
    disp=$out
  fi
  printf '%s' "$disp"
}

# user@host 는 SSH 접속일 때만
host=""
if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
  host="${ESC}[32m$(whoami)${ESC}[35m@$(hostname -s)${R} "
fi

# git 상태 (한 번 호출, optional lock 없이)
branch="" oid="" ahead="" behind="" staged=0 unstaged=0
while IFS= read -r line; do
  [ -z "$line" ] && continue
  case "$line" in
    "# branch.head "*) branch=${line#\# branch.head } ;;
    "# branch.oid "*) oid=${line#\# branch.oid } ;;
    "# branch.ab "*)
      ab=${line#\# branch.ab +}
      a=${ab%% *}
      b=${ab#* -}
      [ "$a" -gt 0 ] 2>/dev/null && ahead=$a
      [ "$b" -gt 0 ] 2>/dev/null && behind=$b
      ;;
    "#"*) ;;
    "?"*|"u"*) unstaged=1; break ;;
    "1"*|"2"*)
      x=${line:2:1}
      y=${line:3:1}
      if [ "$y" != "." ]; then unstaged=1; break; fi
      [ "$x" != "." ] && staged=1
      ;;
  esac
done < <(git -C "$cwd" --no-optional-locks status --porcelain=v2 --branch 2>/dev/null)

git_seg=""
if [ -n "$branch" ]; then
  bcolor="${ESC}[33m"
  if [ "$branch" = "(detached)" ]; then
    branch=${oid:0:7}
    bcolor="${ESC}[35m"
  fi
  git_seg=" ${ESC}[1m${ESC}[36m(${R}${ESC}[1m${bcolor}${branch}${R}"
  [ -n "$ahead$behind" ] && git_seg+=" "
  [ -n "$ahead" ] && git_seg+="${ESC}[1m${ESC}[32m⇡${ahead}${R}"
  [ -n "$behind" ] && git_seg+="${ESC}[1m${ESC}[31m⇣${behind}${R}"
  if [ "$unstaged" -eq 1 ]; then
    git_seg+=" ${ESC}[1m${ESC}[31m✗${R}"
  elif [ "$staged" -eq 1 ]; then
    git_seg+=" ${ESC}[1m${ESC}[32m✓${R}"
  fi
  git_seg+="${ESC}[1m${ESC}[36m)${R}"
fi

# 컨텍스트 사용량: 60% 부터 노랑, 80% 부터 빨강. 첫 응답 전(null)에는 숨긴다.
ctx_seg=""
if [ -n "$ctx" ]; then
  if [ "$ctx" -ge 80 ]; then c="${ESC}[1m${ESC}[31m"
  elif [ "$ctx" -ge 60 ]; then c="${ESC}[33m"
  else c="${DIM}"
  fi
  ctx_seg="${c}ctx ${ctx}%${R}"
fi

# 보이는 너비 (ANSI 를 빼고 UTF-8 글자 수로 센다)
vis_len() {
  local s LC_ALL=en_US.UTF-8
  s=$(printf '%s' "$1" | sed $'s/\033\\[[0-9;]*m//g')
  printf '%s' "${#s}"
}

# 줄은 둘이다. 첫 줄은 경로·git, 둘째 줄은 모델·effort·컨텍스트.
# 줄마다 따로 너비를 맞춘다. COLUMNS 를 모르면 줄이지 않는다.
# footer 의 내장 들여쓰기 몫으로 4칸을 남긴다.
max=$(( ${COLUMNS:-0} - 4 ))
fits() { [ "${COLUMNS:-0}" -le 0 ] || [ "$(vis_len "$1")" -le "$max" ]; }

line1() { # $1: 경로 단계 수
  printf '%s' "${host}${ESC}[36m${ESC}[4m$(path_disp "$1")${R}${git_seg}"
}

line2() { # $1: 모델 넣기(1/0), $2: effort 넣기(1/0)
  # 모델·effort: "Opus 5.5·medium". effort 는 입력창 위에도 보이지만 모델과 한 묶음으로 둔다.
  local s=""
  if [ "$1" = 1 ] && [ -n "$model" ]; then
    s="${ESC}[35m${model}${R}"
    [ "$2" = 1 ] && [ -n "$effort" ] && s+="${DIM}·${R}${ESC}[35m${effort}${R}"
  fi
  if [ -n "$ctx_seg" ]; then
    [ -n "$s" ] && s+="$SEP"
    s+="$ctx_seg"
  fi
  printf '%s' "$s"
}

# 첫 줄: 경로를 4 → 2 → 1 단계로 줄인다.
for keep in 4 2 1; do
  out1=$(line1 "$keep")
  fits "$out1" && break
done

# 둘째 줄: effort → 모델 순으로 뺀다.
for try in "1 1" "1 0" "0 0"; do
  out2=$(line2 $try)
  fits "$out2" && break
done

if [ -n "$out2" ]; then
  printf '%s\n%s' "$out1" "$out2"
else
  printf '%s' "$out1"
fi
