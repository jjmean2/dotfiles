# prefix W 윈도우 피커: 멘탈 모델과 설계

`tmux-dev worktree` (prefix W). 2026-11-08~09 에 다시 짰다 (4단계: PR #63 공용 lib, #64 새 피커, #65 정리, 그리고 pane 전환).
prefix S(`session-picker.md`)와 같은 기준이고 공용 부분은 `lib/picker.sh` 를 쓴다. 이 문서는 W 에만 있는 것을 적는다.

## 한 줄 모델

> **W 는 지금 세션에 윈도우를 연다.** 출처는 세 가지 모드이고, 세션이 저장소면 워크트리 모드가 먼저 나온다. 정리는 워크트리만.

```
tmux 세션 (세션 디렉토리 = @tmux-dev-path, 없으면 session_path)
 ├─ 윈도우 "main"     @worktree=<메인>     ← worktree 모드: 워크트리 = 브랜치 = 윈도우
 ├─ 윈도우 "feat-a"   @worktree=<워크트리>
 ├─ 윈도우 "lib"      @dir=<세션 디렉토리 아래>   ← subdirectory 모드
 └─ 윈도우 "notes"    @dir=<홈 아래 아무 곳>     ← directory 모드
```

- tmux 를 대체하지 않고 얹는다. `prefix c` 의 보통 윈도우, 순정 `tmux new -c <워크트리>` 모두 정상이다.
- 순정 대응: `git worktree add -b <브랜치> <경로> main` + `tmux new-window -n <브랜치> -c <경로>`.
- **저장소 판정은 세션 디렉토리다.** 패널의 cwd 로 하면 같은 세션에서도 어느 패널에서 눌렀느냐에 따라 모드가 달라진다.
  세션 디렉토리가 워크트리면 그 메인 저장소로 정규화된다(`git rev-parse --git-common-dir`).

## 모드

| 탭 | 켜지는 조건 | 후보 | 윈도우 표시 |
|---|---|---|---|
| `worktree` | 세션 디렉토리가 git 저장소 | 워크트리 → 로컬 브랜치 → `origin/*` | `@worktree <경로>`, 이름 = 브랜치 |
| `subdirectory` | 항상 | 세션 디렉토리 아래 (`⌂` = 세션 디렉토리 자체) | `@dir <경로>`, 이름 = 디렉토리 이름 |
| `directory` | 항상 | 홈 전체 (S 의 디렉토리 모드와 같은 탐색) | `@dir <경로>` |

- 시작 모드는 저장소면 `worktree`, 아니면 `subdirectory`. tab·shift-tab 이나 헤더의 모드 이름 클릭으로 바꾼다.
- 탭 이름은 온전한 영어 단어다(누를 자리가 넓게, fzf 의 여러 바이트 글자 클릭 버그를 피해서. session-picker.md 화면 절).
- 창을 찾는 범위는 지금 세션 하나다.

## 화면

```
╭─ open window · dotfiles ─────────────────────────────────────────╮  ← 라벨 = 화면 제목 + 세션 이름
│     worktree  subdirectory  directory  │ feat-x                   │  ← 헤더 탭 (클릭 전환)
│ ╭──────────────────────────────────╮  │ ~/.local/…/feat-x        │
│ │ >                                │  │ merged into origin/main  │  ← 미리보기: 상태·판정·로그
│ ╰──────────────────────────────────╯  │ a1b2c3 fix: ...          │
│ ╭──────────────────────────────────╮  │                          │
│ │ main      ~/dev/jwlee/dotfiles  ●0                            │  ← 열린 윈도우 (창 번호 순)
│ │ feat-x    ~/.local/…/feat-x     ●3 merged                     │
│ │ fix-y     ~/.local/…/fix-y      ◷ dirty [ahead 2]             │  ← 최근 고른 것
│ │ spike     (branch)                                            │  ← 로컬 브랜치 (최근 커밋 순)
│ │ origin/pr-12  (remote)                                        │  ← 원격 (같은 이름 로컬 있으면 숨김)
│ ╰──────────────────────────────────╯  │                          │
│ ─────────────────────────────────────│                          │
│     enter open · alt-enter new branch · alt-l layout · ctrl-x …  │  ← 푸터: 안내 · 확인 · 결과
╰──────────────────────────────────────────────────────────────────╯
```

- 행은 5칸 `"<이름>\t<표시>\t<종류>\t<경로>\t<브랜치>"`. fzf 는 1·2칸을 보이고 1칸만 검색한다. 종류는
  `worktree | prunable | branch | remote | dir`.
- 마커: `●N` 열린 창 · `◷` 최근 · `dirty` · `merged` · `[ahead n, behind m]` · `missing`(디렉토리가 사라진 워크트리) · `locked`.
  마커 없는 목록을 먼저 그리고 fzf 의 `load` 이벤트에서 `--marks` 로 바꿔 끼운다(행마다 git 이 돌아 비싸다).

## worktree 모드의 동작

| 행 | Enter | alt-l | ctrl-x |
|---|---|---|---|
| 워크트리, 창 열림 | 그 창으로 | 그 창으로 | 정리: 창 → 워크트리 → 백업 → 브랜치 |
| 워크트리, 창 없음 | 창 만들기 | 레이아웃 골라 창 만들기 | 정리 (창 단계 없음) |
| 메인 체크아웃 | 메인 창으로 (없으면 만들기) | 레이아웃 골라 | 하지 않음 |
| missing | **묻고** prune 후 다시 만들기 | (묻는 중 alt-l) | prune → 백업 → 브랜치 |
| 로컬 브랜치 | **묻고** 워크트리 + 창 | (묻는 중 alt-l) | 백업 → 브랜치 |
| 원격 브랜치 | **묻고** 추적 브랜치 + 워크트리 + 창 | (묻는 중 alt-l) | 하지 않음 |
| alt-enter (친 이름) | **묻고** 베이스에서 새 브랜치 + 워크트리 + 창 | (묻는 중 alt-l) | – |

**만들기는 언제나 푸터에서 먼저 묻는다** (S 의 "질문은 목록을 유지한 채 푸터에서"). 상태 `target`(무엇을)·`confirm`(묻는 중)·
`op`(create | clean | clean2). 묻는 동안 enter 는 실행, alt-l 은 레이아웃 고른 뒤 실행(create 일 때만), esc 는 취소.
커서를 옮기거나(묻는 동안만 `focus` 이벤트를 묶는다) 글자를 쳐도 취소된다.

**여는 동작은 "피커는 결정만"** 이다. 결정 `"<종류>US<경로>US<브랜치>US<레이아웃>US<save>US<만들기>US<부모>"` 를 적고
fzf 를 끝낸 뒤 `apply_decision` 이 만들고 연다(`CONFIRMED=1` 이라 셸 호출용 질문을 건너뛴다). 정리는 반대로 피커 안에서 끝난다
(피커를 계속 쓰려고).

## 디렉토리 모드

- 목록: 이 세션에 열린 창의 디렉토리(`●N`) → 최근(`◷`) → (`⌂` 세션 디렉토리) → 탐색. 경로가 같은 행은 앞의 것만.
- Enter: `@dir` 창이 있으면 그리로, 없으면 만들기. 고른 디렉토리가 이 저장소의 워크트리면 워크트리 창으로 연다.
- 새로 만들기: S 와 같은 위치 피커(alt-enter, 경로를 치면 그 자리에). subdirectory 에서는 위치 후보도 세션 디렉토리 아래로
  (`lib/picker.sh` 의 `LOC_ROOT`, 탐색 시작점은 `SCAN_ROOT`). 탐색은 시작점 아래만 나오므로 시작점 자체를 `⌂` 행으로 넣는다.
- 정리는 없다(디렉토리는 지우지 않는다).

## 정리 (ctrl-x)

```
ctrl-x ─▶ 검사 ─┬─ 메인 / 베이스 브랜치 / 원격 / locked ─▶ 벨 + 안내
                ├─ dirty ─▶ 변경 수와 함께 실패
                └─ 통과 ─▶ "clean up feat-x: close window ●2 → remove worktree → archive + delete branch"  enter · esc
                             └─ 머지 안 됨 ─▶ "feat-x has 2 commit(s) not in origin/main · clean up anyway?"  enter · esc
                                              └─ 실행 → 목록 다시 읽기 → 푸터 "cleaned up … · archived → <ref> · restore: …"
```

- 순서: 창 닫기 → `git worktree remove`(강제 없이, missing 이면 `prune`) → 백업 → `git branch -D`. 창을 먼저 닫는 것은
  그 안의 프로세스(셸, nvim, 에이전트)를 먼저 끝내려고.
- 백업: `refs/archive/<날짜>/<브랜치>`, 같은 날 같은 이름이 있으면 `-2`, `-3` (날짜 없는 이름은 다시 쓰면 덮어써서 기각).
  `refs/heads` 밖이라 브랜치 목록에는 안 뜬다. 목록 `tmux-dev worktree --archived`, 복구 `git branch <이름> <ref>`.
- **피커가 그 창 안에 있을 때.** 피커는 정리할 창 안의 modal 패널일 수 있다(그 창에서 prefix W). 창을 닫으면 피커도 죽는다.
  modal pane 은 `move-pane`·`join-pane` 으로 옮길 수 없다(tmux 3.8 "pane is modal", 시험). 그래서 그 창의 다른 패널만 닫고
  `@worktree` 를 지운다. 피커가 끝나면 마지막 패널이 사라지며 창도 닫히고 tmux 가 다른 창으로 옮겨 준다(시험).
  푸터에 "this window closes when you leave the picker".
- 세션의 마지막 창이면 세션이 끝나지 않도록 세션 디렉토리에 창을 먼저 연다(메인이면 `@worktree`).

## 머지 판정

- `merged` = 브랜치의 변경이 베이스에 모두 들어 있다. ff·merge commit 은 `for-each-ref --merged` 로, rebase(새 SHA)는 고유 커밋의
  patch-id 가 베이스 쪽 집합에 있는지로, squash 는 merge-base 와 브랜치 트리의 diff 하나의 patch-id 로 본다. 캐시
  `~/.cache/tmux-dev/merged/<브랜치 커밋>`, 베이스 쪽 집합 `patchids/<베이스 커밋>`.
- **기준 ref (`judge_ref`).** 로컬 베이스가 업스트림의 조상(같거나 뒤처짐)이면 `origin/<베이스>` 로, 아니면 로컬로. 업스트림이
  둘을 다 담으므로 "로컬 main 또는 origin/main 에 들어 있으면 머지됨" 을 계산 한 번으로 얻는다. 그래서 PR 로 머지한 뒤 pull
  하지 않아도 `merged` 로 보이고, 예전의 "main 을 origin 에 맞출까요?" 질문이 필요 없어졌다.
- 피커가 뜰 때 백그라운드에서 `git fetch --prune origin`(`start:bg-transform`). 원격 ref 가 바뀌었고 아직 worktree 모드이며 묻는
  중이 아니면 목록을 다시 읽는다. 실패(오프라인 등)는 조용히 넘긴다.

## 워크트리 위치와 만들기

`git config` 로 둔다(셸과 Claude Code 훅에서도 돌아야 해서 tmux 옵션이 아니다).

| 키 | 뜻 |
|---|---|
| `tmux-dev.worktree.location` | `central`(기본, `~/.local/share/tmux-dev/worktrees/<이름>/<브랜치의 / → ->`) 또는 `sibling`(`<저장소>.worktrees/…`) |
| `tmux-dev.worktree.root` / `name` | central 모음 디렉토리 / 그 안에서의 저장소 이름 (같은 이름의 다른 저장소면 만들 때 거절) |
| `tmux-dev.worktree.setup` | 새 워크트리 안에서 한 번 실행할 셸 명령 (`TMUX_WORKTREE_MAIN/PATH/BRANCH`) |
| `tmux-dev.layout` | 저장소 기본 레이아웃. 레이아웃 목록에서 alt-enter 로 저장(worktree 모드만) |

베이스는 로컬 기본 브랜치(`origin/HEAD` 가 가리키는 이름, 없으면 main → master), 셸에서는 `--base`.

## 띄우기

prefix S 와 같다 (session-picker.md "띄우기" 절): `run-shell -b "tmux-dev open worktree '#{client_name}' '#{pane_id}' #{q:pane_current_path}"`
→ 런처가 `new-pane -O -K -B none` 로 가운데에 띄운다. 피커는 패널이라 세션은 그 패널의 세션이다. 창만 고르므로 클라이언트를
옮기지 않는다(`select-window`). 피커 디렉토리와 상관없이 저장소는 세션 디렉토리에서 찾는다.

## 결정 기록 (2026-11-08~09)

1. **W 가 만드는 것은 윈도우다.** 워크트리는 그중 흔한 경우. 모드는 worktree · subdirectory · directory (사용자 정리).
2. **저장소 판정은 세션 디렉토리.** 패널 cwd 기준이던 것을 바꿨다. subdirectory 의 시작점도 같다.
3. **목록 순서**: 열린 창 → 최근 → 나머지 워크트리 → 로컬 브랜치 → `origin/*`. 메인 체크아웃도 워크트리 행이다.
4. **만들기는 푸터에서 먼저 묻는다.** enter / alt-l(레이아웃) / esc. 예전 "후보가 없으면 Enter = 새 브랜치" 는 없앴다
   (S 의 "enter 는 열기만, 만들기는 alt-enter" 와 같은 방향).
5. **백업 이름은 날짜 경로 + 충돌 시 -2, -3** (사용자 결정).
6. **머지 판정은 로컬 main 또는 origin/main + 백그라운드 fetch** (사용자 결정). main 동기화 질문은 없앴다.
7. **정리는 피커 안에서, 피커 유지.** 피커가 정리할 창 안에 있으면 다른 패널만 닫는다(modal pane 은 옮길 수 없다).
8. **pane 전환은 맨 마지막에.** 자기 창을 닫는 정리를 먼저 패널 친화적으로 바꾼 뒤 옮겼다.
9. **화면 문구는 영어**, 주석·문서는 한국어.

## 구현 구조와 시험

- `libexec/executable_tmux-dev-worktree`: 저장소·경로 규칙, 후보(`rows_worktree`, `rows_dir`), 머지 판정, 화면, 콜백(`--on …`),
  미리보기, 피커, 실행(`apply_decision`, `open_target`), 정리, Claude Code 훅. 공용은 `lib/picker.sh`, 탐색은 `lib/dirs.sh`,
  레이아웃은 `lib/layout.sh`.
- 콜백은 `--on <이벤트>` 로 같은 스크립트를 다시 부르고, 매번 세션 디렉토리(상태 `root`)에서 저장소를 다시 찾는다.
- **고친 경쟁 상태**: 목록 마커와 미리보기가 같은 patch-id 집합을 동시에 계산할 때 먼저 끝난 쪽의 `find -delete` 가 다른 쪽
  임시 파일을 지워 `mv` 가 실패(`set -e`)하고 목록이 통째로 비었다. 임시 파일(`<커밋>.<pid>`)은 정리 대상에서 빼고 `mv` 실패도 넘긴다.
- **시험**: 격리 tmux 서버(`tmux -L`) + `script` 가짜 클라이언트(stdin 은 끝나지 않는 파이프) + 임시 bare 원격·저장소 +
  `XDG_*_HOME` 임시 디렉토리. 피커는 창이나 modal 패널에 띄우고 `send-keys` / `capture-pane` 으로 본다. 함정: 다른 클론에서
  만든 커밋 cherry-pick 이 조용히 실패한다 → 같은 저장소에서 `checkout -b tmp origin/main; cherry-pick; push HEAD:main`.
