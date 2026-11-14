# 작업별 안내

하려는 일이 정해져 있을 때 읽는 문서다. 각 절은 독립적이다. 처음 쓰는 경우에는 [시작하기](getting-started.md)를 먼저 본다.

- [프로젝트 열기와 만들기](#프로젝트-열기와-만들기)
  - [목록에 없는 경로 열기](#목록에-없는-경로-열기)
  - [새 프로젝트 만들기](#새-프로젝트-만들기)
- [윈도우 열기](#윈도우-열기)
  - [기존 브랜치나 원격 브랜치를 워크트리로 열기](#기존-브랜치나-원격-브랜치를-워크트리로-열기)
  - [저장소가 아닌 디렉토리를 윈도우로 열기](#저장소가-아닌-디렉토리를-윈도우로-열기)
- [워크트리 정리하기](#워크트리-정리하기)
  - [머지된 워크트리를 한꺼번에 정리하기](#머지된-워크트리를-한꺼번에-정리하기)
  - [지운 브랜치 되살리기](#지운-브랜치-되살리기)
- [레이아웃 바꾸기](#레이아웃-바꾸기)
  - [나만의 레이아웃 추가하기](#나만의-레이아웃-추가하기)
  - [dev 서버 명령 정하기](#dev-서버-명령-정하기)
- [워크트리 위치와 초기 설정 바꾸기](#워크트리-위치와-초기-설정-바꾸기)
- [탐색에서 디렉토리 빼기](#탐색에서-디렉토리-빼기)
- [키와 피커 크기 바꾸기](#키와-피커-크기-바꾸기)
- [셸에서 쓰기](#셸에서-쓰기)
- [Claude Code 와 함께 쓰기](#claude-code-와-함께-쓰기)
- [다른 tmux 설정에 설치하기](#다른-tmux-설정에-설치하기)

---

## 프로젝트 열기와 만들기

`prefix S` 는 디렉토리 하나를 골라 그 디렉토리의 세션으로 간다. 세션이 없으면 만든다.

### 목록에 없는 경로 열기

숨김 디렉토리 아래(`~/.local/...`), 홈 밖, 탐색 제외 경로는 목록에 나오지 않는다. 경로를 직접 친다.

1. `prefix S` 를 누른다.
2. `/` 나 `~` 로 시작하는 경로를 친다. 예: `~/.local/share/nvim/lazy/LazyVim`

   경로 모양 검색어는 퍼지 검색이 아니라 **경로 접두 일치**로 거른다. 끝에 `/` 를 붙이면 "이 디렉토리 아래" 를 뜻한다.

3. `enter` 를 누른다. 그 경로가 있는 디렉토리면 목록에 없어도 연다.

> **팁:** 목록의 항목에서 `ctrl-]` 를 누르면 그 경로가 검색어에 채워진다. 이어서 `/하위이름` 을 쳐서 그 아래로 좁힌다.

### 새 프로젝트 만들기

1. `prefix S` 를 누른다.
2. 모드를 고른다. `repository` 모드에서 만들면 `git init` 까지 한다. `directory` 모드는 디렉토리만 만든다.
   모드는 `alt-m`(다음)·`alt-n`(이전)으로 바꾼다.
3. 새 이름을 친다. 예: `my-app`. 같은 이름의 항목이 목록에 걸려도 상관없다.
4. `alt-enter` 를 누른다. 만들 위치를 고르는 목록이 겹쳐 뜬다.

   | 표시 | 후보 |
   |---|---|
   | `◷` | 최근에 무언가를 만든 위치 |
   | `↳` | `alt-enter` 를 누를 때 커서에 있던 항목의 부모 |
   | (없음) | 홈 아래 모든 디렉토리 |

   미리보기에 만들어질 경로와 판정(새로 만든다 / 이미 있다 / git init / 다른 저장소 안)이 나온다.

5. 위치에 커서를 두고 `enter` 를 누른다. 레이아웃을 골라서 만들려면 `alt-l` 을 누른다.

**결과:** 디렉토리(와 저장소)가 생기고 그 세션으로 전환된다. 같은 이름이 이미 있으면 만들지 않고 연다.

- 이름에 `/` 를 넣으면 중간 디렉토리도 만든다 (`apps/web`).
- 위치를 묻지 않고 바로 만들려면 2단계에서 전체 경로(`~/dev/my-app`)를 치고 `alt-enter` 를 누른다.
- 위치 목록에서 `esc` 를 누르면 검색어와 커서가 그대로인 메인 목록으로 돌아간다.

---

## 윈도우 열기

`prefix W` 는 지금 세션 안에 윈도우를 연다. 피커에는 세 모드가 있다.

| 모드 | 언제 나오나 | 후보 |
|---|---|---|
| `worktree` | 세션 디렉토리가 git 저장소일 때 (기본 모드) | 워크트리 → 로컬 브랜치 → 원격 브랜치 (`origin/*`) |
| `subdirectory` | 항상 | 세션 디렉토리 아래의 디렉토리 (`⌂` = 세션 디렉토리 자신) |
| `directory` | 항상 | 홈 아래의 모든 디렉토리 |

저장소 판정은 키를 누른 패널의 현재 디렉토리가 아니라 **세션 디렉토리**를 기준으로 한다. 같은 세션이면 어느 패널에서 눌러도 결과가 같다.

### 기존 브랜치나 원격 브랜치를 워크트리로 열기

1. 저장소 세션에서 `prefix W` 를 누른다.
2. 브랜치 행을 찾는다. 로컬 브랜치는 `(branch)`, 원격 브랜치는 `(remote)` 가 붙어 있다.
3. `enter` 를 누른다. 푸터에 확인 문구가 뜬다.
4. `enter` 로 만든다. 레이아웃을 골라서 만들려면 `alt-l` 을 누른다. 취소는 `esc` 다 (커서를 옮기거나 글자를 쳐도 취소된다).

**결과:** 워크트리와 윈도우가 생긴다. 원격 브랜치를 고르면 같은 이름의 추적 브랜치를 함께 만든다.

### 저장소가 아닌 디렉토리를 윈도우로 열기

1. `prefix W` 를 누른다.
2. `alt-m` 으로 `subdirectory` 나 `directory` 모드로 바꾼다.
3. 디렉토리를 골라 `enter` 를 누른다.

**결과:** 지금 세션에 그 디렉토리의 윈도우가 생긴다 (이미 있으면 그리로 간다). 고른 디렉토리가 이 저장소의 워크트리면
워크트리 윈도우로 연다. 새 디렉토리를 만들려면 이름을 치고 `alt-enter` 를 누른다 (`prefix S` 와 같은 위치 목록).

---

## 워크트리 정리하기

정리는 `prefix W` 의 `worktree` 모드에서 `ctrl-x` 로 한다. 기본 절차는 [시작하기 4단계](getting-started.md#4단계-워크트리-정리하기)에 있다.

정리할 수 없는 항목은 벨과 함께 이유를 보여 준다.

| 항목 | 정리 |
|---|---|
| 메인 체크아웃, 베이스 브랜치, 원격 브랜치, locked 워크트리 | 하지 않는다 |
| 커밋하지 않은 변경이 있는 워크트리 (`dirty N`) | 변경 수와 함께 실패한다. 커밋하거나 버린 뒤 다시 한다 |
| 머지되지 않은 브랜치 | `clean up` 이면 한 번 더 묻는다 |

### 머지된 워크트리를 한꺼번에 정리하기

1. `prefix W` 를 누른다. 행에 `merged` 마커가 붙을 때까지 잠깐 기다린다 (목록을 먼저 띄우고 마커를 뒤에서 얹는다).
2. `ctrl-t` 를 누른다. `merged` 인 워크트리와 브랜치가 모두 선택된다.

   직접 고르려면 `tab`(선택)·`shift-tab`(해제)을 쓴다. 선택이 있을 때 `ctrl-t` 를 다시 누르면 모두 풀린다.

3. `ctrl-x` 를 누른다. 정리 목록에 `clean up N` / `keep branches` 가 뜬다. 미리보기에 항목별로 할 일과 건너뛸 항목이 나온다.
4. `enter` 를 누른다.

**결과:** 푸터에 스피너와 진행 상황이 나온다. 하나가 실패해도 나머지는 계속하고, 끝나면 결과를 개수로 보여 준다.
정리는 tmux 서버의 백그라운드 작업으로 돌기 때문에 도중에 피커를 닫아도 끝까지 진행된다.

> **참고:** 머지 판정은 로컬 `main` 이 `origin/main` 보다 뒤처져 있으면 `origin/main` 을 기준으로 한다. 피커가 뜰 때
> 백그라운드에서 `git fetch --prune` 을 하므로 GitHub 에서 PR 을 머지한 뒤 `git pull` 을 하지 않아도 `merged` 로 보인다.

### 지운 브랜치 되살리기

`clean up` 은 브랜치를 지우기 전에 항상 `refs/archive/<날짜>/<브랜치>` 에 보관한다. 같은 날 같은 이름이 있으면 `-2`, `-3` 이 붙는다.

```sh
tmux-dev worktree --archived                                 # 보관 목록
git branch feat-x refs/archive/2026-11-09/feat-x             # 브랜치 복구
```

복구한 브랜치는 `prefix W` 목록에 다시 나온다. 그 행에서 `enter` 로 워크트리를 다시 만든다.

---

## 레이아웃 바꾸기

레이아웃은 새 세션·윈도우의 어느 패널에 무엇을 띄울지 정한다. 윈도우를 만들 때 한 번만 적용한다.

| 이름 | 배치 |
|---|---|
| `plain` | 셸 하나 **(기본값)** |
| `ide` | 왼쪽 셸 / 오른쪽 nvim |
| `ide-dev` | 왼쪽 셸 / 오른쪽 위 nvim, 오른쪽 아래 dev 서버 |
| `nvim` | nvim 하나 |
| `nvim-dev` | 위 nvim / 아래 dev 서버 |

nvim 과 dev 서버는 셸 위에서 실행한다. nvim 을 닫거나 서버를 `ctrl-c` 로 꺼도 패널의 셸은 남는다.

어떤 레이아웃을 쓸지는 다음 순서로 정한다. 앞에 있는 것이 이긴다.

1. 이번 한 번만: 피커의 `alt-l`, 또는 명령줄 `--layout <이름>`
2. 저장소 기본값: `git config tmux-dev.layout <이름>`
3. 전역 기본값: tmux 옵션 `@tmux-dev-layout`
4. 내장 기본값: `plain`

### 이번 한 번만 다른 레이아웃으로 열기

1. 피커에서 열 항목에 커서를 두고 `alt-l` 을 누른다.
2. 레이아웃 목록에서 고르고 `enter` 를 누른다. 미리보기에 배치 그림이 나온다.

`esc` 는 메인 목록으로 돌아간다.

### 저장소마다 기본 레이아웃 정하기

피커에서 정하는 방법: `alt-l` 로 레이아웃 목록을 띄운 뒤 `enter` 대신 `alt-enter` 를 누른다. 이번 윈도우에 쓰고 저장소 기본값으로도 남긴다.
(`prefix W` 에서는 `worktree` 모드일 때만 된다.)

명령으로 정하는 방법:

```sh
cd ~/dev/my-app
git config tmux-dev.layout ide-dev        # 정하기
git config --unset tmux-dev.layout        # 되돌리기 (전역 기본값을 따른다)
```

워크트리는 메인 체크아웃과 git config 를 공유하므로 모든 워크트리 윈도우에 같이 적용된다.

### 모든 저장소의 기본 레이아웃 정하기

`~/.config/tmux/tmux.conf` (이 저장소의 `home/dot_config/tmux/tmux.conf`) 에서 tmux-dev 를 불러오는 `run-shell` 줄 **앞에** 둔다.

```tmux
set -g @tmux-dev-layout ide
run-shell ~/.config/tmux/plugins/tmux-dev/tmux-dev.tmux
```

이 옵션은 키를 누를 때 읽으므로 tmux 안에서 `prefix :` 로 `set -g @tmux-dev-layout ide` 를 쳐도 바로 적용된다.

### 나만의 레이아웃 추가하기

`~/.config/tmux-dev/layouts.sh` 에 함수 하나와 등록 한 줄을 쓴다. 이 파일은 머신별이고 dotfiles 가 관리하지 않는다.

1. 파일을 만든다.

   ```bash
   # ~/.config/tmux-dev/layouts.sh
   # $1 = 윈도우 대상, $2 = 디렉토리. 패널은 "$1.<인덱스>" 로 가리킨다.
   layout_agent() {
     local win=$1 dir=$2
     layout_ide "$win" "$dir"                         # 기존 레이아웃을 재사용해도 된다
     tmux send-keys -t "$win.0" 'claude' Enter
   }
   layout_register agent "claude left / nvim right" \
   '┌──────┬──────┐
   │claude│ nvim │
   └──────┴──────┘'
   ```

2. 확인한다.

   ```sh
   tmux-dev project --layouts      # 목록에 agent 가 보이면 된다
   ```

`layout_register` 의 인자는 차례로 이름, 설명, 미리보기 그림이다. 이름은 `--layout`, `git config tmux-dev.layout`,
`@tmux-dev-layout` 에 그대로 쓴다. 패널을 셋 이상으로 나눌 때는 `split-window -P -F '#{pane_id}'` 로 패널 id 를 받아 쓴다
(나눌 때마다 인덱스가 바뀐다). 예시는 `lib/layout.sh` 의 `layout_ide-dev` 를 본다.

### dev 서버 명령 정하기

`ide-dev` 와 `nvim-dev` 의 dev 서버 패널이 실행할 명령은 다음 순서로 정한다.

1. 저장소의 `git config tmux-dev.dev`
2. `package.json` 에 `scripts.dev` 가 있으면 lockfile 에 맞는 패키지 매니저의 dev 명령

   | lockfile | 명령 |
   |---|---|
   | `pnpm-lock.yaml` | `pnpm dev` |
   | `yarn.lock` | `yarn dev` |
   | `bun.lock`, `bun.lockb` | `bun run dev` |
   | 그 밖 | `npm run dev` |

3. 둘 다 없으면 빈 셸로 남는다.

```sh
git config tmux-dev.dev 'pnpm --filter web dev'
git config tmux-dev.dev 'make serve'
```

> **주의:** 새 워크트리에는 `node_modules` 가 없어 서버가 실패할 수 있다. 설치는
> [워크트리 초기 설정](#워크트리-위치와-초기-설정-바꾸기)의 `setup` 명령으로 한다.

---

## 워크트리 위치와 초기 설정 바꾸기

워크트리 설정은 tmux 옵션이 아니라 git config 에 둔다. 셸과 Claude Code 훅처럼 tmux 밖에서도 같은 규칙을 써야 하기 때문이다.
`--global` 로 두면 모든 저장소에, 저장소 안에서 두면 그 저장소에만 적용된다.

### 위치 바꾸기

기본(`central`)은 한곳에 모은다. `sibling` 은 저장소 옆에 둔다.

```sh
# central (기본): ~/.local/share/tmux-dev/worktrees/<저장소>/<브랜치의 / 를 - 로>
git config tmux-dev.worktree.location central
git config tmux-dev.worktree.root ~/worktrees      # 모음 디렉토리 바꾸기
git config tmux-dev.worktree.name my-app           # 모음 안에서 쓸 저장소 이름

# sibling: <저장소 부모>/<저장소>.worktrees/<브랜치>
git config tmux-dev.worktree.location sibling
```

새 워크트리가 만들어질 경로를 미리 보려면:

```sh
tmux-dev worktree --path feat/login
```

### 새 워크트리에서 초기 명령 실행하기

`tmux-dev.worktree.setup` 은 새 워크트리를 만든 직후 그 안에서 한 번 실행된다.

```sh
git config tmux-dev.worktree.setup 'cp "$TMUX_WORKTREE_MAIN/.env" . && pnpm install'
```

명령은 다음 환경 변수를 받는다.

| 변수 | 값 |
|---|---|
| `TMUX_WORKTREE_MAIN` | 메인 체크아웃 경로 |
| `TMUX_WORKTREE_PATH` | 새 워크트리 경로 |
| `TMUX_WORKTREE_BRANCH` | 브랜치 이름 |

### 베이스 브랜치 바꾸기

새 브랜치는 로컬 기본 브랜치에서 갈라진다 (`origin/HEAD` 가 가리키는 이름, 없으면 `main` → `master`).
셸에서는 `--base` 로 바꾼다.

```sh
tmux-dev worktree --base develop feat-x
```

---

## 탐색에서 디렉토리 빼기

`prefix S` 와 `prefix W` 의 `directory` 모드는 홈 전체를 깊이 제한 없이 탐색한다. 숨김 디렉토리는 늘 빠진다.
그 밖에 빼고 싶은 곳은 `~/.config/tmux-dev/ignore` 에 적는다.

1. 파일을 연다. chezmoi 가 처음 한 번만 만들어 주고 이후에는 덮어쓰지 않으므로 홈의 파일을 직접 고친다.

   ```sh
   $EDITOR ~/.config/tmux-dev/ignore
   ```

2. gitignore 문법으로 패턴을 적는다.

   ```gitignore
   /Library          # 홈 바로 아래의 Library 만
   node_modules      # 어느 깊이든 이 이름
   /Downloads/**     # 그 아래만
   !/Downloads/keep  # 위에서 뺀 것 다시 넣기
   ```

3. 다음 번 피커부터 적용된다. 재시작은 필요 없다.

- 파일이 없으면 `Library` 와 `node_modules` 를 뺀다.
- 디렉토리 탐색은 각 저장소의 `.gitignore` 도 따른다. 저장소 탐색(`repository` 모드)은 따르지 않는다.
- 빠진 곳도 [경로를 직접 쳐서](#목록에-없는-경로-열기) 열 수 있다.

---

## 키와 피커 크기 바꾸기

tmux.conf 에서 `run-shell` 줄 **앞에** 사용자 옵션을 둔다.

```tmux
set -g @tmux-dev-project-key  S        # prefix S
set -g @tmux-dev-worktree-key W        # prefix W
set -g @tmux-dev-popup-size   85%,75%  # 피커 너비,높이 (% 또는 칸)
set -g @tmux-dev-layout       plain    # 기본 레이아웃
run-shell ~/.config/tmux/plugins/tmux-dev/tmux-dev.tmux
```

키 옵션은 tmux.conf 를 다시 읽어야 적용된다 (`prefix :` 에서 `source-file ~/.config/tmux/tmux.conf`).
크기와 레이아웃 옵션은 키를 누를 때 읽으므로 바로 적용된다.

---

## 셸에서 쓰기

`tmux-dev` 명령은 피커 없이 바로 대상으로 갈 때나 스크립트에서 쓴다.

```sh
tmux-dev project ~/dev/my-app              # 그 디렉토리의 세션으로 (있는 디렉토리만)
tmux-dev project --layout ide ~/dev/my-app # 새 세션이면 ide 레이아웃으로
tmux-dev worktree feat-login               # 지금 세션에 그 브랜치의 윈도우 (없으면 묻고 만든다)
tmux-dev worktree --archived               # 보관된 브랜치 목록
```

tmux 밖에서 `tmux-dev worktree <브랜치>` 를 실행하면 윈도우 없이 워크트리만 만들고(있으면 그대로) 경로를 출력한다.
없는 브랜치면 만들기 전에 `[Y/n]` 으로 묻는다. 이 질문도 표준 출력으로 나오므로, `cd "$(tmux-dev worktree …)"` 처럼
명령 치환에 쓸 때는 이미 있는 브랜치나 워크트리를 넘긴다.

모든 옵션은 [레퍼런스: 명령줄](reference.md#명령줄)과 `tmux-dev project --help`, `tmux-dev worktree --help` 를 본다.

---

## Claude Code 와 함께 쓰기

### 기본 흐름

1. 저장소 세션에서 `prefix W` → 브랜치 이름 → `alt-enter` → `enter`. 워크트리와 윈도우가 생긴다.
2. 그 윈도우의 셸에서 `claude` 를 실행한다. 에이전트는 그 워크트리 안에서 커밋하고 푸시한다.
3. PR 을 머지한다.
4. `prefix W` 에서 그 행에 `ctrl-x` → `clean up`.

에이전트를 워크트리 안에서 띄워도 잃는 것은 없다. Claude Code 의 자동 메모리와 권한 승인은 저장소 단위로 모든 워크트리가 공유한다.

새 윈도우에서 `claude` 를 자동으로 띄우려면 [나만의 레이아웃](#나만의-레이아웃-추가하기)의 `agent` 예시를 쓴다.

### 에이전트가 만드는 워크트리도 같은 위치에 두기

`claude -w`, EnterWorktree, 백그라운드 세션이 만드는 워크트리를 tmux-dev 와 같은 위치·이름·베이스로 만들려면
`~/.claude/settings.json` 에 훅을 추가한다. 이 파일은 dotfiles 밖에 있다.

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

| 훅 | 동작 |
|---|---|
| `--hook-create` | 워크트리를 만들고 경로만 출력한다. 브랜치 이름은 요청 이름 그대로, 베이스는 로컬 `main`, `setup` 명령도 실행한다 |
| `--hook-remove` | 워크트리를 지운다. 브랜치는 베이스에 모두 들어 있을 때만 보관 후 삭제한다. tmux 윈도우는 건드리지 않는다 |

격리 서브에이전트의 임시 워크트리에는 `WorktreeRemove` 가 불리지 않는다. 남은 것은 `prefix W` 의 `ctrl-t` → `ctrl-x` 로 정리한다.

전역 `~/.claude/CLAUDE.md` 에 둘 지침과 백그라운드 세션 흐름은 [`design/claude-code.md`](design/claude-code.md) 를 본다.

---

## 다른 tmux 설정에 설치하기

tmux-dev 는 tmux 플러그인 API 가 아니라 `run-shell` 한 줄로 동작한다. 이 dotfiles 없이 쓰려면:

1. `home/dot_config/tmux/plugins/tmux-dev/` 를 `~/.config/tmux/plugins/tmux-dev/` 로 복사한다.
   chezmoi 접두어를 직접 벗긴다: `executable_` 로 시작하는 파일은 접두어를 떼고 실행 권한을 준다.
2. tmux.conf 끝에 추가한다.

   ```tmux
   run-shell ~/.config/tmux/plugins/tmux-dev/tmux-dev.tmux
   ```

3. 셸에서 쓰려면 PATH 에 추가한다.

   ```sh
   export PATH="$HOME/.config/tmux/plugins/tmux-dev/bin:$PATH"
   ```

4. tmux 설정을 다시 읽는다: `tmux source-file ~/.config/tmux/tmux.conf`
