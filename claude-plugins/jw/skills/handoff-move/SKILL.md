---
name: handoff-move
description: 브랜치 워크트리를 만들고(있으면 그대로), 지금 세션을 그 워크트리로 옮기는 /cd 명령을 알려 준다. Claude Code 전용. 사용자가 직접 부를 때만 쓴다.
argument-hint: <브랜치> [--in-stack|--new-worktree]
disable-model-invocation: true
allowed-tools: Bash(worktree-handoff:*)
---

브랜치 워크트리를 확보하고, **이 세션 자체**를 그리로 옮기도록 안내한다. 포크도 새 세션도 만들지 않는다.

**Claude Code 전용**: 세션을 옮기는 `/cd` 는 Claude Code 의 명령이다. 이 스킬 디렉토리 `${CLAUDE_SKILL_DIR}` 가 경로로
바뀌지 않고 `$`·중괄호가 붙은 글자 그대로 보이면 Claude Code 가 아닌 에이전트(Cursor 등)에서 불린 것이다. 그때는 실행하지
말고, 이 스킬은 Claude Code 전용이라고 알리고 멈춘다.

**인자**: 사용자가 입력한 인자 원문은 아래 명령의 heredoc 안에 이미 들어 있다. 원문이 비어 있거나 첫 낱말이 브랜치 이름이
아니라 문장으로 보이면 실행하지 말고 브랜치 이름을 물어본다. 그 밖에는 고치거나 따옴표를 붙이지 말고 그대로 실행한다.
브랜치와 `--in-stack`·`--new-worktree` 는 스크립트가 읽는다.

1. Bash 로 한 번 실행한다:
   ```
   worktree-handoff path --args-file - <<'WORKTREE_HANDOFF_EOF'
   $ARGUMENTS
   WORKTREE_HANDOFF_EOF
   ```
2. 실패하면 오류를 그대로 보여 주고 멈춘다.
   - **스택 워크트리**: 브랜치가 어디에도 체크아웃돼 있지 않은데 그 브랜치를 품은 스택 워크트리가 있으면 스크립트가
     옵션 없이는 멈춘다. 오류를 보여 주고 어느 쪽으로 할지 묻는다. 워크트리 하나에서 브랜치를 바꿔 가며 쌓는 스택이면
     `--in-stack`(그 스택 워크트리를 쓰고 체크아웃은 바꾸지 않는다), 따로 떼어 작업할 거면 `--new-worktree` 다.
     답을 받으면 같은 명령의 `path` 뒤에 그 옵션을 붙여 다시 실행한다.

   성공하면 워크트리 경로를 알리고, 출력의 `move:` 줄(`/cd <경로>`, 따옴표 없음)을 그대로 보여 주며 사용자가 입력하도록
   안내한다. `/cd` 는 세션 기록·설정·스킬·CLAUDE.md 를 새 디렉토리로 옮긴다. `ignored:` 줄이 있으면 브랜치 뒤의 글을 쓰지
   않았다고 알린다.
   - `/cd` 는 사용자가 입력하는 명령이다. EnterWorktree 도구나 Bash 의 `cd` 로 대신하지 않는다.
   - 사용자가 옮기기 전에는 그 워크트리의 파일을 편집하지 않는다.
3. 옮긴 뒤 같은 세션에 다시 들어가려면 그 워크트리에서 `claude --resume` 을 쓴다 (세션 기록이 그 워크트리로 옮겨진다).
