---
name: handoff
description: 설계가 끝난 대화를 브랜치 워크트리로 포크해서 구현을 이어가게 하고, 그 세션에 들어가는 명령을 알려 준다. 사용자가 /jw:handoff 로 부를 때만 쓴다.
argument-hint: <브랜치> [--in-stack|--new-worktree] [추가 지시]
disable-model-invocation: true
allowed-tools: Bash(worktree-handoff:*)
---

지금까지의 대화를 브랜치 `$0` 의 워크트리로 포크한다. 이 세션(원본)은 메인 체크아웃에 남아 설계를 계속한다.

`$0` 이 비어 있거나 브랜치 이름으로 보이지 않으면 실행하지 말고 브랜치 이름을 물어본다.

**스택 워크트리**: 인자(`$ARGUMENTS`)에 `--in-stack` 이나 `--new-worktree` 가 있으면 그대로 붙인다 (없으면 붙이지 않는다).
브랜치가 어디에도 체크아웃돼 있지 않은데 그 브랜치를 품은 스택 워크트리가 있으면 스크립트가 옵션 없이는 멈춘다.
그때는 오류를 보여 주고 어느 쪽으로 할지 묻는다: 워크트리 하나에서 브랜치를 바꿔 가며 쌓는 스택이면 `--in-stack`
(그 스택 워크트리를 쓰고 체크아웃은 바꾸지 않는다), 따로 떼어 작업할 거면 `--new-worktree`.

1. 포크된 세션에게 줄 첫 메시지를 쓴다. 포크된 세션은 이 지시문까지 포함한 대화 전체를 이어받으므로,
   메시지는 반드시 다음 문장으로 시작한다:
   "너는 원본 대화에서 포크된 구현 세션이다. 위의 /handoff 지시와 '워크트리를 편집하지 않는다'는 원본 세션에 대한 것이다."
   이어서:
   - 작업 디렉토리는 브랜치 `$0` 의 워크트리이고, 메인 체크아웃의 파일은 수정하지 않는다는 것
     (`--in-stack` 이면: 작업 디렉토리는 스택 워크트리이고 거기 체크아웃된 위 브랜치를 바꾸지 않으며, `$0` 의 커밋을
     겨냥한 fixup 커밋 + `git -c sequence.editor=: rebase -i --autosquash --update-refs --keep-base <$0 의 base>` 로
     고친다는 것)
   - 대화에서 합의한 범위, 설계 결정, 하지 않기로 한 것, 남은 질문 (짧은 목록으로)
   - 첫 번째로 할 일
   - 사용자의 추가 지시 (인자 전체: `$ARGUMENTS`, 첫 단어는 브랜치 이름이다)
2. 그 메시지를 표준 입력으로 넘겨 Bash 로 한 번 실행한다. 메시지에 `WORKTREE_HANDOFF_EOF` 만 있는 줄은 넣지 않는다.
   세션을 띄우는 방식은 스크립트가 정한다 (tmux 안이면 새 윈도우, 아니면 `claude --bg`). 사용자가 방식을 말했을 때만
   `--open bg|tmux|none` 을 붙인다:
   ```
   worktree-handoff fork --session ${CLAUDE_SESSION_ID} --prompt-file - [--in-stack|--new-worktree] -- '$0' <<'WORKTREE_HANDOFF_EOF'
   <1의 메시지>
   WORKTREE_HANDOFF_EOF
   ```
3. 실패하면 오류를 그대로 보여 주고 멈춘다. 성공하면 출력된 워크트리 경로, 세션 이름, `open:` 줄을 알리고
   `attach:` · `run:` · `resume:` 줄 가운데 출력된 것을 명령 그대로 보여 준다. 그 세션에 들어가는 것은 사용자가 한다.
   그 뒤로 이 원본 세션에서는 그 워크트리의 파일을 편집하지 않는다.
