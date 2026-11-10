---
name: handoff
description: 설계가 끝난 대화를 포크해서 브랜치 워크트리의 새 tmux 윈도우에서 구현을 이어가게 한다. 사용자가 /handoff 로 부를 때만 쓴다.
argument-hint: <브랜치> [추가 지시]
disable-model-invocation: true
allowed-tools: Bash(worktree-handoff:*)
---

지금까지의 대화를 브랜치 `$0` 의 워크트리로 넘긴다. 이 세션은 메인 체크아웃에 남아 설계를 계속한다.

1. 넘겨받을 세션에게 줄 첫 메시지를 쓴다. 내용:
   - 이 세션은 포크된 구현 세션이며, 작업 디렉토리는 브랜치 `$0` 의 워크트리라는 것
   - 메인 체크아웃의 파일은 수정하지 않는다는 것
   - 대화에서 합의한 범위, 설계 결정, 하지 않기로 한 것, 남은 질문 (짧은 목록으로)
   - 첫 번째로 할 일
   - 사용자의 추가 지시: $ARGUMENTS
2. 그 메시지를 표준 입력으로 넘겨 실행한다 (Bash 한 번):
   ```
   worktree-handoff --session ${CLAUDE_SESSION_ID} --prompt-file - $0 <<'HANDOFF'
   <1의 메시지>
   HANDOFF
   ```
3. 출력된 워크트리 경로와 윈도우를 한 줄로 알린다. 그 뒤로 이 세션에서는 그 워크트리의 파일을 편집하지 않는다.
