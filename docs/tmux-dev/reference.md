# 레퍼런스

tmux-dev 의 키, 명령줄, 설정, 파일, 화면 표시를 찾아보는 문서다. 사용 절차는 [작업별 안내](how-to.md)를 본다.

- [tmux 키](#tmux-키)
- [키](#키)
  - [공통 키](#공통-키)
  - [prefix S 피커](#prefix-s-피커)
  - [prefix W 피커](#prefix-w-피커)
  - [겹쳐 뜨는 목록](#겹쳐-뜨는-목록)
- [명령줄](#명령줄)
- [설정](#설정)
  - [tmux 사용자 옵션](#tmux-사용자-옵션)
  - [git config](#git-config)
  - [환경 변수](#환경-변수)
- [레이아웃](#레이아웃)
- [파일 위치](#파일-위치)
- [목록 표시](#목록-표시)
- [tmux 객체에 붙이는 옵션](#tmux-객체에-붙이는-옵션)

---

## tmux 키

| 키 | 동작 | 순정 짝 |
|---|---|---|
| `prefix S` | 디렉토리 → 세션 피커 | `prefix s` (세션 목록) |
| `prefix W` | 지금 세션에 윈도우를 여는 피커 | `prefix w` (윈도우 트리) |

키는 [`@tmux-dev-project-key`, `@tmux-dev-worktree-key`](#tmux-사용자-옵션)로 바꾼다. 피커가 떠 있는 동안에는 prefix 를 포함한
모든 키가 피커로 가므로 피커를 겹쳐 띄울 수 없다.

## 키

피커는 fzf 다. 아래에 없는 키(커서 이동, 검색어 편집 등)는 fzf 기본 동작을 따른다. 피커 안에서 `alt-h` 를 누르면 키 안내가 미리보기 자리에 나온다.

### 공통 키

| 키 | 동작 |
|---|---|
| `enter` | 커서 항목을 연다 |
| `alt-enter` | 친 이름으로 새로 만든다 |
| `alt-l` | 레이아웃을 골라서 연다 |
| `alt-m` / `alt-n` | 다음 / 이전 모드. 맨 위의 모드 이름을 클릭해도 된다 |
| `alt-p` | 미리보기 위치: 오른쪽 → 아래 → 숨김 |
| `alt-h` | 키 안내 열기 / 닫기 |
| `esc` | 닫기. 겹쳐 뜬 목록에서는 한 단계 뒤로, 확인 중에는 취소 |
| `ctrl-c` | 언제나 닫기 |

### prefix S 피커

| 키 | 동작 |
|---|---|
| `enter` | 커서 항목의 세션으로 (없으면 만든다). 걸리는 항목이 없으면 벨과 안내. 경로를 쳤고 그 경로가 있으면 연다 |
| `alt-enter` | 친 이름으로 새 디렉토리(`repository` 모드는 `git init` 까지) → [위치 목록](#겹쳐-뜨는-목록). 경로를 쳤으면 그 자리에 바로 |
| `ctrl-]` | 커서 항목의 경로를 검색어에 채운다 |
| 더블클릭 | `enter` 와 같다 |

모드: `repository`(메인 체크아웃만) ↔ `directory`(모든 디렉토리).

### prefix W 피커

| 키 | 모드 | 동작 |
|---|---|---|
| `enter` | 전부 | 커서 항목의 윈도우로. 없으면 만든다. 워크트리를 새로 만들어야 하면 푸터에서 먼저 묻는다 |
| `alt-enter` | `worktree` | 친 이름으로 베이스에서 새 브랜치 + 워크트리 (푸터에서 묻는다) |
| `alt-enter` | `subdirectory`, `directory` | 친 이름으로 새 디렉토리 → 위치 목록 |
| `ctrl-x` | `worktree` | 커서 항목 정리. 선택이 있으면 선택 전체 |
| `tab` / `shift-tab` | `worktree` | 선택 / 해제 (정리에만 쓴다) |
| `ctrl-t` | `worktree` | 선택이 없으면 `merged` 항목 모두 선택, 있으면 모두 해제 |
| `ctrl-]` | `subdirectory`, `directory` | 커서 항목의 경로를 검색어에 채운다 |

푸터에서 묻는 중일 때:

| 키 | 동작 |
|---|---|
| `enter` | 실행 |
| `alt-l` | 레이아웃을 골라 실행 (만들기일 때만) |
| `esc` | 취소. 커서를 옮기거나 글자를 쳐도 취소된다 |

### 겹쳐 뜨는 목록

| 목록 | 여는 키 | `enter` | `alt-enter` | `alt-l` | `esc` |
|---|---|---|---|---|---|
| 레이아웃 | `alt-l` | 이번만 이 레이아웃 | 이번에 쓰고 저장소 기본값으로 저장 | – | 돌아가기 |
| 위치 | `alt-enter` | 여기에 만들고 열기 | – | 레이아웃 골라 만들기 | 돌아가기 |
| 정리 | `ctrl-x` | 고른 방법으로 정리 | – | – | 돌아가기 |

정리 목록의 항목:

| 항목 | 하는 일 |
|---|---|
| `clean up` | 윈도우 닫기 → 워크트리 제거 → 브랜치 보관 → 브랜치 삭제. 머지 안 됐으면 한 번 더 묻는다 |
| `keep branch` | 윈도우 닫기 → 워크트리 제거. 브랜치는 남긴다 |
| `clean up N` / `keep branches` | 선택이 있을 때. 정리할 수 없는 항목은 건너뛰고 이유별 개수를 보여 준다 |

---

## 명령줄

`tmux-dev` 는 `~/.config/tmux/plugins/tmux-dev/bin/tmux-dev` 다.

```
tmux-dev project  [옵션] [디렉토리]
tmux-dev worktree [옵션] [브랜치 | 워크트리 경로 | 디렉토리]
tmux-dev open <project|worktree> <클라이언트> <패널> <디렉토리>
tmux-dev help
```

### tmux-dev project

| 형식 | 동작 |
|---|---|
| `tmux-dev project` | 피커 |
| `tmux-dev project <디렉토리>` | 그 디렉토리의 세션으로. 있는 디렉토리만 받는다. 최근 기록에 남기지 않는다 |
| `--layout <이름>` | 새 세션의 레이아웃 |
| `--layouts` | 레이아웃 목록 출력 |
| `--list [repo\|dir\|loc]` | 후보 목록만 출력 (디버그) |
| `--help` | 도움말 |

### tmux-dev worktree

| 형식 | 동작 |
|---|---|
| `tmux-dev worktree` | 피커 |
| `tmux-dev worktree <브랜치>` | 그 브랜치의 윈도우로. 브랜치·워크트리가 없으면 묻고 만든다 |
| `tmux-dev worktree <워크트리 경로>` | 그 워크트리의 윈도우로 |
| `tmux-dev worktree <디렉토리>` | 그 디렉토리의 윈도우로 (tmux 안에서만) |
| `--base <ref>` | 새 브랜치의 베이스. 기본: 로컬 기본 브랜치 |
| `--layout <이름>` | 새 윈도우의 레이아웃 |
| `--layouts` | 레이아웃 목록 출력 |
| `-t <세션>` | 윈도우를 만들 세션. 기본: 지금 클라이언트의 세션 |
| `--path <브랜치>` | 그 브랜치의 워크트리가 만들어질 경로만 출력 |
| `--list [worktree\|subdirectory\|directory] [--marks]` | 후보 목록만 출력 (디버그) |
| `--archived` | 보관된 브랜치 목록 |
| `--hook-create` | Claude Code `WorktreeCreate` 훅. stdin JSON 으로 워크트리를 만들고 경로를 출력 |
| `--hook-remove` | Claude Code `WorktreeRemove` 훅. 워크트리를 지우고, 머지된 브랜치만 보관 후 삭제 |
| `--help` | 도움말 |

tmux 밖에서 실행하면 윈도우를 만들지 않고 워크트리만 만든 뒤 경로를 출력한다.

### tmux-dev open

`prefix S`·`prefix W` 가 `run-shell` 로 부르는 내부 런처다. 피커를 modal floating pane 으로 화면 가운데에 띄운다. 직접 부를 일은 없다.

---

## 설정

### tmux 사용자 옵션

tmux.conf 에서 `run-shell .../tmux-dev.tmux` 줄 **앞에** 둔다.

| 옵션 | 기본값 | 뜻 | 적용 시점 |
|---|---|---|---|
| `@tmux-dev-project-key` | `S` | `prefix S` 의 키 | tmux.conf 다시 읽을 때 |
| `@tmux-dev-worktree-key` | `W` | `prefix W` 의 키 | tmux.conf 다시 읽을 때 |
| `@tmux-dev-popup-size` | `85%,75%` | 피커 너비,높이 (`%` 또는 칸) | 키를 누를 때 |
| `@tmux-dev-layout` | `plain` | 전역 기본 레이아웃 | 키를 누를 때 |
| `@float-style` | `popup-style` 값 | 피커 배경·글자 스타일 (tmux.conf 공용 옵션) | 키를 누를 때 |

### git config

전역(`--global`)과 저장소별 값 모두 된다. 워크트리는 메인 체크아웃과 값을 공유한다.

| 키 | 기본값 | 뜻 |
|---|---|---|
| `tmux-dev.layout` | (없음) | 저장소 기본 레이아웃. 전역 `@tmux-dev-layout` 보다 앞선다 |
| `tmux-dev.dev` | (없음) | dev 서버 패널에서 실행할 명령 |
| `tmux-dev.worktree.location` | `central` | `central` 또는 `sibling` |
| `tmux-dev.worktree.root` | `$XDG_DATA_HOME/tmux-dev/worktrees` | `central` 의 모음 디렉토리 |
| `tmux-dev.worktree.name` | 메인 체크아웃의 디렉토리 이름 | 모음 안에서 이 저장소가 쓰는 이름 |
| `tmux-dev.worktree.setup` | (없음) | 새 워크트리 안에서 한 번 실행할 셸 명령 |

워크트리 경로 규칙:

| `location` | 경로 |
|---|---|
| `central` | `<root>/<name>/<브랜치의 / 를 - 로>` |
| `sibling` | `<저장소 부모>/<name>.worktrees/<브랜치의 / 를 - 로>` |

`tmux-dev.worktree.setup` 이 받는 환경 변수: `TMUX_WORKTREE_MAIN`, `TMUX_WORKTREE_PATH`, `TMUX_WORKTREE_BRANCH`.

### 환경 변수

주로 시험용이다. 평소에는 바꿀 필요가 없다.

| 변수 | 기본값 | 뜻 |
|---|---|---|
| `TMUX_DEV_LAYOUT` | `plain` | 전역 기본 레이아웃. 런처가 `@tmux-dev-layout` 값으로 채운다 |
| `TMUX_DEV_SCAN_ROOT` | `$HOME` | 디렉토리 탐색 시작점 |
| `TMUX_DEV_IGNORE` | `$XDG_CONFIG_HOME/tmux-dev/ignore` | 탐색 제외 파일 |
| `TMUX_DEV_HISTORY` | `$XDG_STATE_HOME/tmux-dev/history` | `prefix S` 최근 기록 |
| `TMUX_DEV_WORKTREES` | `$XDG_DATA_HOME/tmux-dev/worktrees` | 워크트리 모음 디렉토리 |
| `TMUX_DEV_CACHE` | `$XDG_CACHE_HOME/tmux-dev` | 머지 판정 캐시 |

---

## 레이아웃

| 이름 | 배치 | 포커스 |
|---|---|---|
| `plain` | 셸 하나 **(기본값)** | 셸 |
| `ide` | 왼쪽 셸 / 오른쪽 nvim | 셸 |
| `ide-dev` | 왼쪽 셸 / 오른쪽 위 nvim, 오른쪽 아래 dev 서버 (30%) | 셸 |
| `nvim` | nvim 하나 | nvim |
| `nvim-dev` | 위 nvim / 아래 dev 서버 (25%) | nvim |

```
plain                  ide                    ide-dev                nvim-dev
┌──────────────────┐   ┌─────────┬────────┐   ┌─────────┬────────┐   ┌──────────────────┐
│ shell            │   │ shell   │ nvim   │   │ shell   │ nvim   │   │ nvim             │
│                  │   │         │        │   │         ├────────┤   ├──────────────────┤
│                  │   │         │        │   │         │ dev    │   │ dev server       │
└──────────────────┘   └─────────┴────────┘   └─────────┴────────┘   └──────────────────┘
```

피커의 레이아웃 목록(`alt-l`)과 `tmux-dev project --layouts` 로도 볼 수 있다.

결정 순서 (앞이 이긴다):

| 순서 | 출처 | 범위 |
|---|---|---|
| 1 | 피커 `alt-l`, 명령줄 `--layout` | 이번 한 번 |
| 2 | `git config tmux-dev.layout` | 저장소 |
| 3 | tmux 옵션 `@tmux-dev-layout` | 전역 |
| 4 | `plain` | 내장 |

개인 레이아웃은 `~/.config/tmux-dev/layouts.sh` 에서 `layout_<이름>()` 함수와 `layout_register <이름> <설명> <그림>` 으로 추가한다.
([나만의 레이아웃 추가하기](how-to.md#나만의-레이아웃-추가하기))

---

## 파일 위치

XDG 기본 디렉토리를 종류별로 쓴다.

| 종류 | 경로 | 내용 | dotfiles 관리 |
|---|---|---|---|
| 프로그램 | `~/.config/tmux/plugins/tmux-dev/` | 스크립트와 설계 문서 | 함 |
| 설정 | `~/.config/tmux-dev/ignore` | 탐색 제외 패턴 (gitignore 문법) | 처음 한 번만 만든다 |
| 설정 | `~/.config/tmux-dev/layouts.sh` | 개인 레이아웃 | 안 함 |
| 상태 | `~/.local/state/tmux-dev/history` | `prefix S` 로 고른 곳 (최근 순, 500줄) | 안 함 |
| 상태 | `~/.local/state/tmux-dev/windows` | `prefix W` 로 연 디렉토리 | 안 함 |
| 상태 | `~/.local/state/tmux-dev/parents` | 위치 목록으로 무언가를 만든 곳 | 안 함 |
| 데이터 | `~/.local/share/tmux-dev/worktrees/<저장소>/<브랜치>` | 워크트리 (`central`) | 안 함 |
| 캐시 | `~/.cache/tmux-dev/{merged,patchids,prs}/` | 머지 판정 결과, main 쪽 patch-id 집합, 머지된 GitHub PR 목록(저장소당 파일 하나). 지워도 다시 계산한다 | 안 함 |

저장소 안 소스 위치:

| 경로 | 내용 |
|---|---|
| `home/dot_config/tmux/plugins/tmux-dev/executable_tmux-dev.tmux` | 진입 스크립트 (키 등록) |
| `home/dot_config/tmux/plugins/tmux-dev/bin/executable_tmux-dev` | 명령 진입점 |
| `home/dot_config/tmux/plugins/tmux-dev/libexec/` | 서브커맨드 (`project`, `worktree`, `open`) |
| `home/dot_config/tmux/plugins/tmux-dev/lib/` | 공용 (`common.sh`, `dirs.sh`, `layout.sh`, `picker.sh`) |
| `home/dot_config/tmux-dev/create_ignore` | `ignore` 파일의 초기 내용 |

---

## 목록 표시

### prefix S

| 표시 | 뜻 |
|---|---|
| `●` + 세션 이름 | 열린 세션 |
| `◷` | 피커로 최근 고른 곳 |
| 청록색 이름 | git 브랜치 |

목록 순서: 열린 세션 → 최근 고른 곳 → 홈 탐색 결과. 같은 경로는 한 번만 나온다.

### prefix W

| 표시 | 뜻 |
|---|---|
| `●N` | N 번 윈도우가 열려 있다 |
| `◷` | 최근 연 것 |
| `⌂` | 세션 디렉토리 자신 (`subdirectory` 모드) |
| `merged` | 변경이 베이스 브랜치에 모두 들어 있다. 흐리게 표시된다. 뒤 글자는 판정 방법: 없음 조상(ff·merge commit) · `·r` rebase · `·s` squash(diff patch-id) · `·t` merge-tree · `·p` GitHub PR(`gh` 필요) |
| `new` | 브랜치 끝이 베이스 끝과 같다 (아직 커밋이 없다) |
| `+N` | 베이스에 없는 커밋 N개 |
| `dirty N` | 커밋하지 않은 변경 N개 |
| `missing` | 워크트리 디렉토리가 사라졌다 (`enter` 로 정리 후 다시 만든다) |
| `locked` | `git worktree lock` 된 워크트리 |
| `5m 3h 2d 3w 4mo 2y` | 마지막 커밋 이후 시간 |
| `(branch)` | 워크트리 없는 로컬 브랜치 |
| `(remote)` | 원격 브랜치. 같은 이름의 로컬 브랜치가 있으면 숨긴다 |
| `claude:x` | Claude Code 기본 위치(`<메인>/.claude/worktrees/x`)의 워크트리 |

`worktree` 모드 목록 순서: 열린 윈도우 → 최근 연 것 → 진행 중 워크트리 → 끝난 워크트리(`merged`) → 로컬 브랜치 → 원격 브랜치.
각 묶음 안은 최근 커밋 순이다. 브랜치 자신의 업스트림 대비 상태(푸시 안 한 커밋 등)는 미리보기에 나온다.

---

## tmux 객체에 붙이는 옵션

tmux-dev 는 만든 세션과 윈도우에 사용자 옵션을 붙여 나중에 다시 찾는다. 순정 tmux 명령으로 만든 세션·윈도우도 경로로 찾는다.

| 옵션 | 대상 | 값 | 붙이는 곳 |
|---|---|---|---|
| `@tmux-dev-path` | 세션 | 세션 디렉토리의 실제 경로 | `prefix S` 가 세션을 만들 때 |
| `@worktree` | 윈도우 | 워크트리 경로 | 워크트리 윈도우를 만들 때. 저장소 세션의 첫 윈도우 |
| `@dir` | 윈도우 | 디렉토리 경로 | `subdirectory`·`directory` 모드로 윈도우를 만들 때 |
