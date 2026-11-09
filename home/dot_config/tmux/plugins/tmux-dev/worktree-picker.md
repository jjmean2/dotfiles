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

- 시작 모드는 저장소면 `worktree`, 아니면 `subdirectory`. `alt-m`(다음)·`alt-n`(이전, n 이 m 왼쪽)이나 헤더의 모드 이름
  클릭으로 바꾼다. tab·shift-tab 은 fzf 순정의 다중 선택이다(worktree 모드에서만, 정리용).
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
│ │ main      ●0 2h ~/dev/jwlee/dotfiles                          │  ← 열린 윈도우 (창 번호 순)
│ │ fix-y     ◷ +2 dirty 3 1d                                     │  ← 최근 고른 것
│ │ feat-z    +5 3d claude:feat-z                                 │  ← 진행 중 워크트리 (최근 커밋 순)
│ │ feat-x    merged 2d                                           │  ← 끝난 워크트리 (흐리게)
│ │ spike     +1 2w (branch) try another layout                   │  ← 로컬 브랜치 (진행 중 → 끝남)
│ │ origin/pr-12  4d (remote) fix: ...                            │  ← 원격 (같은 이름 로컬 있으면 숨김)
│ ╰──────────────────────────────────╯  │                          │
│ ─────────────────────────────────────│                          │
│     enter open · alt-enter new branch · alt-l layout · ctrl-x …  │  ← 푸터: 안내 · 확인 · 결과
╰──────────────────────────────────────────────────────────────────╯
```

- 행은 5칸 `"<이름>\t<표시>\t<종류>\t<경로>\t<브랜치>"`. fzf 는 1·2칸을 보이고 1칸만 검색한다. 종류는
  `worktree | prunable | branch | remote | dir`.
- 행 모양 `<이름 30칸> <창·최근> <상태> <dirty N> <나이> <짧은 위치 | (branch) 제목 | (remote) 제목>` (2026-11-09).
  마커를 위치보다 앞에 둔다: 위치가 길어(50~70자) 미리보기가 켜진 목록 폭에서는 뒤에 붙인 마커가 잘려 안 보였다.
- 마커: `●N` 열린 창 · `◷` 최근 · 상태는 **베이스 기준 하나**: `merged`(모두 들어감) · `new`(브랜치 끝이 베이스 끝과 같다 =
  아직 커밋이 없다) · `+N`(베이스에 없는 커밋 수) · `dirty N`(커밋 안 된 변경 수) · `missing` · `locked` · 나이(마지막 커밋,
  `5m 3h 2d 3w 4mo 2y`). 브랜치 자신의 업스트림 대비(ahead/behind/gone)는 행에서 빼고 미리보기에 말로 쓴다
  ("2 not pushed to origin/x", "upstream … was deleted"). 두 기준이 한 행에 섞여 헷갈렸다.
- 위치: 표준 모음 위치는 생략(미리보기에 전체 경로), Claude Code 의 `<메인>/.claude/worktrees/x` 는 `claude:x`, 나머지는 `~/…`.
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
                └─ 통과 ─▶ 정리 목록이 겹쳐 뜬다 (커서로 고르고 enter, esc 는 돌아가기)
                             ├─ clean up      창 → 워크트리 → 백업 → 브랜치 삭제
                             │                 └─ 머지 안 됨 ─▶ 푸터 "feat-x has 2 commit(s) not in origin/main · clean up anyway?"
                             └─ keep branch   창 → 워크트리 제거까지 (브랜치는 남는다. 그 행에서 enter 로 다시 만든다)
                           → 실행 → 목록 다시 읽기 → 푸터에 결과 (백업 ref, 또는 "kept branch …")
```

- 정리 목록은 레이아웃·위치 목록과 같은 겹쳐 뜨는 fzf 다(`execute(--choose-cleanup)` → 상태 `cleanup_choice` →
  `transform(--on after-cleanup)`). 미리보기가 고른 항목이 할 일을 보여 준다: 닫을 창, 지울 경로, 쓸 백업 ref 이름
  (`next_archive_ref`), 복구 명령, 머지 안 된 커밋 수. 브랜치만 있는 행은 keep 이 할 일이 없어 clean up 하나만 보인다.
- 처음엔 푸터 확인(enter · esc)이었다가 "브랜치는 두고 워크트리만" 이 필요해져 고르는 목록으로 바꿨다 (2026-11-09).
  푸터 키(alt-k)를 더하는 안도 있었지만 커서로 고르는 쪽이 자연스럽고, 우회 없이 피커의 기존 구조를 쓴다.
  tmux `display-menu` 는 고른 결과를 fzf 로 돌려받을 길이 없어(--listen 등 우회) 택하지 않았다.
- 순서: 창 닫기 → `git worktree remove`(강제 없이, missing 이면 `prune`) → 백업 → `git branch -D`. 창을 먼저 닫는 것은
  그 안의 프로세스(셸, nvim, 에이전트)를 먼저 끝내려고.
- 백업: `refs/archive/<날짜>/<브랜치>`, 같은 날 같은 이름이 있으면 `-2`, `-3` (날짜 없는 이름은 다시 쓰면 덮어써서 기각).
  `refs/heads` 밖이라 브랜치 목록에는 안 뜬다. 목록 `tmux-dev worktree --archived`, 복구 `git branch <이름> <ref>`.
- **피커가 그 창 안에 있을 때.** 피커는 정리할 창 안의 modal 패널일 수 있다(그 창에서 prefix W). 창을 닫으면 피커도 죽는다.
  modal pane 은 `move-pane`·`join-pane` 으로 옮길 수 없다(tmux 3.8 "pane is modal", 시험). 그래서 그 창의 다른 패널만 닫고
  `@worktree` 를 지운다. 피커가 끝나면 마지막 패널이 사라지며 창도 닫히고 tmux 가 다른 창으로 옮겨 준다(시험).
  푸터에 "this window closes when you leave the picker".
- 세션의 마지막 창이면 세션이 끝나지 않도록 세션 디렉토리에 창을 먼저 연다(메인이면 `@worktree`).

### 한꺼번에 정리 (2026-11-09)

- **선택**: tab / shift-tab(fzf 순정 `--multi`)으로 하나씩, `ctrl-t` 토글로 merged 인 워크트리·브랜치를 모두 고르거나(선택이 없을 때) 모두 풀기(선택이 있을 때). 다중 선택은 정리에만 쓴다
  (enter 는 늘 커서 항목을 연다). worktree 모드에서만 tab 이 묶여 있고, 다른 모드로 가면 선택을 비우고 tab 을 푼다.
- `ctrl-t` 의 선택 쪽은 마커가 붙은 목록(상태 `rows`, `--list worktree --marks` 가 남긴다)에서 merged 행의 줄 번호로 `pos(N)+select` 를 만든다.
  검색어가 있으면 먼저 지우고 필터가 끝나는 `result` 이벤트에서 고른다(검색어가 없을 때만 목록 위치 = 줄 번호).
  마커가 아직이면 "markers are still loading".
- **ctrl-x 에 선택이 있으면**(`FZF_SELECT_COUNT`) fzf 의 `{+f}`(선택한 행들의 파일)로 받아 정리할 수 있는 것만 모으고, 같은 정리
  목록에 개수로 띄운다: `clean up 12` / `keep branches · remove 9 worktree(s) only`. 미리보기에 항목별 할 일과 건너뛸 것
  (`skipping 3 (2 dirty, 1 main)`, keep 이면 워크트리 없는 브랜치 행도)이 나온다. clean up 에 머지 안 된 것이 섞이면
  `4 of them have commits not in origin/main · clean up anyway?` 로 한 번 더. 하나가 실패해도 나머지는 계속하고 결과를 개수로
  (`cleaned up 12 · archived 12 branch(es) under refs/archive/<날짜>/ · 1 failed: …`, keep 이면 `removed 9 worktree(s) · branches kept`).
  규칙은 하나씩 정리와 같은 `cleanable` / `clean_one` 이다.

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
3. **목록 순서**: 열린 창 → 최근 → 진행 중 워크트리 → 끝난 워크트리(merged, 흐리게) → 로컬 브랜치(진행 중 → 끝남) →
   `origin/*`, 묶음 안은 최근 커밋 순. 메인 체크아웃도 워크트리 행이다. 끝난 것이 아래로 가는 것은 마커를 읽은 뒤다
   (2026-11-09: 실제 dotfiles 에서 59행 중 48행이 끝난 에이전트 워크트리라 진행 중인 작업이 묻혔다).
4. **만들기는 푸터에서 먼저 묻는다.** enter / alt-l(레이아웃) / esc. 예전 "후보가 없으면 Enter = 새 브랜치" 는 없앴다
   (S 의 "enter 는 열기만, 만들기는 alt-enter" 와 같은 방향).
5. **백업 이름은 날짜 경로 + 충돌 시 -2, -3** (사용자 결정).
6. **머지 판정은 로컬 main 또는 origin/main + 백그라운드 fetch** (사용자 결정). main 동기화 질문은 없앴다.
7. **정리는 피커 안에서, 피커 유지.** 피커가 정리할 창 안에 있으면 다른 패널만 닫는다(modal pane 은 옮길 수 없다).
8. **pane 전환은 맨 마지막에.** 자기 창을 닫는 정리를 먼저 패널 친화적으로 바꾼 뒤 옮겼다.
9. **화면 문구는 영어**, 주석·문서는 한국어.
10. **행 표시 (2026-11-09)**: 마커를 위치 앞으로, 상태는 베이스 기준 하나(merged / new / +N), 업스트림은 미리보기로,
    위치 줄이기(표준 생략, claude:), 브랜치·원격 행에 나이와 제목, `dirty N`, 이름 칸 최대 30.
11. **키 (2026-11-09)**: tab·shift-tab 은 fzf 순정 다중 선택(정리에만), 모드는 alt-m·alt-M(S 도 같이), alt-a 는 merged 모두 선택(alt-s 는 모두 풀기),
    선택이 있을 때 ctrl-x 는 한꺼번에 정리. ctrl-[ 는 Esc 와 같은 바이트라 모드 키로 못 쓴다. 이전 모드·모두 풀기는 처음 alt-M·alt-A(Shift 면 반대)였다가
    사용자 요청으로 손이 편한 alt-n·alt-s 로 (키보드에서 m·a 바로 왼쪽·오른쪽 = 짝).
    이후 사용자 요청으로 alt-a·alt-s 를 ctrl-t 토글 하나로 합쳤다(alt-a 가 누르기 불편. ctrl-a 는 tmux prefix2 이자 fzf 기본이라 제외,
    ctrl-s 는 흐름 제어, ctrl-space 는 macOS 입력 소스 전환과 겹친다).
12. **정리는 고르는 목록으로 (2026-11-09)**: clean up / keep branch. 미머지 2차 확인은 clean up 에만 남긴다. 여러 개를 골랐으면
    같은 목록에 clean up N / keep branches(워크트리만, 브랜치 행은 건너뜀).

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
