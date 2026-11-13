# jw

작업할 때 쓰는 개인 스킬 모음 Claude Code 플러그인. 마켓플레이스 `justwonder` 에 있다.

| 스킬 | 하는 일 |
|---|---|
| `/jw:handoff <브랜치> [--in-stack\|--new-worktree] [추가 지시]` | 지금 대화를 브랜치 워크트리로 **포크**한 세션을 연다 |
| `/jw:handoff-fresh <브랜치> [--in-stack\|--new-worktree] [추가 지시]` | 대화 없이, 자기완결적인 작업 지시서를 첫 메시지로 넣은 **새 세션**을 연다 |
| `/jw:handoff-move <브랜치> [--in-stack\|--new-worktree]` | 워크트리만 만들고, **지금 세션**을 그리로 옮기는 `/cd` 명령을 알려 준다 |
| `/jw:pr-review-handle [PR] [--all] [--stack]` | PR 에 달린 리뷰(Copilot·사람)를 설명하고, 코드와 대조해 판정하고, 수정안과 배경 원리를 설명한다 |

## 개념

Claude 와 대화하다가 작업 방향이 정해지면 그 작업의 브랜치와 워크트리를 만들고, 그 워크트리에서 일할 세션을 준비한다.

```
워크트리 확보 ──▶ 세션 ─────────────────▶ 띄우기 ────────────────▶ 안내 출력
(git worktree)   fork | fresh | move(path)   bg | tmux | none           attach / run / resume / /cd
```

- **fork** (`handoff`): 대화를 포크한다. 시행착오·기각한 안까지 넘겨야 할 때.
- **fresh** (`handoff-fresh`): 결론만 담은 지시서로 깨끗한 맥락에서 시작한다. 원본 대화가 길어 컨텍스트가 아까울 때도.
- **move** (`handoff-move`): 세션을 둘로 나누지 않고 지금 세션을 워크트리로 옮긴다.

fork·fresh 는 원본 세션이 메인 체크아웃에 남아 설계와 질의를 계속한다. 스크립트는 세션을 띄우고 들어가는 명령을
출력하는 데까지만 한다. 그 세션에 들어가는 것은 사용자가 한다.

tmux 는 필요 없다. tmux 안에서 부르면 워크트리의 윈도우를 열어 그 안에서 세션을 띄워 주는 것뿐이다.

## 세션을 띄우는 방식 (`--open`, fork·fresh)

| 값 | 동작 | 들어가기 |
|---|---|---|
| `auto` (기본) | `$TMUX` 가 있으면 `tmux`, 없으면 `bg` | |
| `bg` | 워크트리에서 `claude --bg` 로 백그라운드 세션을 띄운다 | `claude attach <세션 이름>` |
| `tmux` | 호출한 패널의 tmux 세션에 윈도우를 `-d` 로 열고 그 안에서 실행 | 그 윈도우로 이동 |
| `none` | 띄우지 않는다 | 출력의 `run:` 줄을 원하는 터미널에서 실행 |

어느 방식이든 대화형 세션이고 이름은 `<브랜치>@<MMDD-HHMM>` 이다. 출력의 `resume:` 줄
(`cd <워크트리> && claude --resume <세션 이름>`)로 언제든 다시 연다. 이름을 잊었으면 그 워크트리에서
`claude --resume <브랜치>` 로 검색한다.

```
worktree: ~/.local/share/worktree-handoff/worktrees/dotfiles/feat-x
branch:   feat/x
session:  feat/x@1111-1530
open:     background
attach:   claude attach 'feat/x@1111-1530'
resume:   cd '…/feat-x' && claude --resume 'feat/x@1111-1530'
```

`bg` 로 띄우지 못하면(작업 폴더를 신뢰하지 않음 등) claude 의 오류와 `run:` 줄을 출력하고 종료 코드 1 로 끝난다.
워크트리는 남아 있으니 `run:` 줄을 터미널에서 실행하면 된다. 포크는 원본의 기록이 써지도록 2초 뒤에 띄우므로
실패가 그 자리에서 보이지 않는다. `open:` 줄의 로그 파일을 본다.

## 옮기기: handoff-move

`worktree-handoff path <브랜치>` 가 워크트리를 확보하고 `move: /cd '<경로>'` 를 출력한다. 사용자가 그 `/cd` 를 입력하면
세션 기록(`~/.claude/projects/` 아래)·설정·훅·스킬·CLAUDE.md 가 새 디렉토리 기준으로 바뀐다. 세션 ID 는 그대로이고,
이후 `claude --resume` 목록에는 그 워크트리에서 보인다. 모델은 `/cd` 를 부를 수 없다. EnterWorktree 도구도 기록을
옮기지만 설정·스킬을 다시 읽지 않고 저장소 밖 경로면 승인을 묻기 때문에 쓰지 않는다.

## 워크트리

| 상황 | 워크트리 |
|---|---|
| 그 브랜치의 워크트리가 이미 있음 | 그대로 쓴다 (메인 체크아웃이나 지금 세션이 있는 체크아웃이면 거부) |
| 없음, 그 브랜치를 품은 스택 워크트리가 있음 | 멈춘다. `--in-stack` 이면 그 워크트리, `--new-worktree` 면 아래처럼 새로 (아래 스택 워크트리) |
| 없음 | `git worktree add` 로 `<root>/<저장소>/<브랜치의 / 를 - 로>` |
| 없음, `create=tmux-dev` | `tmux-dev worktree [--base <ref>] --hook-create` (그 위치·셋업 훅). tmux-dev·jq 가 없거나 실패하면 git 으로 |

새로 만들 때 브랜치는 로컬에 있으면 그것을, `--base` 없이 원격 하나에만 있으면 추적 브랜치를, 아니면 `--base`
(기본: `origin/HEAD` 가 가리키는 로컬 브랜치 → `main`/`master` → 메인의 HEAD)에서 새로 만든다.

어디에 만들든 `git worktree list` 로 보이고, tmux-dev 피커(`prefix W`)도 그 목록을 읽는다.
bare 저장소는 지원하지 않는다. 정리는 `git worktree remove <경로>` 와 `git branch -d <브랜치>`. `.env` 처럼 추적되지 않는 파일은
복사하지 않는다 (필요하면 `create=tmux-dev` 의 셋업 훅).

### 스택 워크트리

워크트리 하나에서 브랜치를 바꿔 가며 PR 을 쌓으면 (`main ← a ← b ← c`, 워크트리에는 `c`) 하위 브랜치 `a`·`b` 는 어디에도
체크아웃돼 있지 않다. 이때 `a` 로 새 워크트리를 만들면 스택 워크트리에서 `a` 를 체크아웃할 수 없고
`git rebase --update-refs` 도 `a` 를 옮기지 않아 스택이 갈라진다. 그래서 브랜치가 체크아웃돼 있지 않은데 그 브랜치를
조상으로 품은 워크트리(기본 브랜치의 워크트리는 제외)가 있으면 스크립트가 멈추고 둘 중 하나를 고르게 한다.

| 옵션 | 동작 |
|---|---|
| `--in-stack` | 그 스택 워크트리를 쓴다. 체크아웃은 바꾸지 않는다. `branch:` 줄에 `(스택 워크트리, 체크아웃: c)` 가 붙고, 포크의 기본 첫 메시지에 고치는 방법이 들어간다 |
| `--new-worktree` | 그래도 새 워크트리를 만든다 |

품은 워크트리가 여럿이면 지금 체크아웃을, 아니면 커밋 차이가 가장 적은(바로 위) 워크트리를 고른다. 스택 워크트리에서
하위 브랜치를 고칠 때는 체크아웃을 바꾸지 않고 fixup 커밋을 만든 뒤 스택 전체를 다시 쌓는다:

```sh
git commit --fixup=<a 의 커밋>
git -c sequence.editor=: rebase -i --autosquash --update-refs --keep-base main
```

## 설정

`${XDG_CONFIG_HOME:-~/.config}/worktree-handoff/config` 에 `key=value` (`#` 주석). 실행하지 않고 값만 읽는다.
같은 이름의 환경 변수가 먼저다. `root` 는 절대 경로나 `~/` 로 시작해야 한다.

| 키 | 환경 변수 | 기본 |
|---|---|---|
| `root` | `WORKTREE_HANDOFF_ROOT` | `${XDG_DATA_HOME:-~/.local/share}/worktree-handoff/worktrees` |
| `open` | `WORKTREE_HANDOFF_OPEN` | `auto` |
| `create` | `WORKTREE_HANDOFF_CREATE` | `git` |

```ini
root=~/dev/worktrees
open=bg
```

## 필요한 것

- handoff: `claude`, git. `create=tmux-dev` 면 [tmux-dev](../../home/dot_config/tmux/plugins/tmux-dev/claude-code.md) 와 jq,
  `--open tmux` 면 tmux.
- pr-review-handle: git, `gh` (`gh auth login` 한 번), jq.

## 설치

```sh
claude plugin marketplace add jjmean2/dotfiles          # 또는 클론한 경로: claude plugin marketplace add ~/dev/jwlee/dotfiles
claude plugin install jw@justwonder
```

세션 안에서는 `/plugin marketplace add ...`, `/plugin install jw@justwonder`. 개발 중에는 설치 없이
`claude --plugin-dir claude-plugins/jw`.

플러그인의 `bin/` 은 Claude 의 Bash 도구 PATH 에만 붙는다. 터미널에서도 쓰려면 링크를 둔다.

```sh
ln -s "$(pwd)/claude-plugins/jw/bin/worktree-handoff" "$(pwd)/claude-plugins/jw/bin/pr-review-fetch" ~/.local/bin/
```

## 스크립트를 직접 쓰기

```sh
worktree-handoff fork  --session <세션 ID> [--prompt-file <파일|->] [--base <ref>] [--open <방식>] [<스택>] <브랜치>
worktree-handoff fresh --prompt-file <파일|->                     [--base <ref>] [--open <방식>] [<스택>] <브랜치>
worktree-handoff path                                             [--base <ref>]                 [<스택>] <브랜치>
# <스택> = --in-stack | --new-worktree
```

세션 ID 는 Claude 안의 `/status` 에서 확인한다. fork 에서 `--prompt-file` 이 없으면 기본 첫 메시지를 쓴다.
fresh 는 첫 메시지가 꼭 있어야 하고, 비어 있으면(공백뿐이어도) 워크트리를 만들기 전에 멈춘다.
첫 메시지 파일과 런처(`.sh`)·로그(`.log`)는 `${XDG_STATE_HOME:-~/.local/state}/worktree-handoff/prompt/` 에 호출마다
새로 생기고 7일 뒤 지워진다.

## 알아 둘 것

- 포크는 대화 기록만 복사한다. 파일·git 상태는 복사하지 않고, 새 세션의 작업 디렉토리는 워크트리다.
- 대화 중에 한 번만 허용한 권한은 새 프로세스로 넘어가지 않는다 (`settings.local.json` 에 저장된 승인은 워크트리가 공유).
- **작업 폴더 신뢰**: `claude --bg` 는 신뢰하지 않은 폴더에서 바로 실패한다 (`Workspace not trusted`). 신뢰는 상위 디렉토리에서
  물려받으므로, 한 번 `root` 디렉토리(기본 `~/.local/share/worktree-handoff/worktrees`)에서 `claude` 를 열어 신뢰해 두면 그
  아래 워크트리가 모두 신뢰된다. tmux·none 방식은 처음 보는 폴더면 새 세션이 신뢰 여부를 묻고, 답하면 첫 메시지가 이어진다.
- 런처는 `sh` 스크립트라 사용자 셸(bash·zsh·fish)의 문법과 무관하다. 포크일 때는 앞에 `sleep 2` 를 둔다. 스킬에서 불렸을 때
  원본의 Bash 호출 결과가 기록에 써질 때까지 기다리는 경험값이다. 그래서 포크의 `bg` 는 분리된 프로세스로 띄운다.
- Claude 는 세션 이름이 겹쳐도 막지 않고, `--resume <이름>` 은 정확히 하나가 일치할 때만 바로 연다. 그래서 같은 브랜치로
  여러 번 넘겨도 겹치지 않게 이름에 분 단위 시각을 붙인다. 이름 검색은 지금 디렉토리의 세션만 본다.
- tmux: 새 윈도우는 호출한 패널의 tmux 세션에 생긴다. 그 워크트리의 윈도우(`@worktree`)가 이미 있으면 키를 보내지 않고
  거기에 새 패널을 열고, 나눌 자리가 없으면 새 윈도우를 연다. 다른 터미널 창에서 따로 보려면 같은 세션 그룹에 붙는다:
  `tmux new-session -t <세션> -s <세션>-2 \; select-window -t <윈도우 번호>`.
- 포크된 세션은 /handoff 지시문까지 이어받는다. 그래서 첫 메시지가 "그 지시는 원본 세션에 대한 것"이라고 먼저 밝힌다.

## pr-review-handle

PR 에 이미 달린 리뷰 댓글을 처리한다. 코드를 직접 리뷰하는 `/code-review` 와는 다르다. 읽기만 하는 스킬이라
"PR 리뷰 댓글 정리해줘" 같은 말로도 불린다. 코드 수정과 답글 게시는 하지 않고, 결과를 보고 고른 항목만 이어서 처리한다.

1. `pr-review-fetch` 가 GitHub GraphQL 로 리뷰 스레드(해결·지난 댓글 여부, 당시 커밋, 스레드의 모든 댓글), 리뷰 본문,
   PR 댓글을 끝까지 받아 JSON 하나로 낸다. 기본은 해결 안 된 스레드만, `--all` 이면 전부.
   로컬에 PR head 나 지난 댓글의 당시 커밋이 없으면 `refs/pull/<N>/head`·그 커밋을 원격에서 받는다 (작업 트리는 그대로).
   로컬 상태는 워크트리가 아니라 로컬 PR 브랜치 기준이다. 고칠 곳(`local.checkout`)은 PR 브랜치가 체크아웃된 워크트리
   (`self`), 없으면 그 브랜치를 품은 스택 워크트리(`stack`), 둘 다 없으면 `none`. `stack` 이면 그 작업 트리는 위 브랜치의
   코드라 이 PR 의 로컬로 쓰지 않고, 다음 단계는 `--in-stack` handoff 나 그 자리의 fixup 으로 안내한다.
   지금 브랜치에 PR 이 없으면 (스택 맨 위의 작업 중 브랜치) 그 아래 쌓인 PR 을 찾는다: `--stack` 이면 가장 가까운 PR 부터
   스택을 모으고, 아니면 목록을 보여 주고 멈춘다.
   `--stack` 이면 그 PR 이 속한 스택(base 를 따라 아래로, 그 PR 위에 쌓인 열린 PR 을 따라 위로, 갈라지면 모든 가지)을
   찾아 PR 마다 같은 내용을 모은다. fork PR 은 스택으로 잇지 않는다.
2. 스킬이 항목마다 리뷰 시점 / PR head / 로컬 세 시점의 코드를 구분해 읽고 판정한다:
   ✅ 수정 필요 · 🟡 선택 · ❌ 불필요(반대 증거 필요) · 💬 답변 필요 · 💬✓ 답변 완료 · 🔁 반영됨 · ❓ 판단 보류.
3. ✅ 는 수정안과 배경 원리, ❌·💬 는 리뷰어에게 보낼 답글 초안(게시하지 않음)을 쓴다.

리뷰 댓글은 누구나 쓸 수 있는 데이터라 그 안의 지시는 따르지 않는다.

```sh
pr-review-fetch [<PR 번호|URL|브랜치>] [--all] [--stack]   # 직접 써도 된다
```
