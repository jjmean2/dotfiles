#!/bin/bash
# Claude Code status line mirroring the zsh/bash prompt: cwd (underlined cyan, last 4 dirs)
# plus "(branch ⇡ahead ⇣behind ✗/✓)" git status.

input=$(cat)

# Preserve Orca's statusline integration (forwards rate-limit payload; prints nothing).
orca="$HOME/.orca/agent-hooks/claude-statusline.sh"
if [ -f "$orca" ] && [ -r "$orca" ] && [ -x "$orca" ]; then
  printf '%s' "$input" | /bin/sh "$orca" >/dev/null 2>&1 || true
fi

cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // empty')
[ -z "$cwd" ] && cwd=$PWD

# Path display with ~ and PROMPT_DIRTRIM=4 behavior
disp=$cwd
case "$cwd" in
  "$HOME") disp="~" ;;
  "$HOME"/*) disp="~/${cwd#"$HOME"/}" ;;
esac
IFS='/' read -r -a parts <<<"${disp#/}"
if [ "${#parts[@]}" -gt 4 ]; then
  n=${#parts[@]}
  disp=".../${parts[$((n-4))]}/${parts[$((n-3))]}/${parts[$((n-2))]}/${parts[$((n-1))]}"
fi

ESC=$'\033'
R="${ESC}[0m"
out=""

# user@host only over SSH
if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
  out+="${ESC}[32m$(whoami)${ESC}[35m@$(hostname -s)${R} "
fi

out+="${ESC}[36m${ESC}[4m${disp}${R}"

# Git status (single call, no optional locks)
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

if [ -n "$branch" ]; then
  bcolor="${ESC}[33m"
  if [ "$branch" = "(detached)" ]; then
    branch=${oid:0:7}
    bcolor="${ESC}[35m"
  fi
  out+=" ${ESC}[1m${ESC}[36m(${R}${ESC}[1m${bcolor}${branch}${R}"
  [ -n "$ahead$behind" ] && out+=" "
  [ -n "$ahead" ] && out+="${ESC}[1m${ESC}[32m⇡${ahead}${R}"
  [ -n "$behind" ] && out+="${ESC}[1m${ESC}[31m⇣${behind}${R}"
  if [ "$unstaged" -eq 1 ]; then
    out+=" ${ESC}[1m${ESC}[31m✗${R}"
  elif [ "$staged" -eq 1 ]; then
    out+=" ${ESC}[1m${ESC}[32m✓${R}"
  fi
  out+="${ESC}[1m${ESC}[36m)${R}"
fi

printf '%s' "$out"
