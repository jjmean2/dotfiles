---
name: handoff-move
description: 브랜치 워크트리를 만들고(있으면 그대로), 지금 세션을 그 워크트리로 옮기는 /cd 명령을 알려 준다. 사용자가 /jw:handoff-move 로 부를 때만 쓴다.
argument-hint: <브랜치>
disable-model-invocation: true
allowed-tools: Bash(worktree-handoff:*)
---

브랜치 `$0` 의 워크트리를 확보하고, **이 세션 자체**를 그리로 옮기도록 안내한다. 포크도 새 세션도 만들지 않는다.

`$0` 이 비어 있거나 브랜치 이름으로 보이지 않으면 실행하지 말고 브랜치 이름을 물어본다.

1. Bash 로 한 번 실행한다:
   ```
   worktree-handoff path -- '$0'
   ```
2. 실패하면 오류를 그대로 보여 주고 멈춘다. 성공하면 워크트리 경로를 알리고, 출력의 `move:` 줄(`/cd '<경로>'`)을
   그대로 보여 주며 사용자가 입력하도록 안내한다. `/cd` 는 세션 기록·설정·스킬·CLAUDE.md 를 새 디렉토리로 옮긴다.
   - `/cd` 는 사용자가 입력하는 명령이다. EnterWorktree 도구나 Bash 의 `cd` 로 대신하지 않는다.
   - 사용자가 옮기기 전에는 그 워크트리의 파일을 편집하지 않는다.
3. 옮긴 뒤 같은 세션에 다시 들어가려면 그 워크트리에서 `claude --resume` 을 쓴다 (세션 기록이 그 워크트리로 옮겨진다).
