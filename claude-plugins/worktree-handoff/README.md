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
워크트리를 그 규칙(위치·이름·베이스·셋업 훅)으로 만들고, 없으면 `git worktree add` 로 XDG 데이터 디렉토리에 만든다.

| 상황 | 워크트리 |
|---|---|
| 그 브랜치의 워크트리가 이미 있음 | 그대로 쓴다 (메인 체크아웃이나 지금 세션이 있는 체크아웃이면 거부) |
| tmux-dev 있음 | `tmux-dev worktree [--base <ref>] --hook-create`. 실패하면(서브모듈 등) 아래로 |
| tmux-dev 없음 | `${XDG_DATA_HOME:-~/.local/share}/worktree-handoff/worktrees/<저장소>/<브랜치의 / 를 - 로>` |

tmux-dev 없이 만들 때 브랜치는 로컬에 있으면 그것을, `--base` 없이 원격 하나에만 있으면 추적 브랜치를, 아니면 `--base`
(기본: `origin/HEAD` 가 가리키는 로컬 브랜치 → `main`/`master` → 메인의 HEAD)에서 새로 만든다.
bare 저장소는 지원하지 않는다. 정리는 `git worktree remove <경로>` 와 `git branch -d <브랜치>`. `.env` 처럼 추적되지 않는 파일은 복사하지 않는다.

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

세션 ID 는 Claude 안의 `/status` 에서 확인한다. `--prompt-file` 이 없으면 기본 첫 메시지를 쓴다.
첫 메시지 파일은 `${XDG_STATE_HOME:-~/.local/state}/worktree-handoff/prompt/` 에 호출마다 새로 생기고 7일 뒤 지워진다.

## 동시에 보기

새 윈도우는 지금 tmux 세션에 생긴다. 다른 터미널 창에서 따로 보려면 같은 세션 그룹에 붙는다.

```sh
tmux new-session -t <세션> -s <세션>-2 \; select-window -t <윈도우 번호>
```

## 알아 둘 것

- 포크는 대화 기록만 복사한다. 파일·git 상태는 복사하지 않고, 새 세션의 작업 디렉토리는 워크트리다.
- 대화 중에 한 번만 허용한 권한은 새 프로세스로 넘어가지 않는다 (`settings.local.json` 에 저장된 승인은 워크트리가 공유).
- 새 패널에는 `sh '<런처>'` 만 입력한다. 런처(첫 메시지 파일 옆의 `.sh`)가 `sleep 2` 뒤에
  `claude --resume <id> --fork-session -- "<첫 메시지>"` 를 실행하므로 사용자 셸(bash·zsh·fish)의 문법과 무관하다.
  `sleep 2` 는 스킬에서 불렸을 때 원본의 Bash 호출 결과가 기록에 써질 때까지 기다리는 경험값이다.
- 새 윈도우는 호출한 패널의 tmux 세션에 생긴다. 그 워크트리의 윈도우가 이미 있으면 키를 보내지 않고 거기에 새 패널을
  열고, 나눌 자리가 없으면 새 윈도우를 연다.
- 처음 보는 디렉토리라 Claude 가 폴더 신뢰 여부를 물을 수 있다. 새 윈도우에서 한 번 답하면 첫 메시지가 이어서 전달된다.
- 포크된 세션은 /handoff 지시문까지 이어받는다. 그래서 첫 메시지가 "그 지시는 원본 세션에 대한 것"이라고 먼저 밝힌다.
