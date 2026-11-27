# prefix W 윈도우 피커: 멘탈 모델과 설계

`tmux-dev worktree` (prefix W). 2026-11-08~09 에 다시 짰다 (4단계: PR #63 공용 lib, #64 새 피커, #65 정리, 그리고 pane 전환).
prefix S(`session-picker.md`)와 같은 기준이고 공용 부분은 `lib/picker.sh` 를 쓴다. 이 문서는 W 에만 있는 것을 적는다.
이 문서의 코드 경로는 플러그인 디렉터리(`home/dot_config/tmux/plugins/tmux-dev/`) 기준이다.

## 한 줄 모델

> **W 는 지금 세션에 윈도우를 연다.** 출처는 세 가지 모드이고, 세션이 저장소면 워크트리 모드가 먼저 나온다. 정리는 워크트리만.

```
tmux 세션 (세션 디렉토리 = session_path)
 ├─ 윈도우 "main"     패널이 <메인> 안          ← worktree 모드: 워크트리 = 브랜치 = 윈도우
 ├─ 윈도우 "feat-a"   패널이 <워크트리> 안
 ├─ 윈도우 "lib"      패널이 <세션 디렉토리 아래>   ← subdirectory 모드
 └─ 윈도우 "notes"    패널이 <홈 아래 아무 곳>     ← directory 모드
```

- **윈도우는 패널의 경로로 찾는다.** 표지를 붙여 찾지 않는다("윈도우 찾기" 절).

- tmux 를 대체하지 않고 얹는다. `prefix c` 의 보통 윈도우, 순정 `tmux new -c <워크트리>` 모두 정상이다.
- 순정 대응: `git worktree add -b <브랜치> <경로> main` + `tmux new-window -n <브랜치> -c <경로>`.
- **저장소 판정은 세션 디렉토리다.** 패널의 cwd 로 하면 같은 세션에서도 어느 패널에서 눌렀느냐에 따라 모드가 달라진다.
  세션 디렉토리가 워크트리면 그 메인 저장소로 정규화된다(`git rev-parse --git-common-dir`).

## 모드

| 탭 | 켜지는 조건 | 후보 | 만드는 윈도우 |
|---|---|---|---|
| `worktree` | 세션 디렉토리가 git 저장소 | 워크트리 → 로컬 브랜치 → `origin/*` | 워크트리에서 시작, 이름 = 브랜치 |
| `subdirectory` | 항상 | 세션 디렉토리 아래 (`⌂` = 세션 디렉토리 자체) | 그 디렉토리에서 시작, 이름 = 디렉토리 이름 |
| `directory` | 항상 | 홈 전체 (S 의 디렉토리 모드와 같은 탐색) | 그 디렉토리에서 시작 |

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
│     enter open · alt-enter new branch · alt-l layout · ctrl-x …  │  ← 푸터: 안내 · 판정 · 진행 · 결과 (묻지 않는다)
╰──────────────────────────────────────────────────────────────────╯
```

- 행은 5칸 `"<이름>\t<표시>\t<종류>\t<경로>\t<브랜치>"`. fzf 는 1·2칸을 보이고 1칸만 검색한다. 종류는
  `worktree | prunable | branch | remote | dir`.
- 행 모양 `<이름 30칸> <창·최근> <상태> <dirty N> <나이> <짧은 위치 | (branch) 제목 | (remote) 제목>` (2026-11-09).
  마커를 위치보다 앞에 둔다: 위치가 길어(50~70자) 미리보기가 켜진 목록 폭에서는 뒤에 붙인 마커가 잘려 안 보였다.
- 마커: `●N` 열린 창 · `◷` 최근 · 상태는 **베이스 기준 하나**: `merged`(모두 들어감. 뒤의 `·r ·s ·t ·p` 는 판정 방법) · `new`(브랜치 끝이 베이스 끝과 같다 =
  아직 커밋이 없다) · `+N`(베이스에 없는 커밋 수) · `dirty N`(커밋 안 된 변경 수) · `missing` · `locked` · 나이(마지막 커밋,
  `5m 3h 2d 3w 4mo 2y`). 브랜치 자신의 업스트림 대비(ahead/behind/gone)는 행에서 빼고 미리보기에 말로 쓴다
  ("2 not pushed to origin/x", "upstream … was deleted"). 두 기준이 한 행에 섞여 헷갈렸다.
- 위치: 표준 모음 위치는 생략(미리보기에 전체 경로), Claude Code 의 `<메인>/.claude/worktrees/x` 는 `claude:x`, 나머지는 `~/…`.
  마커 없는 목록을 먼저 그리고 fzf 의 `load` 이벤트에서 `--marks` 로 바꿔 끼운다(행마다 git 이 돌아 비싸다).
  fetch 로 원격이 바뀌어 다시 읽을 때는 마커 없는 목록을 거치지 않고 `reload-sync(--list worktree --marks)` 로 한 번에
  바꾼다(2026-11-17). `reload-sync` 는 새 목록이 다 만들어질 때까지 지금 목록을 그대로 둔다(그동안 검색·선택도 된다). 예전에는
  겹친 목록(정리·만들기)을 보는 동안 fetch 가 끝나면 돌아왔을 때 마커가 빠져 있다가 몇 초 뒤 붙었다. 새로 생긴 행은 계산이
  끝난 뒤에 나타나고, 계산 중에 모드를 바꾸면 나중의 reload 가 이긴다(시험). 정리가 끝난 뒤와 모드를 바꿀 때는 예전대로 바로
  다시 읽는다: 정리 뒤에 지운 행이 몇 초 남거나, 모드를 바꿨는데 다른 모드의 목록이 남으면 그 행을 잘못 다룰 수 있다.
  처음에는 지난 마커를 목록에 합쳐 보이는 `--cached` 를 만들었다가, 상태 `rows` 의 뜻이 둘로 갈려(지우는 규칙, 한꺼번에
  정리의 신뢰 검사) 복잡도에 비해 얻는 것이 적어 `reload-sync` 로 바꿨다.

## worktree 모드의 동작

| 행 | Enter | alt-l | ctrl-x |
|---|---|---|---|
| 워크트리, 창 열림 | 그 창으로 | 그 창으로 | 정리: 창 → 워크트리 → 백업 → 브랜치 |
| 워크트리, 창 없음 | 창 만들기 | 레이아웃 골라 창 만들기 | 정리 (창 단계 없음) |
| 메인 체크아웃 | 메인 창으로 (없으면 만들기) | 레이아웃 골라 | 하지 않음 |
| missing | **만들기 목록** → prune 후 다시 만들기 | 만들기 목록 (커서는 with layout) | prune → 백업 → 브랜치 |
| 로컬 브랜치 | **만들기 목록** → 워크트리 + 창 | 만들기 목록 (커서는 with layout) | 백업 → 브랜치 |
| 원격 브랜치 | **만들기 목록** → 추적 브랜치 + 워크트리 + 창 | 만들기 목록 (커서는 with layout) | 하지 않음 |
| alt-enter (친 이름) | **만들기 목록** → 베이스에서 새 브랜치 + 워크트리 + 창 | – | – |

**만들기는 언제나 겹쳐 뜬 만들기 목록에서 고른다** (session-picker.md 의 "고르는 것은 겹쳐 뜨는 목록에서, 푸터는 묻지 않는다").

```
메인 목록 ──enter / alt-enter──▶ ┌ new branch 'foo' ──────┐   미리보기: branch ← base, worktree 경로,
                                 │ > create from main     │            layout(기본값), setup, (있는 브랜치면) 커밋
                                 │   create with layout…  │──enter / alt-l──▶ 레이아웃 목록
                                 └ esc back ──────────────┘                      │ esc → 만들기 목록 (커서 그대로)
                                   │ esc → 메인 목록 (검색어·커서·선택 그대로)
```

- `execute(--choose-create)` → 상태 `create_choice` → 메인 목록의 `transform(--on after-create)` 가 `decide`. 대상은 상태 `target`,
  처음 커서 행은 `create_start`(`load:pos(N)`. 메인 목록의 alt-l 이면 2). 레이아웃은 만들기 목록 위에 한 번 더 `execute` 로
  겹쳐 띄우므로 거기서 esc 면 만들기 목록에 남는다(위치 피커 → 레이아웃과 같은 구조).
- 제목이 할 일을 말한다: `new branch 'x'` · `worktree for 'x'` · `track origin/x` · `recreate worktree 'x'`.
- 메인 목록의 alt-l 은 만들어야 하는 행에서 따로 지름길을 두지 않는다. 만들기 목록에 with layout 행이 있으니 같은 목록을
  띄우고 커서만 그 행에 둔다.

**여는 동작은 "피커는 결정만"** 이다. 결정 `"<종류>US<경로>US<브랜치>US<레이아웃>US<save>US<만들기>US<부모>"` 를 적고
fzf 를 끝낸 뒤 `apply_decision` 이 만들고 연다(`CONFIRMED=1` 이라 셸 호출용 질문을 건너뛴다). 정리는 반대로 피커 안에서 끝난다
(피커를 계속 쓰려고).

## 디렉토리 모드

- 목록: 이 세션에 열린 창의 디렉토리(`●N`) → 최근(`◷`) → (`⌂` 세션 디렉토리) → 탐색. 경로가 같은 행은 앞의 것만.
- Enter: 그 디렉토리의 창이 있으면 그리로, 없으면 만들기. 고른 디렉토리가 이 저장소의 워크트리면 워크트리 창으로 연다.
  디렉토리의 창 = 현재 경로가 정확히 그 디렉토리인 패널이 있는 창, 없으면 시작 경로가 그런 창. 디렉토리는 겹칠 수 있어
  (`app` 과 `app/docs`) 워크트리처럼 "안에 있으면" 으로 보지 않는다. 목록의 `●N` 과 Enter 는 같은 함수(`open_window_for`)로 정한다.
- 새로 만들기: S 와 같은 위치 피커(alt-enter, 경로를 치면 그 자리에). subdirectory 에서는 위치 후보도 세션 디렉토리 아래로
  (`lib/picker.sh` 의 `LOC_ROOT`, 탐색 시작점은 `SCAN_ROOT`). 탐색은 시작점 아래만 나오므로 시작점 자체를 `⌂` 행으로 넣는다.
- 정리는 없다(디렉토리는 지우지 않는다).

## 윈도우 찾기 (2026-11-24)

"이 워크트리의 윈도우가 열려 있는가" 는 패널의 경로로 판정한다(`lib/panes.sh`). tmux 가 패널마다 들고 있는 두 값을 쓴다.

| 값 | 뜻 | 성질 |
|---|---|---|
| `pane_start_path` | 패널을 만들 때 받은 경로(`-c`) | `cd` 로 바뀌지 않는다. `break-pane`·`join-pane` 에서 패널을 따라간다. 받은 그대로라 심볼릭 링크는 풀어서 쓴다 |
| `pane_current_path` | 패널의 포그라운드 프로그램의 cwd | 셸이 아니라 돌고 있는 프로그램의 경로다. 실제 경로 |

- **패널의 주인(`pane_owner`)**: 현재 경로가 이 저장소의 워크트리 안이면 그 워크트리, 아니면 시작 경로의 워크트리. 겹치면 가장
  깊은 워크트리다(메인 체크아웃이 그 아래 `.claude/worktrees/*` 를 삼키지 않게). 한 패널의 주인은 하나다.
- **워크트리의 윈도우(`window_for`)**: 그 워크트리가 주인인 패널이 있는 가장 앞 번호의 윈도우. 범위는 지금 세션.
- **피커 자신은 뺀다**: 피커는 그 윈도우의 modal 패널이고 세션 디렉토리로 cd 해 있다(`pane_modal_flag`).
- 목록의 `●N`, Enter, 정리 미리보기, 정리, S 의 워크트리 이동이 모두 이 함수들을 쓴다.

현재 경로를 먼저 보는 이유는 지울 때 중요한 것이 "지금 거기 있는 프로세스" 여서다. 시작 경로로 물러나는 이유는 현재 경로가
프로그램에 따라 바뀌어서다(셸이 제자리여도 프로그램이 다른 곳으로 옮긴 동안에는 그 경로가 나온다). 물러남이 없으면 `●` 가 깜빡인다.

따라오는 동작:

- `prefix c` 로 워크트리 안에서 연 윈도우, handoff 가 연 윈도우, 떼어 낸 패널이 모두 같은 규칙으로 잡힌다.
- 메인 체크아웃 아래 디렉토리(`docs`)에서 연 윈도우는 메인의 윈도우다. 메인 행의 Enter 가 그리로 간다.
- 메인 윈도우의 셸이 다른 워크트리로 `cd` 해 있는 동안 그 윈도우는 그 워크트리의 것이다. 그때 메인 행에서 Enter 하면
  메인 윈도우가 하나 더 열린다.
- 메인에서 띄운 에이전트가 워크트리로 들어가면(`EnterWorktree`) 그 패널은 그 워크트리의 것이 되고, 그 워크트리를 정리하면 닫힌다.

전에는 만든 윈도우에 사용자 옵션 `@worktree`·`@dir` 을 붙여 그것으로 찾았다(메인 체크아웃 행만 활성 패널의 경로로 보완). 표지는
윈도우라는 자리에 붙는데 "워크트리 안에 있다" 는 패널의 성질이라 어긋났다: 표지 없는 윈도우는 잡히지 않아 같은 워크트리의
윈도우가 하나 더 생겼고, `break-pane` 으로 떼어 낸 패널은 표지를 잃고 남은 윈도우는 무관한 패널만 있어도 표지를 지녔으며,
정리는 표지 없는 윈도우의 프로세스를 지워지는 디렉토리에 남겼다. 피커가 뜬 윈도우가 메인의 윈도우로 잡히기도 했다(피커가
활성 패널이고 세션 디렉토리에 있어서). 표지는 세 단계로 없앴다: tmux-dev 가 읽지 않게, jw 플러그인의 handoff 가
읽지 않게(0.11.1), 양쪽이 쓰지 않게(0.11.2). 지금은 어느 표지도 쓰거나 읽지 않는다. 시험은 `test/tmux-dev/windows`(격리된 실제 tmux 서버).

## 정리 (ctrl-x)

```
ctrl-x ─▶ 검사 ─┬─ 메인 / 베이스 브랜치 / 원격 / locked ─▶ 벨 + 안내
                ├─ dirty ─▶ 변경 수와 함께 실패
                └─ 통과 ─▶ 정리 목록이 겹쳐 뜬다 (커서로 고르고 enter, esc 는 돌아가기)
                             ├─ clean up      패널 → 워크트리 → 백업 → 브랜치 삭제
                             └─ keep branch   패널 → 워크트리 제거까지 (브랜치는 남는다. 그 행에서 enter 로 다시 만든다)
                           → 실행 → 목록 다시 읽기 → 푸터에 결과 (백업 ref, 또는 "kept branch …")
```

- 정리 목록은 레이아웃·위치 목록과 같은 겹쳐 뜨는 fzf 다(`execute(--choose-cleanup)` → 상태 `cleanup_choice` →
  `transform(--on after-cleanup)`). 미리보기가 고른 항목이 할 일을 보여 준다: 닫을 창, 지울 경로, 쓸 백업 ref 이름
  (`next_archive_ref`), 복구 명령, 머지 안 된 커밋 수. 브랜치만 있는 행은 keep 이 할 일이 없어 clean up 만 있다.
- **머지 안 됨은 다시 묻지 않고 행 순서로 막는다 (2026-11-17).** 안전한 행(keep branch, 없으면 `back · do nothing`)을 맨 위
  (커서 자리)에 두고 clean up 에 `(+N not in origin/main) · branch archived` 를 붙인다. enter 를 연달아 눌러도 안전한 쪽만
  일어나고, 지우려면 커서를 내린다. 머지됐으면 clean up 이 맨 위다. 예전에는 clean up 을 고른 뒤 푸터에서 한 번 더 물었는데,
  그때는 정리 목록이 이미 닫혀 있어 esc 가 정리 목록이 아니라 메인 목록으로 물러났다.
- 처음엔 푸터 확인(enter · esc)이었다가 "브랜치는 두고 워크트리만" 이 필요해져 고르는 목록으로 바꿨다 (2026-11-09).
  푸터 키(alt-k)를 더하는 안도 있었지만 커서로 고르는 쪽이 자연스럽고, 우회 없이 피커의 기존 구조를 쓴다.
  tmux `display-menu` 는 고른 결과를 fzf 로 돌려받을 길이 없어(--listen 등 우회) 택하지 않았다.
- **커밋 안 된 변경은 지우지 않는다 (2026-11-17).** dirty 는 `git status --porcelain -unormal` 로 센다: 수정 + 추적 안 하는 새 파일,
  무시된 파일은 빼고(`git worktree remove` 와 같은 기준). `-unormal` 은 저장소의 `status.showUntrackedFiles=no` 를 덮는다(없으면
  새 파일만 있는 워크트리가 깨끗해 보였다). ctrl-x 때 한 번(`cleanable`), 실행할 때 다시 두 번(`dirty_guard`): 창을 닫기 전
  (괜히 닫지 않게), 창을 닫고 그 패널 프로세스가 끝나기를 기다린 뒤 옮기기 직전. 빠른 제거의 `git worktree move` 와
  뒤의 `remove --force --force` 는 dirty 를 막지 않으므로 이 검사가 유일한 안전장치다. 정리 목록을 보는 동안 에이전트가 파일을
  쓰거나, 창이 닫히며 에디터가 저장하는 경우를 시험으로 확인했다(`kill-window` 는 SIGHUP 만 보내고 바로 돌아와서 기다리지 않으면
  검사가 먼저 돈다). 걸리면 `dirty: N … · nothing removed` 로 실패하고, 한꺼번에 정리면 그 항목만 실패로 센다.
  - 기다릴 대상은 쉘(`pane_pid`)만이 아니라 패널의 터미널(`pane_tty`)을 쓰는 프로세스 전부다(`ps -t`, 창을 닫기 전에 모은다).
    쉘보다 늦게 끝나는 nvim·claude 와 그 자식, 백그라운드 작업이 들어간다. 5초 안에 다 끝나지 않으면 지우지 않고 실패한다
    (`processes in its windows are still running`). 살아남은 프로세스의 cwd 는 옮긴 휴지통을 따라가서, 시간이 지났다고
    진행하면 거기 쓴 것이 강제 삭제로 사라진다. (PR #144 리뷰)
- **서브모듈이 든 워크트리는 서브모듈에만 있는 것을 보고 --force 로 지운다 (2026-11-25).** git 은 초기화된 서브모듈이 있는
  워크트리를 `move`·`remove` 모두 거부한다(`working trees containing submodules cannot be moved or removed`). 서브모듈의 저장소가
  `<common>/worktrees/<id>/modules/` 에 있어 워크트리와 함께 사라지기 때문이다. 예전에는 이 에러로 실패해 패널만 닫히고 워크트리·
  브랜치가 남았다. 이제 `dirty_guard` 가 `submodule_guard` 를 부르고, `trash_worktree` 는 이 에러일 때만 `remove --force` 로 넘어간다.
  대상은 git 의 판정과 같게 잡는다: `modules/` 아래 저장소 전부(중첩, deinit 해서 체크아웃 없는 것 포함) + `submodule foreach
  --recursive` 로 체크아웃된 것 전부(흡수 안 된 옛 `.git` 디렉토리 포함). 각각에서 원격 추적 브랜치에 없는 커밋(로컬 브랜치·HEAD 기준,
  원격이 없으면 전부), `refs/stash`, 커밋 안 된 변경(`.gitmodules` 의 `ignore=` 로 상위 status 에 숨을 수 있어 직접 센다)을 본다.
  하나라도 있거나 판정을 못 하면 아무것도 지우지 않는다. Claude Code 의 WorktreeRemove 훅(`hook_remove`)은 Claude 가 지우기로
  정한 뒤라 예전처럼 `--force --force` 로 지운다.
  - `git status` 가 실패하면(깨진 `.git`, `safe.directory` 소유자 검사, 권한) 판정 못 함 = 막는다. 파이프(`… | wc -l`)로 세면
    실패해도 `0` 이 찍히고, `||`·`if` 안에서 불린 함수에서는 `set -e` 도 꺼져 있어 "깨끗함" 으로 읽혔다. 행 마커는 `dirty ?`,
    ctrl-x 는 `cannot check …`, 한꺼번에 정리는 `unchecked` 로 건너뛴다. (PR #144 리뷰)
- 순서: 창 닫기 → 워크트리 제거(missing 이면 `prune`) → 백업 → `git branch -D`. 창을 먼저 닫는 것은
  그 안의 프로세스(셸, nvim, 에이전트)를 먼저 끝내려고.
- **빠른 제거 (2026-11-09).** `git worktree remove` 는 디렉토리를 다 지울 때까지 기다린다(무시 파일 3만 개에 1.3초). 대신
  같은 부모의 `.trash/<이름>.<시각>.<pid>` 로 `git worktree move` 한다: 같은 파일시스템의 이름 바꾸기라 즉시(0.02초) 끝나고,
  원래 경로·목록 행이 바로 비고, `checkout --detach` 로 브랜치가 풀려 `git branch -D` 와 같은 이름으로 다시 만들기가 바로 된다.
  실제 삭제(`git worktree remove --force --force`)는 결과를 알린 뒤에. `mv` 가 아니라 `git worktree move` 인 것은 git 의 검사
  (메인·locked·서브모듈 거절)와 메타데이터를 그대로 쓰려고. 옮기지 못하면(서브모듈, 다른 파일시스템) 예전처럼 바로 지운다.
  휴지통의 워크트리는 목록에서 숨기고(`list_worktrees`), 중간에 끊겨 남은 것은 다음에 피커가 뜰 때 백그라운드 fetch 와 함께
  tmux 서버에서 마저 지운다(`trash_sweep`, `--empty-trash`).
- **진행 표시 (2026-11-09).** 정리는 콜백(transform)에서 바로 하지 않고 `tmux run-shell -b … --cleanup-job` 로 띄운다. fzf 가
  멈추지 않고, 피커가 끝나도(esc, 피커 창 닫힘) 정리는 끝까지 간다. 피커는 처음에 풀어 둔 `every(0.15)` 이벤트를 다시 묶어
  틱마다(`--cleanup-tick`, 저장소를 찾지 않는 가벼운 경로) 스피너와 상태 `progress`(`2/3 h2 · archiving branch`)를 푸터에 그리고,
  `finished` 가 생기면 `every` 를 풀고 목록을 다시 읽어 결과를 남긴다. 정리 중(`busy`)에는 enter·ctrl-x·alt-enter·alt-l·모드·ctrl-t(고르기 쪽) 가
  벨만 낸다. 상태 디렉토리는 피커가 끝나면 지워지므로 작업은 시작할 때 할 일을 다 읽고, 이후 쓰기는 실패해도 넘긴다. 작업이
  중간에 죽어도 EXIT 트랩이 결과를 남겨 스피너가 계속 돌지 않는다. fzf 의 `unbind`/`rebind` 는 `every(0.15)` 전체 이름으로 해야
  먹는다(시험: `every` 만 쓰면 다시 묶이지 않는다).
- 백업: `refs/archive/<날짜>/<브랜치>`, 같은 날 같은 이름이 있으면 `-2`, `-3` (날짜 없는 이름은 다시 쓰면 덮어써서 기각).
  `refs/heads` 밖이라 브랜치 목록에는 안 뜬다. 목록 `tmux-dev worktree --archived`, 복구 `git branch <이름> <ref>`.
- **닫는 것은 패널이다 (2026-11-24).** 그 워크트리가 주인인 패널을 닫는다("윈도우 찾기" 절의 규칙 그대로. 범위는 지금 세션).
  표지 없는 창의 패널도 닫히고, 한 창에 다른 곳의 패널이 섞여 있으면 그 패널과 창은 남는다. 정리 목록의 미리보기가 창마다
  `close window ●N (zsh, nvim)` 또는 `close 1 of 3 panes in window ●N (claude)` 로 닫을 것과 거기서 도는 프로그램을 보인다
  (`close_plan`. 실제로 닫는 `close_panes` 와 같은 주인 표를 본다).
- **피커가 그 창 안에 있을 때.** 피커는 정리할 창 안의 modal 패널일 수 있다(그 창에서 prefix W). modal 패널은 주인을 가릴 때부터
  빠져 있어 닫히지 않는다. modal pane 은 `move-pane`·`join-pane` 으로 옮길 수 없다(tmux 3.8 "pane is modal", 시험). 그 창에
  피커만 남으면 피커가 끝날 때 창도 닫히고 tmux 가 다른 창으로 옮겨 준다(시험). 푸터에 "this window closes when you leave the picker".
- 사라진 워크트리(missing)는 예전에 등록된 경로가 아니라 지금 규칙의 경로(`wt_dir`)에 다시 만든다(`open_target` 이 prune 뒤
  `add_worktree`). 만들기 목록의 미리보기·레이아웃 제목도 같은 `wt_dir` 을 쓰고, 경로가 다르면 `was at <예전 경로>` 를 따로 보인다.
  detached 였으면 다시 만들 브랜치가 없어 `prune the missing worktree` 한 행만 있다. (PR #144 리뷰)
- 닫고 나면 세션에 남는 창이 없을 때는 세션이 끝나지 않도록 세션 디렉토리에 창을 먼저 연다.

### 한꺼번에 정리 (2026-11-09)

- **선택**: tab / shift-tab(fzf 순정 `--multi`)으로 하나씩, `ctrl-t` 토글로 merged 인 워크트리·브랜치를 모두 고르거나(선택이 없을 때) 모두 풀기(선택이 있을 때). 다중 선택은 정리에만 쓴다
  (enter 는 늘 커서 항목을 연다). worktree 모드에서만 tab 이 묶여 있고, 다른 모드로 가면 선택을 비우고 tab 을 푼다.
- `ctrl-t` 의 선택 쪽은 마커가 붙은 목록(상태 `rows`, `--list worktree --marks` 가 남긴다)에서 merged 행의 줄 번호로 `pos(N)+select` 를 만든다.
  검색어가 있으면 먼저 지우고 필터가 끝나는 `result` 이벤트에서 고른다(검색어가 없을 때만 목록 위치 = 줄 번호).
  마커가 아직이면 "markers are still loading".
- **ctrl-x 에 선택이 있으면**(`FZF_SELECT_COUNT`) fzf 의 `{+f}`(선택한 행들의 파일)로 받아 정리할 수 있는 것만 모으고, 같은 정리
  목록에 개수로 띄운다: `clean up 12` / `keep branches · remove 9 worktree(s) only`. 미리보기에 항목별 할 일과 건너뛸 것
  (`skipping 3 (2 dirty, 1 main)`, keep 이면 워크트리 없는 브랜치 행도)이 나온다. clean up 에 머지 안 된 것이 섞이면
  같은 규칙으로 `keep branches`(워크트리가 없으면 `back`)가 맨 위에 오고 `clean up N (4 not merged)` 로 경고한다. 하나가 실패해도 나머지는 계속하고 결과를 개수로
  (`cleaned up 12 · archived 12 branch(es) under refs/archive/<날짜>/ · 1 failed: …`, keep 이면 `removed 9 worktree(s) · branches kept`).
  규칙은 하나씩 정리와 같은 `cleanable` / `clean_one` 이다.

## 머지 판정

- `merged` = 브랜치의 변경이 베이스에 모두 들어 있다. ff·merge commit 은 `for-each-ref --merged` 로, rebase(새 SHA)는 고유 커밋의
  patch-id 가 베이스 쪽 집합에 있는지로, squash 는 merge-base 와 브랜치 트리의 diff 하나의 patch-id 로 본다. 그래도 아니면
  `git merge-tree --write-tree <베이스> <브랜치>` 의 결과 트리가 베이스 트리와 같은지 본다 (3-way 머지는 양쪽에 똑같이 들어간
  변경을 그대로 합치므로 diff 문맥이 달라져도, 스택 PR 이 차례로 squash 돼도 잡는다). 캐시
  `~/.cache/git-merged/merged/<브랜치 커밋>` 에 `<베이스 커밋> <0|방법>`, 베이스 쪽 집합 `patchids/<베이스 커밋>`.
- **판정 방법 표시 (2026-11-13).** 처음 맞은 방법을 `merged` 뒤에 흐린 글자로: 없음 = 조상(ff·merge commit), `·r` rebase,
  `·s` squash(diff patch-id), `·t` tree(merge-tree), `·p` GitHub PR. 미리보기에는 말로.
- **판정 방법 글자 색 (2026-11-17).** `·r ·s ·t` 는 흐린 초록, `·p` 는 마젠타. 색은 증명의 근거를 나눈다: 로컬 git 내용
  (merged 와 같은 계열이라 한 덩어리로 읽힌다) 대 GitHub 정보(fetch 때 갱신되는 캐시, GitHub 의 머지 PR 색).
  글자마다 다른 색은 외우기 어렵고, 노랑(살펴볼 것)·빨강(위험)은 "지워도 안전"과 뜻이 반대라 쓰지 않는다.
- **GitHub PR (2026-11-13).** 로컬 판정이 모두 아니면 머지된 PR 목록을 본다. 브랜치 커밋이 PR head 와 같거나, 같은 이름 PR 의
  head 가 로컬에 있고 브랜치 커밋을 담으면(로컬이 뒤처짐) merged. 이름이 아니라 커밋으로 비교해 이름을 다시 써도 안전하다.
  리뷰 제안처럼 GitHub 에서만 생긴 커밋까지 squash 돼 로컬 판정이 다 실패하는 경우를 잡는다. 목록은 백그라운드 fetch 때
  `gh pr list --state merged --limit 300` 으로 받아 `~/.cache/git-merged/prs/<origin URL 해시>` 를 통째로 바꾼다(저장소당 파일
  하나, `<head 커밋> <번호> <base 브랜치> <head 브랜치>`). fetch 와 동시에 돌고, 목록이 바뀌어도 다시 읽는다. gh 가 없거나 실패하면 예전
  파일을 두고, 파일이 없으면 건너뛴다. 60일 동안 안 갱신된 파일은 `merged_cache_prune` 이 치운다. `GIT_MERGED_PR_LIMIT` 로 개수 조절.
- **PR 은 베이스로 머지된 것만 (2026-11-27).** 목록에 PR 이 머지된 곳(`baseRefName`)을 같이 받아, 베이스 브랜치(업스트림이
  있으면 그 이름)로 머지된 PR 만 센다. 전에는 스택 PR 이 부모 브랜치로 머지된 것도 merged 였다: main 에는 없는데 정리 화면의
  "not merged" 경고가 빠졌다. 칸이 셋인 예전 형식의 줄은 base 를 몰라 세지 않는다(다음 fetch 가 파일을 새로 쓴다).
- **빈 patch-id 는 squash 가 아니다 (2026-11-27).** squash 판정은 diff 의 patch-id 가 비어도 merged 로 봤다. 비는 경우는
  변경이 없을 때만이 아니라 `git diff` 실패, 모드만 바뀐 변경도 있어서(뒤의 둘은 머지된 것이 아니다) 판정하지 않고 넘긴다.
  변경이 정말 없는 브랜치(커밋 뒤 되돌림)는 tree 가 잡는다.
- **판정은 git-merged 로 옮겼다 (2026-11-27).** 머지 판정은 tmux 와 상관없는 git 의 일이라 독립 명령
  `~/.jongwan/bin/git-merged` (`git merged <브랜치>`, `--explain` 은 방법마다 결과와 이유)로 뺐다. 피커는 그 파일을 source 해서
  같은 함수를 쓴다: 브랜치 수백 개를 프로세스를 새로 띄우지 않고 판정하고, `merge_prepare` 의 결과를 fork 한 자식이 상속받는
  구조가 그대로다(명령을 브랜치마다 부르면 느리다). 의존은 tmux-dev → git-merged 한쪽이다. 캐시도 따라갔다:
  `~/.cache/git-merged/{merged,patchids,prs}`. 피커에는 피커만의 것이 남는다: `new` 상태, 행 상태 캐시(`marks`), dirty 수.
  판정 테스트는 `test/git-merged/run` (피커의 목록이 같은 답을 내는지도 본다).
- **merge-tree 는 임시 오브젝트 디렉토리에 쓴다.** `--write-tree` 는 결과 블롭·트리를 저장소에 써서, 머지 안 된 브랜치마다 참조
  없는 루즈 오브젝트가 gc 전까지 쌓인다. `GIT_OBJECT_DIRECTORY=<임시>` + `GIT_ALTERNATE_OBJECT_DIRECTORIES=<저장소 objects>`
  로 새 것은 임시 디렉토리에만 쓰고 바로 지운다. 죽어서 남은 `$TMPDIR/tmux-dev.mt.*` 는 기존 `tmux-dev.*` 1시간 정리가 치운다.
  `--quiet`(오브젝트를 안 쓰는 옵션)는 git 2.43 에 없고 트리 비교도 못 해서 쓰지 않는다.
- **기준 ref (`judge_ref`).** 로컬 베이스가 업스트림의 조상(같거나 뒤처짐)이면 `origin/<베이스>` 로, 아니면 로컬로. 업스트림이
  둘을 다 담으므로 "로컬 main 또는 origin/main 에 들어 있으면 머지됨" 을 계산 한 번으로 얻는다. 그래서 PR 로 머지한 뒤 pull
  하지 않아도 `merged` 로 보이고, 예전의 "main 을 origin 에 맞출까요?" 질문이 필요 없어졌다.
- 피커가 뜰 때 백그라운드에서 `git fetch --prune origin`(`start:bg-transform`). 원격 ref 가 바뀌었고 아직 worktree 모드이며 정리
  중이 아니면 목록을 다시 읽는다. 실패(오프라인 등)는 조용히 넘긴다.
  검색어를 바꿀 때 보내던 `bg-cancel` 은 돌고 있는 bg-transform 을 모두 끊어서 이 fetch 도 죽였다(검색어를 빨리 치면 원격이
  갱신되지 않았다. 시험으로 확인). 그 취소는 디렉토리 모드의 경로 판정(`result`)을 위한 것이라 이제 그 모드에서만 보낸다 (2026-11-17).
- **fzf 가 끊는 콜백에서는 락을 쥐는 git 을 돌리지 않는다** (2026-11-19). fzf 0.75 는 preview·reload·bg-transform 을 끊을 때
  (커서 이동, 모드 전환, 마커 다시 읽기, 피커 종료) 프로세스 그룹째 SIGKILL 을 보낸다(손자 프로세스까지. 시험으로 확인).
  git 은 SIGKILL 에 락을 못 치운다. 그래서
  - 스크립트 맨 위에서 `GIT_OPTIONAL_LOCKS=0`. `git status` 가 stat 캐시를 index 에 다시 쓰느라 도는 내내 쥐던 `index.lock` 을
    아예 잡지 않는다. 전에는 preview·마커 계산(`dirty_count`)이 끊길 때 `.git/worktrees/<n>/index.lock` 이 남았고, 남지 않아도
    피커가 쥔 동안 사용자·에이전트의 `git commit` 이 실패했다. 병렬 마커 계산 자체는 원인이 아니다(워크트리마다 index 가 따로).
  - fetch(와 gh PR 목록)는 정리 작업처럼 `tmux run-shell -b`(`--fetch-job`)로 띄우고, bg-transform 은 상태 `fetched` 만 기다린다.
    피커를 닫으면 기다리던 콜백만 죽고 fetch 는 끝까지 가므로 `refs/remotes/origin/*.lock`·`packed-refs.lock` 이 남지 않는다.

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
4. **만들기는 먼저 확인한다.** 처음엔 푸터에서 물었고(enter / alt-l / esc), 2026-11-17 부터 겹쳐 뜬 만들기 목록이다(결정 14).
   예전 "후보가 없으면 Enter = 새 브랜치" 는 없앴다 (S 의 "enter 는 열기만, 만들기는 alt-enter" 와 같은 방향).
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
12. **정리는 고르는 목록으로 (2026-11-09)**: clean up / keep branch. 미머지 2차 확인은 clean up 에만 남긴다(결정 14 에서 없앰). 여러 개를 골랐으면
    같은 목록에 clean up N / keep branches(워크트리만, 브랜치 행은 건너뜀).
13. **빠른 제거 + 진행 표시 (2026-11-09)**: 휴지통(`.trash/`, 워크트리 모음 디렉토리 안)으로 `git worktree move` 한 뒤 백그라운드 삭제,
    정리는 tmux 서버 작업으로 돌리고 피커는 `every` 틱으로 진행을 보인다 (사용자 결정: "둘다").
14. **푸터는 묻지 않는다 (2026-11-17)**: 사용자 요구 "모든 선택이 끝날 때까지는 되돌아올 수 있어야 한다". 겹친 목록 뒤에
    푸터 확인이 오면(정리 → 미머지 확인) esc 가 겹친 목록을 건너뛰어 메인 목록으로 물러났다. 그래서 만들기 확인을 겹친 목록으로
    옮기고(alt-l 은 그 목록의 with layout 행으로 대체), 미머지 2차 확인은 "안전한 행을 맨 위에" 로 바꿨다(사용자: 권장대로).
    상태 `confirm`·`op`, 묻는 동안만 묶던 `focus`, 처리기마다의 "묻는 중인가" 분기가 모두 없어졌다.
    같이 고친 것: 마커 판정(`ctrl-t`, 한꺼번에 정리의 미머지 수)이 표시 칸을 `*merged*` 로 맞춰 경로·제목의 "unmerged" 에도
    걸렸다. 색까지(`${G}merged${R}`) 맞춘다.

15. **표지 대신 패널의 경로 (2026-11-24)**: 윈도우를 `@worktree`·`@dir` 로 찾던 것을 패널의 시작·현재 경로로 바꿨다("윈도우 찾기" 절).
    사용자 질문 "이 표지는 꼭 필요할까? window 나 pane 을 이동하고 break/join 을 하는 환경에서도 유용할까?" 에서 시작했다.
    정한 것: 주인은 현재 경로 먼저·시작 경로로 물러남, 여럿이면 가장 앞 번호의 윈도우, 디렉토리는 정확히 같을 때만, 정리는
    패널 단위·지금 세션(다른 세션의 패널까지 닫는 것은 따로 정한다). `@worktree` 쓰기는 handoff 가 경로로 찾게 된 뒤 같이 뗐다.

## 구현 구조와 시험

- `libexec/executable_tmux-dev-worktree`: 저장소·경로 규칙, 후보(`rows_worktree`, `rows_dir`), 머지 판정, 화면, 콜백(`--on …`),
  미리보기, 피커, 실행(`apply_decision`, `open_target`), 정리, Claude Code 훅. 공용은 `lib/picker.sh`, 탐색은 `lib/dirs.sh`,
  레이아웃은 `lib/layout.sh`, 윈도우 찾기(패널의 주인)는 `lib/panes.sh`. 키마다 도는 콜백(`change`·`result`·`enter`)과 그것이 쓰는 푸터·모드 함수는 `lib/worktree-events.sh`
  (진입 스크립트 머리의 빠른 길이 이것만 읽고 끝낸다. 아래 2026-11-23).
- 콜백은 `--on <이벤트>` 로 같은 스크립트를 다시 부른다. 매번 새 프로세스라 문맥을 다시 갖춰야 하는데, 그 문맥은 세 가지다.
  - **피커가 정해 둔 값** (상태 `session`·`base`·`root`·`mode`): `pick` 이 뜰 때 한 번 쓰고 `picker_ctx` 가 읽는다. bash 내장
    `read` 라 프로세스를 띄우지 않는다. 피커가 떠 있는 동안 바뀌지 않는 것만 둔다. `base` 는 브랜치 이름만 고정하고 그 커밋은
    늘 새로 읽는다.
  - **저장소 문맥** (`repo_try`: `COMMON`·`WT_LIST`·`MAIN`·`NAME`): git 을 여러 번 띄우고 워크트리 수만큼 느려진다. 워크트리
    목록은 피커가 떠 있는 동안에도 바뀌므로(만들기·정리) 쓸 때마다 새로 읽는다. `in_session_dir` = `picker_ctx` + `repo_try`.
  - **이벤트 값**: fzf 가 주는 환경변수(`FZF_QUERY` 등)와 인자(커서 행).
- **자주 도는 콜백은 가볍게 (2026-11-22).** `change`(키마다)와 `result`(검색마다)는 `picker_ctx` 만 쓰고 저장소 문맥을 만들지
  않는다. 진입 스크립트 머리의 빠른 길(2026-11-23 부터. 그 전에는 `--on` 디스패처의 `case` 한 줄)이 그 목록이고, 거기 없는 콜백은 모두 저장소 문맥까지 만든다(기본이 안전한 쪽).
  - 왜: `change` 는 `transform`(동기)이라 콜백이 도는 동안 fzf 가 다음 키를 받지 않는다. 전에는 모든 콜백이 `tmux
    display-message` + `repo_try` + `default_base` 로 프로세스 8개를 띄워 키마다 약 120ms 가 걸렸다(워크트리 95개. 1개여도
    90ms). 콜백 시간이 키 간격을 넘으면 입력이 쌓인다: 워크트리 61개에서 10타를 62ms 간격으로 치면 마지막 글자가 328ms 뒤에
    떴고(마커 목록이 끝난 뒤), 피커가 뜨자마자 치면(마커 계산·fetch 대기와 겹친다) 약 690ms 뒤였다. 지금은 각각 18ms,
    27ms 다. 남는 약 30ms 는 bash 기동과 스크립트를 읽는 비용이다(prefix S 의 `change`, `--cleanup-tick` 과 같다).
  - 규칙: 이 둘의 콜백은 상태 파일과 fzf 환경변수만 읽는다. git·tmux 를 띄우지 않고, 저장소 변수를 쓰지 않는다(비어 있어서
    `set -u` 로 죽는데, 죽은 콜백은 빈 줄을 낼 뿐이라 화면으로는 알기 어렵다). `result` 의 없는 경로 판정(`classify` 의 git
    한 번, 백그라운드)만 예외다. `test/tmux-dev/run` 이 가짜 git·tmux 를 PATH 앞에 두고 모드 × 검색어마다 확인한다.
  - 같이 고쳐진 것: `-t`·`--base` 로 띄운 피커에서 콜백은 그 값을 받지 못해 푸터·마커·미리보기가 기본 base 로 계산됐다
    (만들기만 `--base` 를 썼다). 이제 콜백·목록·미리보기·정리 작업이 모두 상태의 값을 본다.
  - 버린 안: (1) `change` 를 `bg-transform` 으로: 늦게 끝난 옛 검색어의 결과가 새 푸터를 덮는다(시험으로 확인). 막으려면
    `bg-cancel` 이 필요한데 그것은 fetch 대기도 끊는다(머지 판정 절). (2) worktree 모드에서 `change` 를 푼다: 검색어가 바뀌어도
    fzf 는 커서를 같은 순번에 두므로(시험으로 확인) `first` 가 필요하고, `change` 는 푸터의 일시 메시지를 지우는 일도 한다.
    "치는 동안 alt-enter 가 할 일을 푸터에 보인다"(session-picker.md)도 뒤집어야 한다. (3) `change` 만의 빠른 경로와 base
    캐시: 값의 출처가 둘이 된다.
- **브랜치·워크트리가 많은 저장소에서 입력이 멈추던 것 (2026-11-23).** 로컬 브랜치 1200 · 원격 1500 · 워크트리 40 에서
  잰 값(리눅스 4코어. macOS 는 프로세스 기동이 더 비싸 차이가 더 크다).
  - 목록이 브랜치 수의 제곱으로 느렸다: 행마다 이름 → 커밋을 브랜치 배열 전체 비교로 찾고(원격 1500 × 로컬 1200), 행마다
    `$(trim …)` 서브셸을 띄웠다. 마커 없는 첫 목록이 **11초**였다(그동안 목록이 비어 있다). 지금은 워크트리에 체크아웃된
    브랜치만 작은 표(`wt_branch`)로 찾고, 워크트리 없는 브랜치는 행과 커밋을 같은 인덱스로 두고, 원격 거르기는 awk 해시로,
    잘라내기는 `trim_to`(전역 `TRIM`)로 한다: **0.34초**, 출력은 바이트까지 같다.
  - 마커를 다시 읽을 때마다 브랜치마다 git 이 한두 번 떠서(캐시가 있어도 `rev-list --count`, `reflog`) 코어 수만큼 동시에 몇 초씩
    CPU 를 다 썼다. 그동안 키마다 도는 동기 콜백과 미리보기가 밀려 입력이 멈춘 것처럼 느껴졌다. 이제 (1) 브랜치 상태를
    `~/.cache/tmux-dev/marks/<브랜치 커밋>-<이름>` 에 "<기준 커밋> <상태>" 로 캐시해서, 워크트리 없는 브랜치는 캐시가 맞으면
    fork 하지 않는다(다시 읽기 4.7초 → 0.6초. 남은 것은 워크트리의 dirty). `+N` 만은 머지된 PR 목록이 새로 왔을 수 있어
    `pr_merged` 를 다시 본다. (2) `--list worktree --marks` 는 `renice -n 10` 으로 돈다(자식 git 도 물려받는다).
  - 키마다 도는 콜백이 스크립트 전체(1700줄 + lib 넷)를 읽느라 23ms 였다(빈 bash 2ms). `change`·`result`·`enter` 와 그것이 쓰는
    함수를 `lib/worktree-events.sh` 로 옮기고, 진입 스크립트 머리에서 common·picker·events 만 읽은 뒤 바로 처리하고 끝낸다
    (bash 는 읽는 대로 실행하므로 `exit` 뒤는 파싱하지 않는다). `change` 7ms, `enter` 37ms → 8ms(저장소 문맥이 필요 없었다:
    상태만 쓰고 `accept`). 위의 버린 안 (3)과 다른 점: 함수는 한 곳(events)에만 있고 값의 출처도 그대로 상태다.
  - 미리보기에 debounce(`sleep 0.12; …`). fzf 는 커서가 옮겨지면 돌던 미리보기를 끊으므로, 치는 동안에는 미리보기의 git
    (status, log, 머지 판정)이 아예 뜨지 않는다.
- **고친 경쟁 상태**: 목록 마커와 미리보기가 같은 patch-id 집합을 동시에 계산할 때 먼저 끝난 쪽의 `find -delete` 가 다른 쪽
  임시 파일을 지워 `mv` 가 실패(`set -e`)하고 목록이 통째로 비었다. 임시 파일(`<커밋>.<pid>`)은 정리 대상에서 빼고 `mv` 실패도 넘긴다.
- **시험**: 격리 tmux 서버(`tmux -L`) + `script` 가짜 클라이언트(stdin 은 끝나지 않는 파이프) + 임시 bare 원격·저장소 +
  `XDG_*_HOME` 임시 디렉토리. 피커는 창이나 modal 패널에 띄우고 `send-keys` / `capture-pane` 으로 본다. 함정: 다른 클론에서
  만든 커밋 cherry-pick 이 조용히 실패한다 → 같은 저장소에서 `checkout -b tmp origin/main; cherry-pick; push HEAD:main`.
- **자동 확인**: `test/tmux-dev/run` (저장소 맨 위. `home/` 밖이라 배포되지 않는다). tmux·fzf 없이 콜백만 실행해 자주 도는
  콜백의 규칙을 본다. 화면 동작은 위의 격리 서버 시험으로 본다.
  `test/tmux-dev/windows` 는 다른 소켓의 실제 tmux 서버와 버리는 저장소로 윈도우 찾기와 정리가 닫는 패널을 본다
  (fzf 없이 셸 호출과 `--cleanup-job` 으로. 피커 패널이 필요한 항목만 가짜 fzf 로 런처를 돌린다).
