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
3. **상태가 바뀌는 순간에만 일한다.** 상주 프로세스·주기 작업(폴링, `#()`)이 없어서 에이전트를 몇 개 켜든 늘어나는 상시 비용이 없다.
   도구 호출마다 불리는 훅은 `PostToolUse` 하나이고 상태가 그대로면 셸 내장 명령만으로 끝낸다(실측 평균 7.4 ms, 바뀔 때 32 ms).
   빈틈 없이 맞추는 것보다 이쪽을 앞에 둔다(개인용 도구라서 — 2026-11-19 사용자 결정).
4. **실패는 조용히.** 훅은 늘 exit 0. 에이전트를 붙잡거나 오류를 띄우지 않는다.

```
 [만드는 쪽]                 [계약]                             [받는 쪽]
 Claude Code 훅 ──┐               ┌─ ① 레코드 파일 ─────────── 아무 도구: list / 파일 감시
 (다른 에이전트) ─┼→ agent-state ─┼─ ② tmux 패널 옵션 ──────┐
 스크립트(emit) ──┘   (번역)      └─ ③ 자기 tty 로 OSC 9;4 ──┴─ tmux: 탭 배지·상태바·패널 테두리·모아 보기
                                       + OSC 9 알림              (③ 은 #{pane_pb_state} 로)
```

②는 훅이 자기 패널(`$TMUX_PANE`)을 알 때만 쓸 수 있다. ③은 패널을 몰라도 된다: 세션의 화면 출력에 섞여 흐르므로, tmux 패널에서 직접 띄운
세션이면 그 패널로, **백그라운드 세션(`claude --bg`)이면 데몬이 지금 붙어 있는 패널로** 간다. tmux 어댑터는 ②가 있으면 ②를, 없으면 ③을 읽는다.

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
 "tmux_pane":"%12","tty":"/dev/ttys012","cwd":"/…/dotfiles","since":1763520000,"transcript":"/…/7dbc….jsonl"}
```

`tty` 는 ③을 낼 터미널이다. tmux 패널이면 그 패널 tty, 아니면 claude 프로세스의 tty 를 세션마다 **한 번만** `ps` 로 찾아 여기 둔다
(`none` = 찾아봤는데 없음). 그 뒤로는 상태가 바뀔 때 `printf` 한 번이다.

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

### 터미널 진행 표시 (OSC 9;4)

상태를 터미널 표준 진행 표시 이스케이프(ConEmu OSC 9;4)에 실어 자기 tty 에 쓴다. tmux 3.8 은 이것을 패널마다 `#{pane_pb_state}` 로 기억한다.

| 상태 | 이스케이프 | `pane_pb_state` |
|---|---|---|
| running | `ESC ] 9;4;3 BEL` | indeterminate |
| waiting | `ESC ] 9;4;4 BEL` | paused |
| error | `ESC ] 9;4;2 BEL` | error |
| done | `ESC ] 9;4;1;100 BEL` | normal |
| idle, 끝 | `ESC ] 9;4;0 BEL` | hidden |

- 이유(`reason`)는 실리지 않는다. 모아 보기의 이유 칸은 ②가 있는 패널에만 나온다.
- tmux 밖에서 Claude Code 가 스스로 진행 표시를 하는 터미널(Ghostty·iTerm2, `TERM_PROGRAM` 으로 안다)에서는 쓰지 않는다. Claude 의
  `terminalProgressBarEnabled` 와 겹친다. tmux 안과 백그라운드 세션에서는 Claude 가 진행 표시를 내지 않았다(실측).
- 훅 출력의 `terminalSequence`(Claude Code 가 대신 내 주는 공식 길)를 먼저 시험했지만 2.1.328 은 OSC 9;4 를 걸러 내고 벨만 내보냈다
  (직접 띄운 세션·백그라운드 세션 모두). 그래서 tty 에 직접 쓴다.
- 다른 프로그램이 낸 OSC 9;4 도 tmux 에서는 에이전트로 보인다. 원치 않으면 `@agent-state-progress off`(②만 읽는다).

## Claude Code 훅 대응

| 훅 | 상태 | 실측으로 확인한 것 |
|---|---|---|
| `SessionStart` (startup·resume·clear) | `idle` + 낡은 레코드 정리 | `/clear` 는 `SessionEnd(clear)` 다음 새 session id 로 온다 |
| `SessionStart` (compact) | 그대로 | `/compact`·자동 압축 때 온다. 작업 도중일 수 있어 초기화하면 안 된다 |
| `UserPromptSubmit` | `running` | |
| `PostToolUse`, `PostToolUseFailure` | `running` | 허락·질문에 답한 뒤 다시 작업 중으로 돌아오는 길. `PreToolUse` 는 걸지 않는다: running 은 `UserPromptSubmit` 이 이미 켰고, 걸면 도구 호출마다 훅이 둘이 된다 |
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

**백그라운드 세션의 공백.** ③은 상태가 바뀌는 순간 그때 붙어 있던 패널에만 간다(실측, `claude attach` 로 붙여 시험).

| 경우 | 표시 |
|---|---|
| 붙어 있는 동안 상태가 바뀜 | 바로 반영 (running → paused → running → normal 확인) |
| 이미 대기·끝남인 세션에 **나중에 붙음** (agent view 에서 들어감) | 다시 오지 않아 다음 상태 변화까지 표시 없음 |
| ← 로 agent view 에 나가거나 다른 세션으로 옮김 | 앞 세션의 표시가 패널에 남음 → `prefix M-A` 로 지운다 |

메우는 방법으로 "세션마다 몇 초마다 다시 보내는 상주 프로세스" 를 검토했지만 에이전트 수만큼 상시 비용이 늘어 넣지 않았다(원칙 3).
패널 쪽에서 지금 어느 세션을 보는지 알아낼 단서도 없다: 붙기 클라이언트는 데몬에만 연결되고(소켓 상대가 데몬), agent view 에서는 프로세스가
`claude agents` 하나로 세션을 갈아 끼우며, `claude agents --json`·데몬의 attach-journal 에도 붙은 클라이언트가 없다(2.1.328 실측).
알림도 같다: 백그라운드 세션은 붙은 쪽이 tmux 인지 모르므로 맨 OSC 와 패스스루로 감싼 것을 둘 다 내지만, 붙은 패널이 없으면 받을 곳이 없다.

**패널과 파일이 어긋날 때.** tmux 쪽의 "봤다" 처리(focus-in 으로 `done` → `idle`, 지우기 키)는 패널만 바꾸고 레코드 파일은 그대로 둔다
(②가 있는 패널은 `@agent_state` 를 idle 로, ③만 있는 패널은 그 패널 tty 에 `9;4;0` 을 써서 진행 표시를 지운다 — `bin/agent-state-ack`).
"봤는지" 는 보는 도구마다 다른 일이라서다. 그래서 `agent-state list` 는 tmux 와 다를 수 있다. 훅은 `UserPromptSubmit` 에서는 같은 상태여도
늘 다시 써서, 손으로 지운 패널도 다음 턴에 바로잡는다.

## 알림

`waiting`·`done`·`error` 로 **바뀔 때만** 보낸다(같은 상태가 다시 와도 한 번). 주인이 아닌 중첩 세션은 보내지 않는다.

| `notify_via` | 바이트 | 받는 터미널 |
|---|---|---|
| `osc9` (기본) | `ESC ] 9 ; Claude · dotfiles: Needs permission: Bash BEL` | iTerm2, Ghostty, WezTerm, Windows Terminal |
| `osc777` | `ESC ] 777 ; notify ; Claude · dotfiles ; Finished BEL` | Ghostty, urxvt, foot |
| `bell` | `BEL` | 모든 터미널. tmux 는 `!` 플래그 |

터미널 이스케이프라서 터미널 종류도, ssh 너머인지도 가리지 않는다. 쓰는 곳은 ③과 같은 tty(레코드의 `tty`)다.
훅의 stdout 은 Claude Code 가 가져가서 화면에 닿지 않는다.

tmux 는 패널이 낸 맨 OSC 9·777 을 바깥으로 넘기지 않고 버린다(실측). 그래서 tmux 패널에서는 OSC 를 DCS 패스스루(`ESC P tmux; … ESC \`,
안쪽 ESC 는 두 번)로 감싼다. 백그라운드 세션은 맨 것과 감싼 것을 둘 다 낸다(tmux 에 붙었으면 감싼 것이, tmux 밖 터미널에 붙었으면 맨 것이 간다). tmux 의 `allow-passthrough` 에 따라 (격리 서버 실측):

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

패널의 상태는 어댑터가 만드는 식 `@agent_st` 다: 패널 옵션 `@agent_state` 가 있으면 그것, 없으면 `#{pane_pb_state}` 를 상태로 바꾼 것
(indeterminate → running, paused → waiting, error → error, normal → done). 아래 모든 표시와 키가 이 식을 쓴다.

패널 옵션은 패널마다 있으므로 **탭(윈도우 포맷)에서는 `#{P:…}` 로 그 윈도우의 모든 패널을 훑는다.** 그냥 `#{@agent_state}` 를 쓰면
활성 패널 값만 읽혀 다른 패널의 Claude 를 놓친다(실측). 패널을 닫거나 다른 윈도우로 빼도(`break-pane`) 옵션이 패널을 따라가므로
따로 맞출 것이 없다. `#{P:a,b}` 의 쉼표는 "활성 패널용 포맷" 구분자라 구분자로는 공백을 쓴다.

- 탭: 가장 급한 상태 하나. 우선순위 `waiting` > `error` > `done` > `running`. 대기가 둘 이상이면 개수를 붙인다(`◆2`).
  보고 있는 윈도우의 탭에도 나온다(tmux 의 벨 `!` 는 보고 있는 윈도우에는 붙지 않는다 — `bell-action any` 로도. 실측).
- 탭 바탕: 대기·오류가 있는 **비활성** 탭은 바탕 전체를 노랑·빨강으로 칠한다(벨 탭과 같은 강도). 보고 있는 탭은 "여기" 를 보여 주는
  원래 색 그대로 두고 아이콘만 색으로. 칠한 탭에서는 아이콘·플래그에 색을 입히지 않는다(바탕과 같은 색이라 묻혀서).
  tmux.conf 의 `window-status-style` 이 `@agent_tab_style` 이 비었으면 원래 색을 쓴다. `@agent-state-tab-paint off` 로 끈다.
- 상태바 요약(`status-right`, 시각 앞): **모든 세션**을 통틀어 상태별 개수 `◆2 ✘1 ✔1 ⋯3`(0 인 것은 뺀다). `#{S:#{W:#{P:…}}}` 로 훑는다.
  탭에는 지금 세션의 윈도우만 보이므로, 다른 세션(다른 프로젝트)의 에이전트가 기다리는 것은 여기서 보인다.
- 패널 테두리(`pane-border-format`): 그 패널의 상태. 윈도우 안에서 어느 패널인지 보인다.

다시 그리기: 뒤쪽 윈도우의 패널 옵션만 바뀌어도 tmux 는 상태줄을 곧바로 다시 그린다(220칸 클라이언트로 실측, 0.6초 안에 노란 바탕 출력).
시험할 때 주의: `script` 로 붙인 클라이언트는 기본 80칸이라 긴 status-right 가 탭 목록을 밀어내 탭 글자가 안 보인다 — `stty cols 220` 으로 넓힌다.

| 상태 | 아이콘 (기본) | 색 (기본) |
|---|---|---|
| running | `⋯` | 탭 글자색 그대로 |
| waiting | `◆` | 노랑 `#f9e2af` (벨 탭과 같은 계열) |
| done | `✔` | 초록 `#a6e3a1` |
| error | `✘` | 빨강 `#f38ba8` |

아이콘·색은 `@agent-state-icon-<상태>`, `@agent-state-color-<상태>` 로 바꾼다. 어댑터가 만드는 포맷 조각은 `@agent_badge`(탭),
`@agent_tab_style`(탭 바탕), `@agent_summary`(상태바), `@agent_pane_badge`(패널 테두리)이고, tmux.conf 의 포맷이 `#{E:@agent_badge}` 처럼
꺼내 쓴다. 어댑터를 빼면 조각이 비어 아무것도 그리지 않는다.

### 모아 보기 (`prefix a`)

tmux 기본 `choose-tree` 를 floating pane 에 띄운다(tmux man 의 `new-pane -E; choose-tree -hk` 꼴, 크기·스타일은 `@float-*` 를 따른다).

- `-f '#{E:@agent_st}'`(패널 옵션 또는 진행 표시에서 읽은 상태): 에이전트가 있는 패널만. 그런 패널이 없는 윈도우·세션은 트리에서 빠진다.
- `-F`: 패널 줄 = `◆ waiting (permission)  /경로`, 윈도우·세션 줄 = 이름. 아이콘과 상태 글자는 상태바와 같은 색(`@agent-state-color-*`)이다.
  `choose-tree` 도 줄을 `format_draw()` 로 그려서 `#[fg=…]` 가 먹는다(tmux `mode-tree.c`). 커서가 있는 줄은 선택 색이 이겨 색이 빠진다.
- 아래쪽 미리보기, 숫자키 바로 고르기, Enter 로 이동(다른 세션이어도), `C-s` 찾기, `q` 닫기. 고르면 floating pane 은 닫힌다(`-k`).
- 한계: 정렬은 tmux 가 번호·이름·활동 시각만 지원해 "대기 먼저" 는 안 된다. 그건 `prefix M-a`(바로 가기) 몫이다.

키 `prefix C-a` 는 쓰지 않는다. 이미 "C-a 글자를 패널로 보내기"(`send-prefix -2`)다.

### 끄기와 키

- `done` 은 다른 데서 그 패널로 **들어올 때** 지운다(`pane-focus-in` 훅, `idle` 로). 이미 보고 있는 패널에서 끝났으면 다음 프롬프트까지 남는다.
  "봤다" 가 아니라 "들어왔다/답했다" 기준이다. 다른 앱에서 터미널 창으로 돌아올 때도 tmux 가 focus-in 을 받으므로(`focus-events on`)
  그때도 지워질 것으로 보지만 실제로는 확인하지 않았다.
- `waiting` 은 들어와도 지우지 않는다. 다음 훅(`PostToolUse`·`UserPromptSubmit`)이 와야 바뀐다. 승인한 도구가 오래 돌면 그동안 남는다(위 공백).
- `prefix a`: 모아 보기 (위).
- `prefix M-a`: 나를 기다리는 다음 패널로 바로 간다(waiting → error → done 순, 오래된 것부터, 지금 패널 제외). 세션이 달라도 간다.
  대기가 둘 이상이면 대기끼리 오가고, 대기를 다 풀어야 끝남·오류로 간다(가장 급한 것부터라서).
- `prefix M-A`: 지금 패널의 표시를 지운다(②는 `idle` 로, ③은 진행 표시를 hidden 으로). 위 "알려진 공백"·백그라운드 세션의 남은 표시용.
- 키는 `@agent-state-tree-key`, `@agent-state-jump-key`, `@agent-state-clear-key` 로 바꾸고, 빈 값이면 묶지 않는다.
  (2026-11-19 첫 판은 `prefix a` = 바로 가기, `prefix M-a` = 지우기였다. 모아 보기를 넣으며 한 칸씩 밀었다.)

## 설치와 제거

| 단위 | 설치 | 제거 |
|---|---|---|
| Claude 플러그인 | `claude plugin marketplace update justwonder` → `claude plugin install agent-state@justwonder` | `claude plugin uninstall agent-state@justwonder` |
| tmux 어댑터 | chezmoi 가 배포. tmux.conf 의 `run-shell …/agent-state.tmux` 한 줄 | 그 줄과 포맷의 `#{E:@agent_*}` 를 지우고 `prefix R` |

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

- tmux 가 받은 OSC 9;4 를 바깥 Ghostty 로도 넘기기(`terminal-features` 의 `progressbar`) — Ghostty 탭에도 진행 표시가 생긴다. 시험 안 함.
- tmux-dev S·W 피커에 세션·윈도우별 상태 열.
- 중단(공백)을 대화 기록으로 감지하는 감시자 — 내부 형식에 기대므로 보류.
