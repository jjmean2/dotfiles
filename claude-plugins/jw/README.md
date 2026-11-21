# jw

작업할 때 쓰는 개인 스킬 모음 Claude Code 플러그인. 마켓플레이스 `justwonder` 에 있다.

| 스킬 | 하는 일 |
|---|---|
| `/jw:handoff [<브랜치>] [fork\|fresh] [--agent claude\|cursor] [--base <ref>] [--in-stack\|--new-worktree] [추가 지시]` | 대화를 **포크**하거나 작업 지시서를 쓴 **새 세션**(Claude 또는 Cursor)을 브랜치 워크트리에 연다. 모델도 대화를 보고 부르며, 실행 전에 확인을 받는다 |
| `/jw:pr-review-handle [PR] [--all] [--stack]` | PR 에 달린 리뷰(Copilot·사람)를 설명하고, 코드와 대조해 판정하고, 원인을 따져 수정 계획(개별 수정, 근거가 있을 때만 공통 원인·구조 개선)과 배경 원리를 설명한다 |
| `/jw:pr-review-apply [수정 단위\|지적…] [--no-push] [--no-reply]` | pr-review-handle 의 수정 계획을 구현·커밋·푸시하고, 스레드마다 답글을 달고 해결 처리한다. 사용자만 부른다 |

0.10.0 에서 handoff 가 Cursor CLI 세션도 열게 했다. Claude 와 Cursor 어느 쪽에서 부르든 돌고, 어느 도구로 열지는 확인 단계에서
고른다 (아래 "세션을 여는 도구"). 세 스킬 모두 Cursor 에서도 스크립트를 찾도록 `bin/` 경로로 부른다 (아래 "Cursor 에서 쓰기").

0.9.0 에서 pr-review-handle 이 지적마다 따로 수정안을 내는 대신 원인을 따진 수정 계획(공통 원인은 근거가 있을 때만 묶음)을 내고, 그 계획을 구현하고
답글·해결까지 하는 `pr-review-apply` 와 `bin/pr-review-reply` 를 더했다 (아래 "pr-review-apply").

0.8.0 에서 `handoff-fresh`·`handoff-move` 를 `handoff` 하나로 합치고 모델도 부를 수 있게 했다 (아래 "모델이 부르는 handoff").

0.7.0 에서 끝남·허락 대기 때 벨을 울리던 `hooks/tmux-bell` 을 뺐다. 그 일은 별도 플러그인
[`agent-state`](../agent-state/README.md)가 맡는다(상태 배지 + 데스크톱 알림. 벨을 원하면 그 플러그인의 `notify_via = bell`).

## 개념

Claude 나 Cursor 와 대화하다가 작업 방향이 정해지면 그 작업의 브랜치와 워크트리를 만들고, 그 워크트리에서 일할 세션을 준비한다.

```
워크트리 확보 ──▶ 세션 ─────────────────────────▶ 띄우기 ──────────▶ 안내 출력
(git worktree)   방식: fork | fresh | (path)      bg | tmux | none    attach / run / resume / /cd
                 도구: claude | cursor
```

- **fork**: 대화를 포크한다. 시행착오·기각한 안까지 넘겨야 할 때.
- **fresh**: 결론만 담은 지시서로 깨끗한 맥락에서 시작한다. 원본 대화가 길어 컨텍스트가 아까울 때도.
- **path** (스크립트만): 세션을 둘로 나누지 않고 지금 세션을 워크트리로 옮길 `/cd` 명령을 출력한다.

원본 세션은 남아 설계와 질의를 계속한다. 스크립트는 세션을 띄우고 들어가는 명령을
출력하는 데까지만 한다. 그 세션에 들어가는 것은 사용자가 한다.

tmux 는 필요 없다. tmux 안에서 부르면 워크트리의 윈도우를 열어 그 안에서 세션을 띄워 주는 것뿐이다.

## 세션을 여는 도구 (`--agent`, fork·fresh)

새 세션은 Claude Code(`claude`, 기본)나 Cursor CLI(`cursor`)로 연다. 도구마다 다른 것은 이 표가 전부다.

| | `claude` | `cursor` |
|---|---|---|
| 실행 | `claude -n <이름> -- "<첫 메시지>"` | `agent -- "<첫 메시지>"` (`agent` 가 없으면 옛 이름 `cursor-agent`) |
| fork | `--resume <id> --fork-session` | 안 된다. CLI 에 대화를 포크하는 옵션이 없다 (대화 안의 `/fork` 뿐) |
| `--open bg` | `claude --bg` | 안 된다. `agent persist` 는 tmux 안에서는 그냥 `agent` 를 실행하고, 밖에서는 터미널이 있어야 한다 |
| 세션 이름 | `<브랜치>@<MMDD-HHMM>` | 붙일 수 없다 |
| `resume:` 줄 | `claude --resume <이름>` | `agent resume` (그 워크트리의 가장 최근 세션. 고르려면 `agent ls`) |

스킬에서는 확인 단계의 `도구:` 줄에서 고른다. 기본은 스킬을 부른 세션의 도구이고, 확인받은 도구를 `--agent` 로 넘긴다.
스크립트는 부른 곳이 어느 도구인지 짐작하지 않는다. `--agent` 가 없으면 설정의 `agent`, 그것도 없으면 `claude` 다.

부른 곳과 여는 도구에 따라 되는 조합은 이렇다. 대화 기록은 다른 도구로 옮길 수 없어서 도구를 바꾸면 fresh 만 된다.

| 지금 세션 → 여는 도구 | 방식 | tmux 밖에서 띄우면 |
|---|---|---|
| Claude Code → `claude` | fork · fresh | `claude --bg` |
| Cursor → `claude` | fresh | `claude --bg` |
| 어디서든 → `cursor` | fresh | 띄우지 않고 `run:` 줄 |

안 되는 조합(`cursor` 의 fork 와 `--open bg`)은 스크립트가 워크트리를 만들기 전에 거절한다. 설정에서 온 `open=bg` 는 알림을 내고
`auto` 로 띄운다.

## 세션을 띄우는 방식 (`--open`, fork·fresh)

| 값 | 동작 | 들어가기 |
|---|---|---|
| `auto` (기본) | `$TMUX` 가 있으면 `tmux`, 없으면 `bg`, `bg` 가 안 되는 도구면 `none` | |
| `bg` | 워크트리에서 `claude --bg` 로 백그라운드 세션을 띄운다 (`claude` 만) | `claude attach <세션 이름>` |
| `tmux` | 호출한 패널의 tmux 세션에 윈도우를 `-d` 로 열고 그 안에서 실행 | 그 윈도우로 이동 |
| `none` | 띄우지 않는다 | 출력의 `run:` 줄을 원하는 터미널에서 실행 |

어느 방식이든 대화형 세션이다. 출력의 `resume:` 줄로 언제든 다시 연다. `claude` 세션은 이름이 `<브랜치>@<MMDD-HHMM>` 이고
`cd <워크트리> && claude --resume <세션 이름>` 으로 연다. 이름을 잊었으면 그 워크트리에서 `claude --resume <브랜치>` 로 검색한다.
아래는 `claude` 세션을 `bg` 로 띄운 출력이다.

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

## 모델이 부르는 handoff

0.7.0 까지는 세 스킬 모두 `/jw:…` 로만 불렀다. 0.8.0 부터는 하나로 합치고 `disable-model-invocation` 을 뺐다.

- 언제 넘길지·스택을 어떻게 쌓을지 같은 원칙은 chezmoi 가 까는 사용자 규칙
  [`~/.claude/rules/worktree-workflow.md`](../../home/dot_claude/rules/worktree-workflow.md) 에 있다. 규칙은 매 세션
  읽히고, 스킬 본문은 넘길 때만 읽힌다.
- 모델이 먼저 제안할 수 있지만, 실행 전에는 브랜치·베이스·방식·도구·넘길 내용을 보여 주고 답을 기다린다.
- `start_session` 도구가 있는 Claude 데스크톱 앱에서는 이 스킬 대신 그 도구를 쓴다 (원본 세션과 연결되고 보고가 돌아온다).
  그 도구는 Claude 세션만 열므로, Cursor 세션으로 넘길 때는 이 스킬을 쓴다.
- 첫 메시지는 heredoc 대신 임시 파일로 넘긴다. 워크트리 세션의 Bash 가드가 heredoc 이 섞인 명령을 거절하기 때문이다.
- fork 의 세션 ID 는 스크립트가 `$CLAUDE_CODE_SESSION_ID` (Claude Code 가 Bash 셸에 넣어 줌)에서 읽는다.

## Cursor 에서 쓰기

Cursor(데스크톱·CLI)는 설치된 Claude 플러그인을 `~/.claude/plugins/installed_plugins.json` 과 `~/.claude/settings.json` 의
`enabledPlugins` 로 찾아 그 캐시 경로에서 그대로 불러온다. 따로 설치할 것은 없고, Claude 쪽에서 플러그인을 갱신하면 Cursor 에도
반영된다.

세 스킬(handoff·pr-review-handle·pr-review-apply)은 스크립트를 `${CLAUDE_PLUGIN_ROOT}/bin/<이름>` 으로 부른다. 플러그인
`bin/` 을 PATH 에 넣어 주는 것은 Claude Code 뿐이라, 맨이름으로 부르면 Cursor 에서는 찾지 못한다. Claude Code 와 Cursor 모두
플러그인 스킬 본문에서 이 변수를 설치 경로로 바꾼다. Claude Code 는 `allowed-tools` 에서도 바꾸므로 권한 프롬프트 없이 돈다.

실제 Cursor 세션에서 돌려 보지는 않았다. 번들 코드(CLI 2026.11.13, 데스크톱 3.31.11)와 가짜 `agent` 로 확인했다.
확인하지 못한 것:

- Cursor 의 셸 도구가 `TMUX`·`TMUX_PANE` 을 스크립트까지 넘겨 주는지. 없으면 tmux 안에서도 윈도우를 열지 못하고 tmux 밖처럼
  띄운다. Cursor 에이전트에게 `env | grep '^TMUX'` 를 시켜 보면 안다
- Cursor 의 셸 도구에서 띄운 `claude --bg` 세션이 그 명령이 끝난 뒤에도 살아 있는지 (Cursor → `claude`, tmux 밖)
- 처음 보는 워크트리에서 신뢰 여부를 물은 뒤에도 첫 메시지가 이어지는지
- `agent resume` 이 고르는 "가장 최근 세션"이 그 워크트리로 한정되는지
- 스킬 이름에 `jw:` 가 붙지 않아 `/handoff` 로 불리는지, `allowed-tools` 를 읽지 않아 스크립트 실행 때 승인을 묻는지
  (둘 다 3.30.8 데스크톱에서 본 것). 승인을 묻는다면 git·gh 명령을 여러 번 쓰는 pr-review 스킬은 명령마다 묻는다.
  Cursor 의 허용 목록에 넣어야 줄어든다

## 옮기기: path

예전 `handoff-move` 스킬은 없앴다. 지금 세션을 워크트리로 옮기는 일은 규칙에 따라 모델이 `EnterWorktree` 로 한다
(`.claude/worktrees/` 아래). 이 플러그인의 워크트리 위치로 옮기고 싶으면 스크립트를 직접 쓴다.

`worktree-handoff path <브랜치>` 가 워크트리를 확보하고 `move: /cd <경로>` 를 출력한다. 사용자가 그 `/cd` 를 입력하면
세션 기록(`~/.claude/projects/` 아래)·설정·훅·스킬·CLAUDE.md 가 새 디렉토리 기준으로 바뀐다. 세션 ID 는 그대로이고,
이후 `claude --resume` 목록에는 그 워크트리에서 보인다. 모델은 `/cd` 를 부를 수 없다.

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
| `agent` | `WORKTREE_HANDOFF_AGENT` | `claude` |

```ini
root=~/dev/worktrees
open=bg
```

## 필요한 것

- handoff: `claude` (Cursor 세션이면 Cursor CLI `agent`), git. `create=tmux-dev` 면
  [tmux-dev](../../docs/tmux-dev/design/claude-code.md) 와 jq, `--open tmux` 면 tmux.
- pr-review-handle·pr-review-apply: git, `gh` (`gh auth login` 한 번), jq.

## 설치

```sh
claude plugin marketplace add jjmean2/dotfiles          # 또는 클론한 경로: claude plugin marketplace add ~/dev/jwlee/dotfiles
claude plugin install jw@justwonder
```

세션 안에서는 `/plugin marketplace add ...`, `/plugin install jw@justwonder`. 개발 중에는 설치 없이
`claude --plugin-dir claude-plugins/jw`.

플러그인의 `bin/` 은 Claude 의 Bash 도구 PATH 에만 붙는다. 터미널에서도 쓰려면 링크를 둔다.

```sh
ln -s "$(pwd)/claude-plugins/jw/bin/worktree-handoff" "$(pwd)/claude-plugins/jw/bin/pr-review-fetch" \
      "$(pwd)/claude-plugins/jw/bin/pr-review-reply" ~/.local/bin/
```

## 스크립트를 직접 쓰기

```sh
worktree-handoff fork  --session <세션 ID> [--prompt-file <파일|->] [--base <ref>] [--open <방식>]                  [<스택>] <브랜치>
worktree-handoff fresh --prompt-file <파일|->                     [--base <ref>] [--open <방식>] [--agent <도구>] [<스택>] <브랜치>
worktree-handoff path                                             [--base <ref>]                                  [<스택>] <브랜치>
# <스택> = --in-stack | --new-worktree,  <도구> = claude | cursor
```

세션 ID 는 Claude 안의 `/status` 에서 확인한다. Claude 의 Bash 도구에서 부르면 `--session` 없이 `$CLAUDE_CODE_SESSION_ID` 를 쓴다. fork 에서 `--prompt-file` 이 없으면 기본 첫 메시지를 쓴다.
fresh 는 첫 메시지가 꼭 있어야 하고, 비어 있으면(공백뿐이어도) 워크트리를 만들기 전에 멈춘다.
첫 메시지 파일과 런처(`.sh`)·로그(`.log`)는 `${XDG_STATE_HOME:-~/.local/state}/worktree-handoff/prompt/` 에 호출마다
새로 생기고 7일 뒤 지워진다.

## 알아 둘 것

- 포크는 대화 기록만 복사한다. 파일·git 상태는 복사하지 않고, 새 세션의 작업 디렉토리는 워크트리다.
- 대화 중에 한 번만 허용한 권한은 새 프로세스로 넘어가지 않는다 (`settings.local.json` 에 저장된 승인은 워크트리가 공유).
- **작업 폴더 신뢰**: `claude --bg` 는 신뢰하지 않은 폴더에서 바로 실패한다 (`Workspace not trusted`). 신뢰는 상위 디렉토리에서
  물려받으므로, 한 번 `root` 디렉토리(기본 `~/.local/share/worktree-handoff/worktrees`)에서 `claude` 를 열어 신뢰해 두면 그
  아래 워크트리가 모두 신뢰된다. tmux·none 방식은 처음 보는 폴더면 새 세션이 신뢰 여부를 묻고, 답하면 첫 메시지가 이어진다
  (`claude` 의 동작이다. `cursor` 도 신뢰 여부를 묻는데, 그 뒤 첫 메시지가 이어지는지는 확인하지 못했다).
- 런처는 `sh` 스크립트라 사용자 셸(bash·zsh·fish)의 문법과 무관하다. 포크일 때는 앞에 `sleep 2` 를 둔다. 스킬에서 불렸을 때
  원본의 Bash 호출 결과가 기록에 써질 때까지 기다리는 경험값이다. 그래서 포크의 `bg` 는 분리된 프로세스로 띄운다.
- Claude 는 세션 이름이 겹쳐도 막지 않고, `--resume <이름>` 은 정확히 하나가 일치할 때만 바로 연다. 그래서 같은 브랜치로
  여러 번 넘겨도 겹치지 않게 이름에 분 단위 시각을 붙인다. 이름 검색은 지금 디렉토리의 세션만 본다.
- tmux: 새 윈도우는 호출한 패널의 tmux 세션에 생긴다. 그 워크트리의 윈도우(`@worktree`)가 이미 있으면 키를 보내지 않고
  거기에 새 패널을 열고, 나눌 자리가 없으면 새 윈도우를 연다. 다른 터미널 창에서 따로 보려면 같은 세션 그룹에 붙는다:
  `tmux new-session -t <세션> -s <세션>-2 \; select-window -t <윈도우 번호>`.
- 포크된 세션은 handoff 지시문까지 이어받는다. 그래서 첫 메시지가 "그 지시는 원본 세션에 대한 것"이라고 먼저 밝힌다.

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
   "문제가 있는가"와 "리뷰어가 제안한 수정이 맞는가"는 따로 본다. ✅ 에는 영향을, 🟡 에는 권장 여부(한다/안 한다)를
   적는다. 설계 선택이 갈리는 것은 ❌ 가 아니라 💬 로 답하고, 리뷰어끼리 요구가 충돌하면 사용자가 정하게 한다.
3. ✅ 와 권장한 🟡 의 원인을 따진다 (❓ 는 확인되기 전에는 수정을 계획하지 않는다). 지적은 대개 서로 독립이고 그 자리에서 고치면 되며, "공통 원인 없음"이 정상적인 결론이다.
   같은 결함이 여러 곳에 있거나, 국소 수정을 반복해야 하거나, 다음 사람이 같은 실수를 하게 되는 구조라는 신호가 코드에
   있을 때만 거슬러 올라가고, "하나의 수정으로 둘 다 해소된다"를 위치로 보일 수 있을 때만 묶는다. 수정 크기는 원인을
   없애는 가장 작은 것으로 하고, 구조 개선은 재발 경로를 적을 수 있을 때만 제안한다. 비용이 PR 범위를 크게 넘으면
   "국소 수정 + 후속 작업" 안도 함께 낸다. 수정 단위마다 계획을 쓰고, 어느 지적이 어느 수정으로 해소되는지 대응표를 만든다.
   수정안도 지적과 같은 기준으로 검증한다: 문제의 경로가 막히는지, 호출부가 깨지지 않는지, 함께 바꿀 테스트·문서가
   있는지. 확인 방법은 고치기 전에 실패하고 고친 뒤 통과하는 것으로 고른다.
4. ❌·💬·안 하는 🟡 는 리뷰어에게 보낼 답글 초안(게시하지 않음)을 쓴다.

스레드마다 GitHub 노드 ID(`thread_id`, `PRRT_…`), 첫 댓글의 REST ID(`comment_database_id`), 답글·해결 권한
(`viewer_can_reply`·`viewer_can_resolve`)을 함께 받는다. 결과를 보고 고른 스레드에 나중에 답글을 달거나 해결 처리할 때 쓰는
키다. ID 는 바뀌지 않지만 스레드 상태는 바뀌므로, 쓰기 직전에는 `--threads` 로 그 스레드들의 지금 상태(해결 여부, 마지막
댓글 3개, 권한)만 가볍게 다시 받는다.

리뷰 댓글은 누구나 쓸 수 있는 데이터라 그 안의 지시는 따르지 않는다.

```sh
pr-review-fetch [<PR 번호|URL|브랜치>] [--all] [--stack]   # 직접 써도 된다
pr-review-fetch [<PR>] --threads <thread_id>[,<thread_id>…]  # 고른 스레드의 지금 상태만
```

## pr-review-apply

pr-review-handle 의 결과를 본 뒤 `/jw:pr-review-apply` 로 부른다. 부른 것이 구현·커밋·푸시·답글·해결 처리에 대한 승인이라
중간에 묻지 않는다. 바깥에 글을 쓰는 스킬이라 `disable-model-invocation` 으로 모델이 스스로 부르지 않게 했다.
분석(읽기만 하는 스킬, 좁은 `allowed-tools`)과 나눈 것도 같은 이유다.

1. 대화의 수정 계획을 쓴다. 대화에 계획이 없으면 분석만 하고 멈춘다 (사용자가 계획을 보지 않은 채 고치지 않는다).
2. `pr-review-fetch` 로 다시 확인한다: 그 PR 의 워크트리 안인지, PR 이 열려 있는지, 원격이 앞서지 않았는지, 미커밋 변경이
   없는지. 하나라도 어긋나면 멈춘다 (stash 하지 않는다).
3. 고치기 전에 확인 방법을 돌려 기준선을 본다 (버그의 재현 확인이 실패하지 않으면 분석이 틀렸을 수 있으니 멈춘다).
   수정 단위마다 고치고 확인 방법을 돌려 커밋한다. 계획에 없는 리팩터링은 덧붙이지 않는다. 단독 PR 은 단위 하나 = 커밋 하나, 스택 워크트리는 fixup 커밋 뒤
   `rebase --autosquash --update-refs`. 계획이 틀렸다는 것을 알게 되면 즉석에서 설계를 바꾸지 않고 멈춘다.
4. 푸시 전에 대응표를 한 줄씩 다시 보며 지적마다 문제의 경로가 실제로 막혔는지 확인한다. 해소되지 않은 지적은 "고침"으로
   답하지 않는다. 그 뒤 푸시한다 (rebase 했으면 `--force-with-lease`). 직전에 PR 이 아직 열려 있는지 다시 본다.
5. `pr-review-fetch --threads` 로 재확인한 뒤 대응표대로 답글을 단다. 고친 지적과 Copilot 의 지적은 해결 처리하고, 사람
   리뷰어에게 반박·답변한 스레드는 열어 둔다 (납득했는지는 상대가 정한다).

```sh
pr-review-reply [--pr <PR>] --thread <thread_id> [--body-file <파일>] [--resolve]   # 답글 하나 + 해결
```

본문은 파일로만 받는다 (따옴표·줄바꿈이 셸 인자에서 깨지지 않게, 그리고 워크트리 세션의 Bash 가드가 heredoc 을 거절해서).
상태 재확인은 하지 않는다. 그것은 부르는 쪽이 `pr-review-fetch --threads` 로 한다.
