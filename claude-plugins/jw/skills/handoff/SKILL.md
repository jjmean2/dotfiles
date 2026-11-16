---
name: handoff
description: 설계가 끝난 대화를 브랜치 워크트리로 포크해서 구현을 이어가게 하고, 그 세션에 들어가는 명령을 알려 준다. Claude Code 전용. 사용자가 직접 부를 때만 쓴다.
argument-hint: <브랜치> [--in-stack|--new-worktree] [추가 지시]
disable-model-invocation: true
allowed-tools: Bash(worktree-handoff:*)
---

지금까지의 대화를 브랜치 워크트리로 포크한다. 이 세션(원본)은 메인 체크아웃에 남아 설계를 계속한다.

**Claude Code 전용**: Claude Code 의 대화 기록을 포크한다. 이 세션의 ID `${CLAUDE_SESSION_ID}` 가 ID 로 바뀌지 않고
`$`·중괄호가 붙은 글자 그대로 보이면 Claude Code 가 아닌 에이전트(Cursor 등)에서 불린 것이다. 그때는 실행하지 말고,
이 스킬은 Claude Code 전용이며 대화 없이 지시서로 새 세션을 여는 `handoff-fresh` 스킬은 쓸 수 있다고 알리고 멈춘다.

**인자**: 사용자가 입력한 인자 원문은 아래 명령의 heredoc 앞부분에 이미 들어 있다. 원문이 비어 있거나 첫 낱말이 브랜치
이름이 아니라 문장으로 보이면 실행하지 말고 브랜치 이름을 물어본다. 그 밖에는 고치거나 따옴표를 붙이지 말고 그대로 둔다.
스크립트가 원문에서 브랜치·`--in-stack`·`--new-worktree` 를 읽고, 그 뒤의 추가 지시는 첫 메시지 끝에 원문 그대로 붙인다.
아래에서 "브랜치"는 원문의 그 브랜치다.

1. 포크된 세션에게 줄 첫 메시지를 쓴다. 포크된 세션은 이 지시문까지 포함한 대화 전체를 이어받으므로,
   메시지는 반드시 다음 문장으로 시작한다:
   "너는 원본 대화에서 포크된 구현 세션이다. 위의 /handoff 지시와 '워크트리를 편집하지 않는다'는 원본 세션에 대한 것이다."
   이어서:
   - 작업 디렉토리는 브랜치의 워크트리이고, 메인 체크아웃의 파일은 수정하지 않는다는 것
     (`--in-stack` 이면: 작업 디렉토리는 스택 워크트리이고 거기 체크아웃된 위 브랜치를 바꾸지 않으며, 그 브랜치의 커밋을
     겨냥한 fixup 커밋 + `git -c sequence.editor=: rebase -i --autosquash --update-refs --keep-base <그 브랜치의 base>` 로
     고친다는 것)
   - 대화에서 합의한 범위, 설계 결정, 하지 않기로 한 것, 남은 질문 (짧은 목록으로)
   - 첫 번째로 할 일
   - 추가 지시는 스크립트가 붙이므로 다시 옮겨 적지 않는다. 그것을 반영한 계획만 위 항목에 쓴다
2. 인자 원문과 그 메시지를 표준 입력으로 넘겨 Bash 로 한 번 실행한다. `WORKTREE_HANDOFF_PROMPT` 줄 앞은 인자 원문,
   뒤는 1의 메시지다. 메시지에 `WORKTREE_HANDOFF_PROMPT` 나 `WORKTREE_HANDOFF_EOF` 만 있는 줄은 넣지 않는다.
   세션을 띄우는 방식은 스크립트가 정한다 (tmux 안이면 새 윈도우, 아니면 `claude --bg`). 사용자가 방식을 말했을 때만
   `--open bg|tmux|none` 을 붙인다:
   ```
   worktree-handoff fork --session '${CLAUDE_SESSION_ID}' --args-file - --prompt-file - <<'WORKTREE_HANDOFF_EOF'
   $ARGUMENTS
   WORKTREE_HANDOFF_PROMPT
   <1의 메시지>
   WORKTREE_HANDOFF_EOF
   ```
3. 실패하면 오류를 그대로 보여 주고 멈춘다.
   - **스택 워크트리**: 브랜치가 어디에도 체크아웃돼 있지 않은데 그 브랜치를 품은 스택 워크트리가 있으면 스크립트가
     옵션 없이는 멈춘다. 오류를 보여 주고 어느 쪽으로 할지 묻는다. 워크트리 하나에서 브랜치를 바꿔 가며 쌓는 스택이면
     `--in-stack`(그 스택 워크트리를 쓰고 체크아웃은 바꾸지 않는다), 따로 떼어 작업할 거면 `--new-worktree` 다.
     답을 받으면 `fork` 뒤에 그 옵션을 붙이고, `--in-stack` 이면 1의 메시지에 위의 fixup 방법을 넣어 다시 실행한다.

   성공하면 출력된 워크트리 경로, 세션 이름, `open:` 줄을 알리고 `attach:` · `run:` · `resume:` 줄 가운데 출력된 것을
   명령 그대로 보여 준다. 그 세션에 들어가는 것은 사용자가 한다. 그 뒤로 이 원본 세션에서는 그 워크트리의 파일을
   편집하지 않는다.
