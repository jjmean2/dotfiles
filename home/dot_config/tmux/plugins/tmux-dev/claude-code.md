# tmux-dev 와 Claude Code

세션 = 저장소, 윈도우 = 워크트리라는 관례 위에서 에이전트를 쓰는 방법. 근거가 되는 Claude Code 의 동작
(2.1.318 문서 기준): 자동 메모리는 git 저장소 단위로 모든 워크트리가 공유하고, 권한 승인(`settings.local.json`)은
메인 체크아웃 루트의 파일을 쓰며, CLAUDE.md 는 cwd 와 상위 디렉토리에서 읽는다. 세션 기록만 시작 디렉토리별이다
(세션 피커에서 Ctrl+W 로 저장소 전체). 그래서 에이전트를 워크트리 안에서 띄워도 잃는 것이 없다.

## 기본 흐름: 워크트리를 먼저, 에이전트는 그 안에서

1. 저장소 세션에서 `prefix W`, 브랜치 이름을 치고 Enter. 워크트리와 윈도우(왼쪽 셸 / 오른쪽 nvim)가 생긴다.
2. 왼쪽 셸에서 `claude`. 에이전트는 그 트리에서 커밋·푸시하고 `gh pr create --draft` 로 리뷰 화면을 연다.
3. 머지는 GitHub 버튼이나 `gh pr merge --rebase`. 원격 브랜치 삭제는 GitHub 의 자동 삭제에 맡긴다
   (`--delete-branch` 는 워크트리에 체크아웃된 로컬 브랜치를 지우려다 실패한다).
4. `prefix W` 에서 `merged` 가 뜬 행에 ctrl-x. 워크트리 제거, 윈도우 닫기, 브랜치는 `refs/archive/<날짜>/<브랜치>`
   에 보관한 뒤 삭제, 마지막에 main 을 origin 에 맞출지 묻는다.

손으로 할 때도 같은 네 단계다. 수동 워크트리에서 띄운 `claude` 에는 메인 체크아웃 편집을 막는 격리 검사가 없으므로
전역 `~/.claude/CLAUDE.md` 에 아래 지침을 둔다.

```markdown
## 워크트리
- 이 머신의 저장소는 메인 체크아웃에서 직접 작업하지 않는다. 메인은 기본 브랜치와 동기화만 한다.
- 이미 git 워크트리 안에서 시작했으면 그 안에서만 작업하고, 새 워크트리를 만들지 않는다.
- 워크트리가 필요하면 EnterWorktree 를 쓴다 (WorktreeCreate 훅이 tmux-dev 로 만들어 준다). git worktree add 를 직접 치지 않는다.
- 작업 브랜치 이름은 짧은 kebab-case 로, 접두어 없이. 베이스는 로컬 main.
- 머지 방식은 저장소 관례를 따르고, 없으면 rebase (스택이면 squash). 머지 뒤 정리는 사람이 prefix W 의 ctrl-x 로 한다.
```

## 에이전트가 만드는 워크트리도 같은 자리에: WorktreeCreate / WorktreeRemove 훅

Claude Code 의 `WorktreeCreate` 훅은 `claude -w`, EnterWorktree, 백그라운드 세션(`--bg`), 격리 서브에이전트가 워크트리를
만들 때 발화하고 **기본 `git worktree add` 를 통째로 대체**한다. 훅을 `tmux-dev worktree --hook-create` 로 두면 에이전트가
만드는 워크트리도 사람이 만든 것과 같은 위치(`~/.local/share/tmux-dev/worktrees/<저장소>/<브랜치>`), 같은 이름
(`worktree-` 접두어 없음), 같은 베이스(로컬 main), 같은 셋업 훅(`tmux-dev.worktree.setup`)을 탄다. 피커는 그 모두를 한 목록에
보여 준다. `WorktreeRemove` 는 Claude 가 워크트리를 지우기로 한 뒤 불린다. 사용자가 종료 때 "지우기" 를 고른 경우와,
깨끗한 무명 워크트리가 세션 종료로 자동 정리되는 경우 둘 다다. 그래서 워크트리는 강제로 지우되 브랜치는 **main 에 모두
들어 있을 때만** 보관 → 삭제하고, 머지 안 된 커밋이 있는 브랜치는 남긴다(피커에 `[ahead n]` 행으로 뜨고 ctrl-x 가 확인을
거쳐 정리한다). tmux 윈도우는 건드리지 않는다(사람의 셸이 거기 있을 수 있다).

`~/.claude/settings.json` 의 `hooks` 에 추가 (이 파일은 dotfiles 밖이다):

```json
{
  "hooks": {
    "WorktreeCreate": [
      { "hooks": [ { "type": "command", "command": "$HOME/.config/tmux/plugins/tmux-dev/bin/tmux-dev worktree --hook-create" } ] }
    ],
    "WorktreeRemove": [
      { "hooks": [ { "type": "command", "command": "$HOME/.config/tmux/plugins/tmux-dev/bin/tmux-dev worktree --hook-remove" } ] }
    ]
  }
}
```

확인된 것(2026-11-05 실측): 훅이 저장소 밖 경로를 돌려줘도 `claude -p -w <이름>` 은 승인 요구 없이 그 워크트리에서
세션을 돈다. 알아 둘 것:
- 격리 서브에이전트의 임시 워크트리도 이 훅으로 중앙 디렉토리에 생기지만 `WorktreeRemove` 는 그들에겐 발화하지 않는다.
  피커의 `merged`·`prunable` 마커와 ctrl-x 가 청소 수단이다.
- 훅이 만든 브랜치는 Claude 가 지우지 않는다. 삭제는 `--hook-remove` 또는 ctrl-x 가 한다(둘 다 보관 먼저).
- Bash 로 직접 친 `git worktree add` 에는 훅이 발화하지 않는다. 그래서 위 지침에 "직접 치지 않는다" 가 있다.

## 백그라운드 변형

폰이나 다른 세션에서 `claude --bg -w <이름> -p "..."`. 훅이 중앙 위치에 워크트리를 만들고 세션이 거기서 돈다.
나중에 `prefix W` → 그 행에 Enter 로 윈도우를 열고, 왼쪽 셸에서 `claude attach <id>`. 끝나면 ctrl-x.

## 스택(gh stack)

한 워크트리 = 한 스택. `gh stack` 이 그 안에서 브랜치를 바꾸므로 윈도우 이름(`-n`)은 처음 브랜치로 남고(바꾸려면 `prefix ,`),
ctrl-x 의 브랜치 단계는 현재 브랜치만 본다. 머지는 squash 를 권한다.
