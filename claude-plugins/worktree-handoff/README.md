# worktree-handoff

메인 체크아웃에서 Claude 와 범위를 정하고 설계한 대화를 **포크**해서, 브랜치 워크트리의 새 tmux 윈도우에서 구현
세션으로 이어 가게 하는 Claude Code 플러그인. 메인 세션은 그대로 남아 설계와 질의를 계속한다.

```
/worktree-handoff:handoff <브랜치> [추가 지시]
```

1. 메인 Claude 가 합의한 범위·설계 결정·하지 않기로 한 것·남은 질문·첫 할 일을 첫 메시지로 정리한다.
2. `worktree-handoff` 스크립트가 워크트리를 만들고(있으면 그대로) 새 tmux 윈도우를 백그라운드로 연다.
3. 그 윈도우에서 `claude --resume <지금 세션> --fork-session "<첫 메시지>"` 가 돈다. 대화 전체를 기억한 새 세션이
   워크트리 디렉토리에서 시작한다.

## 필요한 것

tmux 안에서 실행한 `claude`, git, jq. [tmux-dev](../../home/dot_config/tmux/plugins/tmux-dev/claude-code.md) 가 있으면
워크트리를 그 규칙(위치·이름·베이스·셋업 훅)으로 만들고, 없으면 `git worktree add` 로 `<저장소>.worktrees/<브랜치>` 에 만든다.

## 설치

```sh
claude plugin marketplace add jjmean2/dotfiles          # 또는 클론한 경로: claude plugin marketplace add ~/dev/jwlee/dotfiles
claude plugin install worktree-handoff@dotfiles
```

세션 안에서는 `/plugin marketplace add ...`, `/plugin install worktree-handoff@dotfiles`. 개발 중에는 설치 없이
`claude --plugin-dir claude-plugins/worktree-handoff`.

플러그인의 `bin/` 은 Claude 의 Bash 도구 PATH 에만 붙는다. 터미널에서도 쓰려면 링크를 둔다.

```sh
ln -s "$(pwd)/claude-plugins/worktree-handoff/bin/worktree-handoff" ~/.local/bin/
```

## 스크립트를 직접 쓰기

```sh
worktree-handoff --session <세션 ID> [--base <ref>] [--prompt-file <파일|->] <브랜치>
```

세션 ID 는 Claude 안의 `/status` 나 `claude --resume` 피커에서 확인한다. `--prompt-file` 이 없으면 기본 첫 메시지를 쓴다.
`--base` 는 tmux-dev 가 없을 때만 쓰인다 (tmux-dev 는 로컬 기본 브랜치를 베이스로 한다).

## 동시에 보기

새 윈도우는 지금 tmux 세션에 생긴다. 다른 터미널 창에서 따로 보려면 같은 세션 그룹에 붙는다.

```sh
tmux new-session -t <세션> -s <세션>-2 \; select-window -t <윈도우 번호>
```

## 알아 둘 것

- 포크는 대화 기록만 복사한다. 파일·git 상태는 복사하지 않고, 새 세션의 작업 디렉토리는 워크트리다.
- 대화 중에 한 번만 허용한 권한은 새 프로세스로 넘어가지 않는다 (`settings.local.json` 에 저장된 승인은 워크트리가 공유).
- 스킬에서 부르면 포크 시점에 원본의 Bash 호출이 아직 끝나지 않았으므로, 새 패널은 `sleep 2` 뒤에 `claude` 를 띄운다.
- 그 워크트리의 윈도우가 이미 있으면 키를 보내지 않고 그 윈도우에 새 패널을 연다.
