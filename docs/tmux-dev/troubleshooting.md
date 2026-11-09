# 문제 해결

증상별로 원인과 해결 방법을 정리한다. tmux-dev 의 오류는 피커가 닫힌 뒤에도 볼 수 있도록 **tmux 상태줄에 5초 동안** 나온다.
놓쳤다면 같은 동작을 셸에서 `tmux-dev project …` / `tmux-dev worktree …` 로 실행하면 표준 오류로 볼 수 있다.

## 피커가 뜨지 않는다

### `prefix S` 를 눌러도 아무 일이 없다

**원인:** 키가 묶이지 않았다. tmux.conf 의 `run-shell` 줄이 실행되지 않았거나, tmux 서버가 예전 설정을 들고 있다.

**해결:**

1. 키를 확인한다.

   ```sh
   tmux list-keys | grep tmux-dev
   ```

2. 나오지 않으면 설정을 다시 읽는다.

   ```sh
   tmux source-file ~/.config/tmux/tmux.conf
   ```

`chezmoi apply` 는 tmux.conf 나 진입 스크립트가 바뀌었을 때 살아 있는 tmux 서버에 자동으로 `source-file` 을 보낸다
(`home/.chezmoiscripts/run_onchange_after_40-reload-tmux.sh.tmpl`). 서버가 없을 때는 건너뛴다.

### 상태줄에 `tmux-dev: …` 오류가 뜨고 피커가 없다

| 메시지 | 원인 | 해결 |
|---|---|---|
| `fd is required` | fd 가 설치되지 않았다 | `brew install fd` (데비안·우분투는 `apt install fd-find`) |
| modal 관련 메시지 | 그 윈도우에 이미 modal 패널(다른 피커)이 떠 있다 | 떠 있는 피커를 `esc` 로 닫는다 |
| `unknown command: new-pane` 등 | tmux 가 3.8 보다 오래됐다 | tmux 를 올린다 (`tmux -V` 로 확인) |

## 목록에 원하는 항목이 없다

### `prefix S` 목록에 저장소나 디렉토리가 없다

**원인 1:** 숨김 디렉토리 아래에 있다 (`~/.local/...`, `~/.config/...`). 숨김 디렉토리는 늘 탐색에서 빠진다.

**원인 2:** `~/.config/tmux-dev/ignore` 의 패턴에 걸린다.

**원인 3:** `directory` 모드에서, 그 디렉토리가 어떤 저장소의 `.gitignore` 에 걸린다 (빌드 산출물 등).

**원인 4:** `repository` 모드에서, 그 디렉토리가 메인 체크아웃이 아니다. 워크트리와 서브모듈(`.git` 이 파일)은 저장소 모드에 나오지 않는다.

**해결:** 경로를 직접 친다. `/` 나 `~` 로 시작하는 검색어는 목록 밖의 경로도 연다.
자주 쓰는 곳이면 ignore 파일에서 그 패턴을 빼거나 `!패턴` 으로 다시 넣는다. ([탐색에서 디렉토리 빼기](how-to.md#탐색에서-디렉토리-빼기))

### `prefix W` 에 `worktree` 모드가 없다

**원인:** 세션 디렉토리가 git 저장소가 아니다. 판정은 키를 누른 패널의 현재 디렉토리가 아니라 **세션 디렉토리**로 한다.
예를 들어 홈에서 만든 세션의 패널에서 저장소로 `cd` 해도 `worktree` 모드는 나오지 않는다.

**해결:** `prefix S` 로 그 저장소의 세션을 열고 그 안에서 `prefix W` 를 누른다.

bare 저장소는 지원하지 않는다 (`bare repositories are not supported`).

### `merged` 마커가 기대와 다르다

| 증상 | 원인 | 해결 |
|---|---|---|
| 마커가 아예 없다 | 아직 계산 중이다. 목록을 먼저 띄우고 마커를 뒤에서 얹는다 | 잠시 기다린다 |
| PR 을 머지했는데 `merged` 가 아니다 | 백그라운드 fetch 가 실패했다 (오프라인 등) | 네트워크를 확인하고 피커를 다시 연다. 또는 `git fetch` |
| 다른 브랜치로 머지했는데 `merged` 가 아니다 | 판정 기준은 베이스 브랜치(보통 `main`)다 | 정상 동작이다. `clean up` 에서 한 번 더 묻고 정리된다 |

`ctrl-t` 를 눌렀을 때 `markers are still loading` 이 나오면 마커가 다 얹힌 뒤 다시 누른다.

## 정리가 안 된다

| 메시지·증상 | 원인 | 해결 |
|---|---|---|
| 벨과 함께 거절 | 메인 체크아웃, 베이스 브랜치, 원격 브랜치, locked 워크트리 | 정상 동작이다. 원격 브랜치는 GitHub 등에서 지운다 |
| `dirty N` 과 함께 실패 | 커밋하지 않은 변경이 있다 | 그 워크트리에서 커밋하거나 `git stash`, `git restore` 후 다시 한다 |
| `this window closes when you leave the picker` | 정리하는 윈도우 안에서 피커를 띄웠다 | 정상 동작이다. 피커를 닫으면 윈도우도 닫힌다 |
| 정리한 브랜치가 필요하다 | – | [지운 브랜치 되살리기](how-to.md#지운-브랜치-되살리기) |

## 새 윈도우·세션의 배치가 기대와 다르다

### 새 윈도우가 셸 하나로만 열린다

**원인:** 기본 레이아웃이 `plain`(셸 하나)이다.

**해결:** 이번만 다르게 열려면 피커에서 `alt-l`. 저장소마다 정하려면 `git config tmux-dev.layout ide`, 전체를 바꾸려면 tmux.conf 에
`set -g @tmux-dev-layout ide`. ([레이아웃 바꾸기](how-to.md#레이아웃-바꾸기))

### 전역 레이아웃을 바꿨는데 어떤 저장소에서는 적용되지 않는다

**원인:** 그 저장소에 `git config tmux-dev.layout` 이 있다. 저장소 값이 전역 값보다 앞선다.

**해결:**

```sh
git config --get tmux-dev.layout      # 확인
git config --unset tmux-dev.layout    # 지우기
```

### 이미 열린 윈도우의 배치가 바뀌지 않는다

**원인:** 레이아웃은 윈도우를 **만들 때 한 번만** 적용된다.

**해결:** 윈도우를 닫고 다시 연다. 패널 크기 배치만 바꾸려면 tmux 순정 `prefix Space` 를 쓴다.

### dev 서버 패널이 빈 셸이거나 바로 실패한다

| 증상 | 원인 | 해결 |
|---|---|---|
| 빈 셸 | `tmux-dev.dev` 가 없고 `package.json` 에 `scripts.dev` 도 없다 | `git config tmux-dev.dev '<명령>'` |
| 실행 후 바로 실패 | 새 워크트리에 의존성이 없다 (`node_modules` 등) | `git config tmux-dev.worktree.setup 'pnpm install'` |
| 포트 충돌 | 여러 워크트리에서 동시에 켰다 | Vite·Next 는 다음 빈 포트로 비켜 간다. 다른 도구는 포트를 직접 지정한다 |

## 그 밖

### 키나 크기 옵션을 바꿨는데 적용되지 않는다

- 옵션은 tmux.conf 에서 `run-shell .../tmux-dev.tmux` 줄 **앞에** 있어야 한다.
- 키 옵션(`@tmux-dev-project-key`, `@tmux-dev-worktree-key`)은 tmux.conf 를 다시 읽어야 적용된다.
- 크기와 레이아웃 옵션은 키를 누를 때 읽으므로 바로 적용된다.

### 셸에서 `tmux-dev: command not found`

`~/.config/tmux/plugins/tmux-dev/bin` 이 PATH 에 없다. 새 셸을 열거나 `rc.sh` 를 다시 읽는다. dotfiles 없이 설치했다면
[다른 tmux 설정에 설치하기](how-to.md#다른-tmux-설정에-설치하기)의 3단계를 한다.

### 프로젝트별 nvim·mise 설정이 적용되지 않는다

mise 와 lazy.nvim 의 프로젝트 설정(`mise.local.toml`, `.lazy.lua`)은 **그 디렉토리에서 시작한 프로세스**에만 적용된다.
tmux-dev 는 새 세션·윈도우의 셸을 프로젝트(워크트리) 디렉토리에서 시작하므로 그 셸에서 `nvim` 을 띄우면 적용된다.
다른 디렉토리에서 연 nvim 안에서 `:cd` 로 옮기면 적용되지 않는다. 자세한 내용은 [`docs/tool-scope.md`](../tool-scope.md) 를 본다.

## 문제를 직접 살펴보기

| 명령 | 보여 주는 것 |
|---|---|
| `tmux-dev project --list repo` | `prefix S` 저장소 모드의 후보 |
| `tmux-dev worktree --list worktree --marks` | `prefix W` 후보와 마커 |
| `tmux-dev worktree --path <브랜치>` | 워크트리가 만들어질 경로 |
| `tmux-dev project --layouts` | 쓸 수 있는 레이아웃 (개인 레이아웃 포함) |
| `tmux show -gv @tmux-dev-layout` | 전역 기본 레이아웃 (비어 있으면 `plain`) |
| `tmux show -v @tmux-dev-path` | 지금 세션의 세션 디렉토리 |
| `tmux show -wv @worktree` | 지금 윈도우의 워크트리 경로 |
