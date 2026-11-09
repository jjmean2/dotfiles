# 시작하기

이 튜토리얼은 tmux-dev 의 기본 흐름을 한 바퀴 따라 한다. 끝나면 다음을 할 수 있다.

- `prefix S` 로 프로젝트 세션을 연다
- `prefix W` 로 브랜치용 워크트리와 윈도우를 만든다
- 다 쓴 워크트리를 `ctrl-x` 로 정리한다

소요 시간: 약 10분.

## 준비

### 필요한 것

| 항목 | 조건 | 확인 명령 |
|---|---|---|
| tmux | 3.8 이상 (floating pane, modal pane 지원) | `tmux -V` |
| fzf | 0.74 기준으로 만들고 시험했다 | `fzf --version` |
| fd | 데비안·우분투의 `fdfind` 도 된다 | `fd --version` |
| git | 워크트리 기능을 쓰려면 필요 | `git --version` |
| jq | 선택. 없으면 `package.json` 판정을 grep 으로 한다 | `jq --version` |

fzf 와 fd 는 이 저장소의 `home/.chezmoidata/packages.yaml` 에 들어 있어 `chezmoi apply` 로 설치된다.

### 설치 확인

이 dotfiles 를 적용했다면 tmux-dev 는 이미 설치되어 있다. 다음 두 가지로 확인한다.

1. tmux 안에서 키가 묶였는지 본다.

   ```sh
   tmux list-keys | grep tmux-dev
   ```

   `S` 와 `W` 두 줄이 나오면 된다.

2. 셸에서 명령을 찾을 수 있는지 본다.

   ```sh
   tmux-dev help
   ```

   도움말이 나오면 된다. `command not found` 면 새 셸을 열거나 `source ~/.zshrc` 한다
   (`~/.config/tmux/plugins/tmux-dev/bin` 이 PATH 에 들어간다).

dotfiles 없이 설치하는 방법은 [작업별 안내의 "다른 tmux 설정에 설치하기"](how-to.md#다른-tmux-설정에-설치하기)를 본다.

## 1단계: 프로젝트 세션 열기

1. tmux 안에서 `prefix S` 를 누른다 (prefix 는 기본 `ctrl-b`).

   화면 가운데에 피커가 뜬다. 맨 위에 모드 탭 `repository  directory` 가 있고, 목록에는 홈 아래의 git 저장소가 나온다.

   ```
   ╭─ open session ───────────────────────────────╮
   │   repository  directory                       │
   │ > dotf                                        │
   │   ~/dev/jwlee/dotfiles  ● dotfiles main       │  ← ● 열린 세션
   │   ~/dev/jwlee/notes  ◷                        │  ← ◷ 최근 고른 곳
   │   ~/dev/opensources/ghostty  main             │
   ╰───────────────────────────────────────────────╯
   ```

2. 저장소 이름 일부를 친다. 퍼지 검색으로 목록이 줄어든다.
3. 원하는 저장소에 커서를 두고 `enter` 를 누른다.

**결과:** 그 저장소 이름의 세션이 생기고 그 세션으로 전환된다. 이미 그 경로의 세션이 있으면 새로 만들지 않고 전환만 한다.
새 세션의 첫 윈도우는 셸 하나다.

> **참고:** 저장소가 아닌 디렉토리를 열려면 `alt-m` 으로 `directory` 모드로 바꾼다. 맨 위의 모드 이름을 클릭해도 된다.

## 2단계: 브랜치용 워크트리 만들기

1단계에서 연 저장소 세션 안에 있다고 가정한다.

1. `prefix W` 를 누른다.

   `worktree` 모드로 피커가 뜬다. 목록에는 워크트리, 로컬 브랜치, 원격 브랜치가 차례로 나온다.

2. 새 브랜치 이름을 친다. 예: `try-tmux-dev`
3. `alt-enter` 를 누른다.

   피커 아래쪽 푸터에 확인 문구가 뜬다. 베이스 브랜치(보통 `main`)에서 새 브랜치를 만든다는 내용이다.

4. `enter` 로 확인한다.

**결과:**

- `~/.local/share/tmux-dev/worktrees/<저장소>/try-tmux-dev` 에 워크트리가 생긴다.
- 지금 세션에 `try-tmux-dev` 라는 윈도우가 생기고 그리로 이동한다. 윈도우의 셸은 워크트리 디렉토리에서 시작한다.

다시 `prefix W` 를 누르면 그 행 앞에 `●N`(N 번 윈도우가 열려 있음)이 붙어 있다. 그 행에서 `enter` 를 누르면 윈도우로 간다.

> **참고:** 이미 있는 브랜치는 이름을 치는 대신 목록의 그 행에서 `enter` 를 누른다. 워크트리가 없으면 푸터에서 한 번 묻고 만든다.

## 3단계: 작업하고 머지하기

새 윈도우에서 평소처럼 작업하고 커밋한다. 이 단계는 tmux-dev 와 상관없다.

```sh
echo test > note.txt && git add note.txt && git commit -m "try tmux-dev"
```

머지는 평소 방식대로 한다. 로컬에서 `main` 에 머지하거나 GitHub 에서 PR 을 머지한다. 이 튜토리얼에서는 머지하지 않고
넘어가도 된다. 머지하지 않은 브랜치도 4단계에서 정리할 수 있다 (한 번 더 묻는다).

## 4단계: 워크트리 정리하기

1. `prefix W` 를 누른다.

   머지된 브랜치에는 `merged` 마커가 붙는다. 머지하지 않았으면 `+1`(베이스에 없는 커밋 1개)이 붙는다.

2. `try-tmux-dev` 행에 커서를 두고 `ctrl-x` 를 누른다.

   정리 방법을 고르는 목록이 겹쳐 뜬다. 미리보기에 무엇을 할지(닫을 윈도우, 지울 경로, 보관 ref 이름)가 나온다.

   | 항목 | 하는 일 |
   |---|---|
   | `clean up` | 윈도우 닫기 → 워크트리 제거 → 브랜치 보관 → 브랜치 삭제 |
   | `keep branch` | 윈도우 닫기 → 워크트리 제거. 브랜치는 남긴다 |

3. `clean up` 에서 `enter` 를 누른다. 머지되지 않은 브랜치면 푸터에서 한 번 더 묻는다. 다시 `enter` 로 확인한다.

**결과:** 윈도우가 닫히고 워크트리가 지워진다. 브랜치는 `refs/archive/<날짜>/try-tmux-dev` 에 보관된 뒤 삭제된다.
푸터에 보관 ref 와 복구 명령이 나온다. 피커는 열린 채로 남으므로 이어서 다른 항목을 정리할 수 있다. `esc` 로 닫는다.

보관한 브랜치를 되살리려면:

```sh
tmux-dev worktree --archived                                     # 보관 목록
git branch try-tmux-dev refs/archive/2026-11-09/try-tmux-dev     # 복구
```

## 다음 단계

- 새 윈도우를 셸 | nvim 같은 배치로 열고 싶다 → [레이아웃 바꾸기](how-to.md#레이아웃-바꾸기)
- 에이전트를 워크트리마다 띄우고 싶다 → [Claude Code 와 함께 쓰기](how-to.md#claude-code-와-함께-쓰기)
- 피커의 모든 키를 보고 싶다 → [레퍼런스: 키](reference.md#키) 또는 피커 안에서 `alt-h`
