# agent-state: 에이전트 진행 상태를 보이게 하기

Claude Code 를 여러 tmux 윈도우·패널에 띄워 두면 어느 것이 끝났고 어느 것이 나를 기다리는지 돌아다니며 봐야 한다.
agent-state 는 에이전트의 상태를 **한 번 기록하고**, 그것을 **여러 도구가 각자 보여 주게** 하는 구조다.

- 만드는 쪽: Claude Code 플러그인 [`claude-plugins/agent-state`](../claude-plugins/agent-state/README.md) (훅 + `bin/agent-state`)
- 받는 쪽: tmux 어댑터 `home/dot_config/tmux/plugins/agent-state` (탭·패널 테두리 표시, 키), 터미널 알림, 그 밖에 레코드를 읽는 아무 도구

2026-11-19 에 정한 설계다. 근거가 된 실측은 Claude Code 2.1.327, tmux 3.8 기준 (Ghostty 1.4.0 은 문서만 확인).

## 정한 것과 기본값

| 질문 | 기본값 | 바꾸는 곳 |
|---|---|---|
| 다른 데서 그 패널로 들어오면 `done` 표시를 지울까 | 지운다 (tmux `pane-focus-in`) | `@agent-state-clear-on-focus off` |
| 알림을 언제 보낼까 | 대기·끝남·오류 모두 (`all`) | 플러그인 옵션 `notify_on` (`attention` = 대기·오류만, `off`) |
| 알림을 무엇으로 보낼까 | OSC 9 데스크톱 알림 | 플러그인 옵션 `notify_via` (`osc777`, `bell`) |
| 이름, jw 와 분리 | `agent-state`, 별도 플러그인 | — |

예전 jw 플러그인의 `tmux-bell` 훅(끝나면 벨)은 이것으로 대체한다. 벨은 다시 "일반 프로그램의 벨"(tmux `!` 와 노란 탭)로만 쓰이고,
에이전트 상태는 따로 생긴 아이콘으로 보인다. 예전처럼 벨을 원하면 `notify_via = bell`.

## 원칙

1. **훅은 상태를 알리고, 표현은 받는 쪽이 정한다.** 훅이 하는 일은 이벤트를 공통 상태로 번역 → 기록 → 알림 보내기뿐이다.
   탭 색이나 아이콘은 tmux 설정이 정한다. 그래서 보여 주는 도구가 바뀌어도 훅은 그대로다.
2. **어느 단위도 다른 단위 없이 조용히 동작한다.** 플러그인만 있으면 기록만 쌓이고, tmux 어댑터만 있으면 아무것도 그리지 않는다.
3. **도구 호출마다 불리는 길은 싸게.** 상태가 그대로면 셸 내장 명령만으로 끝낸다(실측 평균 8.5 ms, 바뀔 때 36 ms).
4. **실패는 조용히.** 훅은 늘 exit 0. 에이전트를 붙잡거나 오류를 띄우지 않는다.

```
 [만드는 쪽]                 [계약]                          [받는 쪽]
 Claude Code 훅 ──┐                                       ┌─ tmux: 탭 배지·패널 테두리·키
 (다른 에이전트) ─┼→ agent-state ─→ 레코드 파일  ──────────┼─ 아무 도구: list / 파일 감시
 스크립트(emit) ──┘   (번역·기록)  + tmux 패널 옵션         └─ 터미널: OSC 9 알림 (패스스루)
```

## 계약 (v1)

### 상태 어휘

| 상태 | 뜻 | 사람이 할 일 |
|---|---|---|
| `idle` | 세션은 살아 있고 할 일 없음 | 없음 |
| `running` | 작업 중 | 없음 |
| `waiting` | 사람을 기다림. `reason`: `permission` / `question` / `plan` / `input` | **지금 필요** |
| `done` | 응답을 끝냄 (아직 안 봤을 수 있음) | 확인 |
| `error` | API 오류로 멈춤. `reason`: 오류 종류 | 확인 |
| 레코드 없음 | 에이전트 없음, 또는 정보 없음 | — |

### 레코드 파일

경로: `agent-state dir` 이 알려 준다.

- `$AGENT_STATE_DIR` 가 있으면 그것.
- Linux: `$XDG_RUNTIME_DIR/agent-state` (메모리 tmpfs, 로그아웃하면 사라짐).
- macOS: `getconf DARWIN_USER_TEMP_DIR` 아래 `agent-state` (`/var/folders/…/T/agent-state`). `$TMPDIR` 대신 시스템에 직접 묻는 이유는
  프로세스(샌드박스 등)마다 `$TMPDIR` 가 다를 수 있어서다.

`XDG_STATE_HOME` 이 아닌 이유: 재부팅 뒤에 남아야 하는 상태(히스토리·로그)의 자리이고, 에이전트의 지금 상태는 프로세스가 살아 있을 때만
의미가 있다. 쓰기 양은 상태가 바뀔 때 한 번(턴당 2~4번)이라 SSD 수명과 무관하다.

macOS 는 dirhelper 가 매일 03:35 에 3일 넘은 임시 파일을 지운다(`/System/Library/LaunchDaemons/com.apple.bsd.dirhelper.plist`).
그래서 쓰는 쪽은 매번 디렉터리를 만들고, 읽는 쪽은 "레코드 없음 = 정보 없음" 으로 다룬다. tmux 표시는 파일이 아니라 패널 옵션을 읽으므로
영향이 없고, 다음 이벤트에서 파일이 다시 생긴다.

파일 이름 `<agent>-<session>.json`, 내용은 JSON 한 줄. 임시 파일에 쓰고 `mv` 로 바꿔치기한다. 첫 필드는 늘 `state`.

```json
{"v":1,"state":"waiting","reason":"permission","agent":"claude","session":"7dbc…","pid":69058,
 "tmux_pane":"%12","cwd":"/…/dotfiles","since":1763520000,"transcript":"/…/7dbc….jsonl"}
```

`pid` 가 죽어 있으면 낡은 레코드다. `agent-state gc`(세션이 시작할 때도 돈다)가 지운다.

### tmux 패널 옵션

tmux 안이면 레코드와 같은 내용을 **그 에이전트가 떠 있는 패널**의 사용자 옵션에도 쓴다. tmux 포맷은 파일을 읽지 못하고 폴링은 느려서다.

| 옵션 | 값 |
|---|---|
| `@agent_state` | 상태 어휘 |
| `@agent_reason` | 이유 (없으면 빈 값) |
| `@agent_name` | `claude` 등 |
| `@agent_pid` | 패널의 **주인** 프로세스 |
| `@agent_since` | 상태가 바뀐 시각 (epoch 초) |

**패널 주인.** 패널 안 Claude 가 Bash 로 띄운 `claude -p` 도 같은 `$TMUX_PANE` 을 물려받는다(실측: 중첩 세션이 같은 패널에서
`SessionStart`…`SessionEnd` 를 낸다). 그래서 패널 옵션과 알림은 `@agent_pid` 가 비었거나, 자기 자신이거나, 죽은 프로세스일 때만 쓴다.
주인은 session id 가 아니라 **claude 프로세스 pid** 다. `/clear` 는 session id 를 바꾸지만 pid 는 그대로이기 때문이다.
훅의 부모 프로세스가 claude 자신이라 `$PPID` 로 얻는다(실측).

## Claude Code 훅 대응

| 훅 | 상태 | 실측으로 확인한 것 |
|---|---|---|
| `SessionStart` (startup·resume·clear) | `idle` + 낡은 레코드 정리 | `/clear` 는 `SessionEnd(clear)` 다음 새 session id 로 온다 |
| `SessionStart` (compact) | 그대로 | `/compact`·자동 압축 때 온다. 작업 도중일 수 있어 초기화하면 안 된다 |
| `UserPromptSubmit` | `running` | |
| `PreToolUse`, `PostToolUse`, `PostToolUseFailure` | `running` | 허락·질문에 답한 뒤 다시 작업 중으로 돌아오는 길 |
| `PermissionRequest` | `waiting` (`tool_name` 이 AskUserQuestion → `question`, ExitPlanMode → `plan`, 그 밖 → `permission`) | 창이 뜨는 즉시 온다. 질문 도구도 이 훅으로 온다. auto 모드에서 자동 승인되면 오지 않는다. 승인·거절에는 훅이 없다(아래 공백) |
| `Notification` permission_prompt | `waiting` (이미 waiting 이면 그대로) | 창이 뜨고 약 6초 뒤. 예비로만 쓴다 |
| `Notification` elicitation_dialog·elicitation_url_dialog·agent_needs_input | `waiting` (`input`) | |
| `Stop` | `done` | |
| `StopFailure` | `error` (`reason` = 오류 종류) | |
| `SessionEnd` | 레코드·패널 표시 제거 (clear 면 패널은 다음 SessionStart 가 덮음) | |
| `SubagentStop` | 쓰지 않는다 | `Stop` 뒤에 따로 온다 |

**알려진 공백.** 사람이 허락 창에 답하는 순간에는 훅이 없다. 그래서 세 경우에 표시가 실제보다 늦거나 남는다.

| 경우 | 오는 훅 | 표시 |
|---|---|---|
| 허락 창에서 **승인** | 없음. 승인한 도구가 **끝나야** `PostToolUse` | 그 도구가 도는 동안 `waiting` 이 남는다 (`ping -c 12` 승인 → 16초 동안 waiting, 실측) |
| 허락 창에서 Esc 로 **거절** | 없음 | `waiting` 이 다음 프롬프트까지 남는다 |
| 작업 도중 **중단** (이 설정에서는 Option+q) | 없음 | `running` 이 다음 프롬프트까지 남는다 |

거절·중단 뒤에는 `Stop` 도 `PostToolUseFailure` 도, 2분 넘게 기다려도 `idle_prompt` 도 오지 않았다. 터미널 제목도 바뀌지 않는다.
대화 기록 파일에는 `[Request interrupted by user…]` 가 남지만 내부 형식이라 기대지 않는다. 셋 다 사람이 그 패널에서 직접 하는 일이므로
다음 이벤트(도구 끝, 다음 프롬프트)에서 바로잡히고, tmux 에는 지금 패널의 표시를 지우는 키를 둔다. 승인 직후를 메우는 방법(그 패널에서
나갈 때 `waiting` 을 지우기 등)은 진짜 대기를 놓칠 수 있어 넣지 않았다.

**패널과 파일이 어긋날 때.** tmux 쪽의 "봤다" 처리(focus-in 으로 `done` → `idle`, 지우기 키)는 패널 옵션만 바꾸고 레코드 파일은 그대로 둔다.
"봤는지" 는 보는 도구마다 다른 일이라서다. 그래서 `agent-state list` 는 tmux 와 다를 수 있다. 훅은 `UserPromptSubmit` 에서는 같은 상태여도
늘 다시 써서, 손으로 지운 패널도 다음 턴에 바로잡는다.

## 알림

`waiting`·`done`·`error` 로 **바뀔 때만** 보낸다(같은 상태가 다시 와도 한 번). 주인이 아닌 중첩 세션은 보내지 않는다.

| `notify_via` | 바이트 | 받는 터미널 |
|---|---|---|
| `osc9` (기본) | `ESC ] 9 ; Claude · dotfiles: Needs permission: Bash BEL` | iTerm2, Ghostty, WezTerm, Windows Terminal |
| `osc777` | `ESC ] 777 ; notify ; Claude · dotfiles ; Finished BEL` | Ghostty, urxvt, foot |
| `bell` | `BEL` | 모든 터미널. tmux 는 `!` 플래그 |

터미널 이스케이프라서 터미널 종류도, ssh 너머인지도 가리지 않는다. 쓰는 곳은 패널의 tty(tmux 안, `#{pane_tty}`) 또는 claude 프로세스의 tty다.
훅의 stdout 은 Claude Code 가 가져가서 화면에 닿지 않는다.

tmux 안에서는 OSC 를 DCS 패스스루(`ESC P tmux; … ESC \`, 안쪽 ESC 는 두 번)로 감싼다. tmux 의 `allow-passthrough` 에 따라 (격리 서버 실측):

| allow-passthrough | 보이는 패널 | 안 보이는 패널 |
|---|---|---|
| `off` (기본) | 버림 | 버림 |
| `on` | 전달 | **버림** |
| `all` | 전달 | 전달 |

뒤쪽 윈도우의 에이전트가 알리게 하려면 `all` 이어야 한다. `all` 은 패널 안 프로그램이 보이지 않을 때도 바깥 터미널에 이스케이프를 보낼 수
있게 넓히는 설정이다(이 머신의 패널은 내가 띄운 프로그램뿐이라 받아들인다).

Ghostty 쪽(실제 알림 배너가 뜨는지, 창에 포커스가 있을 때도 뜨는지)은 이 저장소에서 자동으로 확인하지 못했다. 손으로 확인하는 법:
tmux 안 아무 패널에서 `printf '\ePtmux;\e\e]9;agent-state test\a\e\\'`.

## tmux 표시

### 배지

패널 옵션은 패널마다 있으므로 **탭(윈도우 포맷)에서는 `#{P:…}` 로 그 윈도우의 모든 패널을 훑는다.** 그냥 `#{@agent_state}` 를 쓰면
활성 패널 값만 읽혀 다른 패널의 Claude 를 놓친다(실측). 패널을 닫거나 다른 윈도우로 빼도(`break-pane`) 옵션이 패널을 따라가므로
따로 맞출 것이 없다. `#{P:a,b}` 의 쉼표는 "활성 패널용 포맷" 구분자라 구분자로는 공백을 쓴다.

- 탭: 가장 급한 상태 하나. 우선순위 `waiting` > `error` > `done` > `running`. 대기가 둘 이상이면 개수를 붙인다(`◆2`).
  보고 있는 윈도우의 탭에도 나온다(tmux 의 벨 `!` 는 보고 있는 윈도우에는 붙지 않는다 — `bell-action any` 로도. 실측).
- 패널 테두리(`pane-border-format`): 그 패널의 상태. 윈도우 안에서 어느 패널인지 보인다.

| 상태 | 아이콘 (기본) | 색 (기본) |
|---|---|---|
| running | `⋯` | 탭 글자색 그대로 |
| waiting | `◆` | 노랑 `#f9e2af` (벨 탭과 같은 계열) |
| done | `✔` | 초록 `#a6e3a1` |
| error | `✘` | 빨강 `#f38ba8` |

아이콘·색은 `@agent-state-icon-<상태>`, `@agent-state-color-<상태>` 로 바꾼다. 어댑터가 만드는 포맷 조각은 `@agent_badge`(탭),
`@agent_pane_badge`(패널 테두리)이고, tmux.conf 의 포맷이 `#{E:@agent_badge}` 처럼 꺼내 쓴다. 어댑터를 빼면 조각이 비어 아무것도 그리지 않는다.

### 끄기와 키

- `done` 은 다른 데서 그 패널로 **들어올 때** 지운다(`pane-focus-in` 훅, `idle` 로). 이미 보고 있는 패널에서 끝났으면 다음 프롬프트까지 남는다.
  "봤다" 가 아니라 "들어왔다/답했다" 기준이다. 다른 앱에서 터미널 창으로 돌아올 때도 tmux 가 focus-in 을 받으므로(`focus-events on`)
  그때도 지워질 것으로 보지만 실제로는 확인하지 않았다.
- `waiting` 은 들어와도 지우지 않는다. 다음 훅(`PostToolUse`·`UserPromptSubmit`)이 와야 바뀐다. 승인한 도구가 오래 돌면 그동안 남는다(위 공백).
- `prefix a`: 나를 기다리는 다음 패널로 간다(waiting → error → done 순, 오래된 것부터, 지금 패널 제외). 세션이 달라도 간다.
  대기가 둘 이상이면 대기끼리 오가고, 대기를 다 풀어야 끝남·오류로 간다(가장 급한 것부터라서).
- `prefix M-a`: 지금 패널의 표시를 지운다(`idle`). 위 "알려진 공백" 용.
- 키는 `@agent-state-jump-key`, `@agent-state-clear-key` 로 바꾸고, 빈 값이면 묶지 않는다.

## 설치와 제거

| 단위 | 설치 | 제거 |
|---|---|---|
| Claude 플러그인 | `claude plugin marketplace update justwonder` → `claude plugin install agent-state@justwonder` | `claude plugin uninstall agent-state@justwonder` |
| tmux 어댑터 | chezmoi 가 배포. tmux.conf 의 `run-shell …/agent-state.tmux` 한 줄 | 그 줄과 포맷의 `#{E:@agent_badge}` 를 지우고 `prefix R` |

tmux 어댑터는 모든 머신에 둔다. 플러그인이 없는 머신에서는 패널 옵션이 비어 아무것도 그리지 않으므로 머신별 기능 스위치를 두지 않는다
(설정은 모든 머신에 같게, 갈리는 것은 깔았을 때 무언가 일어나는 것뿐 — [`docs/machines.md`](machines.md)). Claude 의 `settings.json` 은 chezmoi 가 관리하지 않으므로 플러그인 설치는 머신마다 한 번 손으로 한다.

## 다른 에이전트 붙이기

`agent-state emit <상태> --agent <이름> [--session S] [--reason R] [--pid P]` 가 일반 입구다. 예: Codex 의 `notify` 설정(턴이 끝날 때
프로그램을 부른다)에 `agent-state emit done --agent codex` 를 건다. 상태 어휘와 패널 옵션이 같으면 tmux 표시는 그대로 동작한다.

## 검증 방법

- 이벤트 순서: 기록만 하는 훅 플러그인을 `claude --plugin-dir` 로 올려 격리 tmux 서버(`tmux -L <이름> -f /dev/null`)의 패널에서
  진짜 Claude 를 띄우고 `send-keys` 로 조작했다. 중단 키는 사용자 설정이 Option+q 라 `M-q`, vim 입력 모드에서는 Esc 가 모드 전환에 먹힌다.
- 단위: 같은 격리 서버에서 가짜 훅 입력을 `bin/agent-state hook claude` 에 넣고 패널 옵션·파일·클라이언트 출력을 본다.
  클라이언트는 `script -q -F <로그> tmux attach` 로 붙인다(`-F` 가 없으면 출력이 늦게 써져 패스스루가 안 온 것처럼 보인다).

## 후속 후보

- OSC 9;4 진행 표시(`running` 동안 불확정 막대. Ghostty `progress-style` 기본 켜짐).
- tmux-dev S·W 피커에 세션·윈도우별 상태 열.
- 중단(공백)을 대화 기록으로 감지하는 감시자 — 내부 형식에 기대므로 보류.
