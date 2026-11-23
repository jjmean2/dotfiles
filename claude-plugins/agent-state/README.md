# agent-state

Claude Code 가 지금 무엇을 하는지(작업 중·사람을 기다림·끝남·오류)를 **터미널 도구가 읽을 수 있게 기록**하고,
사람이 필요해지면 **터미널 알림**을 보내는 Claude Code 플러그인. 마켓플레이스 `justwonder` 에 있다.

Cursor CLI(`agent`)도 설치된 Claude 플러그인의 훅을 가져와 돌리므로 같은 플러그인으로 상태가 기록된다 (아래 "Cursor CLI").

훅은 보여 주는 방식을 정하지 않는다. 기록과 알림만 하고, 어떻게 보일지는 받는 쪽(tmux 탭, 상태바 앱, 스크립트)이 정한다.
설계와 계약 전체는 [`docs/agent-state.md`](../../docs/agent-state.md).

## 설치·제거

```sh
claude plugin marketplace update justwonder
claude plugin install agent-state@justwonder      # 제거: claude plugin uninstall agent-state@justwonder
```

새로 시작한 세션부터 적용된다. 지워도 남는 것은 임시 디렉터리의 레코드 파일뿐이고, 다음 `agent-state gc` 나 OS 의 임시 파일 정리가 치운다.

## 무엇을 하나

| 상태 | 뜻 | 들어가는 훅 |
|---|---|---|
| `idle` | 세션은 있고 할 일 없음 | `SessionStart` |
| `running` | 작업 중 | `UserPromptSubmit`, `PostToolUse`, `PostToolUseFailure` |
| `waiting` | 사람을 기다림 (`reason`: permission / question / plan / input) | `PermissionRequest`, `Notification` |
| `done` | 응답을 끝냄 | `Stop` |
| `error` | API 오류로 멈춤 (`reason`: 오류 종류) | `StopFailure` |
| (없음) | 세션이 끝남 | `SessionEnd` |

상태가 바뀔 때마다 세 곳에 낸다. 상태가 바뀌는 순간에만 일하고 상주 프로세스·주기 작업은 없다(에이전트를 많이 켜도 상시 비용이 늘지 않는다).

- **레코드 파일** `$(agent-state dir)/claude-<session>.json` — 아무 도구나 읽는 원본. macOS 는 사용자 임시 디렉터리, Linux 는 `$XDG_RUNTIME_DIR`.
- **tmux 패널 옵션** `@agent_state` `@agent_reason` `@agent_name` `@agent_pid` `@agent_since` — 자기 tmux 패널을 알 때만. tmux 포맷이 바로 읽는다.
- **자기 터미널로 OSC 9;4(진행 표시)** — 세션의 tty 에 직접 쓴다. 백그라운드 세션(`claude --bg`)이면 데몬이 지금 붙어 있는 패널로 넘겨 주고,
  tmux 는 그 패널의 `#{pane_pb_state}` 로 기억한다. 그래서 `claude attach`·agent view 로 붙은 패널에도 상태가 보인다
  (나중에 붙은 경우엔 다음 상태 변화부터).

`waiting`·`done`·`error` 로 바뀌면 알림을 보낸다(아래 옵션).

## Cursor CLI

따로 설치할 것이 없다. Cursor 는 `~/.claude/plugins` 에 설치된 Claude 플러그인을 가져오고(끄는 설정: `importThirdPartyPlugins`),
`hooks/hooks.json` 의 이벤트를 자기 이벤트로 바꿔 같은 명령을 부른다. 플러그인을 갱신할 때는 Claude 쪽에서 한다
(`claude plugin marketplace update justwonder` 뒤 `claude plugin update agent-state@justwonder` — Cursor 는 그 캐시 사본을 읽고, 새로 띄운 `agent` 부터 적용된다). 레코드는 `cursor-<conversation id>.json`, `@agent_name` 은 `cursor`.

| 상태 | 들어가는 Cursor 훅 (hooks.json 의 이름) |
|---|---|
| `idle` | `sessionStart` (SessionStart), 중단된 `stop` (status `aborted`) |
| `running` | `beforeSubmitPrompt` (UserPromptSubmit), `postToolUse` (PostToolUse) |
| `done` | `stop` (status `completed`) |
| `error` | `stop` (status `error`) |
| (없음) | `sessionEnd` (SessionEnd) |

Claude 와 다른 점 (Cursor CLI 2026.11.22 실측, 자세한 것은 설계 문서):

- **`waiting` 이 없다.** Cursor 에는 승인 창이 뜨는 순간을 알리는 훅이 없어서, 승인을 기다리는 동안에도 `running` 으로 보인다.
  대신 Cursor 가 스스로 터미널 알림을 보낸다("Approve command: …", 끝나면 "Cursor is waiting for you").
- 그래서 이 플러그인은 Cursor 에서는 **오류만 알린다** (끝남 알림은 Cursor 것과 겹친다).
- 옵션은 환경 변수로 준다: `AGENT_STATE_NOTIFY_ON`, `AGENT_STATE_NOTIFY_VIA` (Claude 의 플러그인 옵션은 Cursor 에 전달되지 않는다).

## 옵션

`/config` 의 플러그인 항목이나 `/plugin configure agent-state@justwonder` 로 바꾼다.

| 옵션 | 값 | 기본 |
|---|---|---|
| `notify_on` | `all`(대기·끝남·오류) / `attention`(대기·오류만) / `off` | `all` |
| `notify_via` | `osc9`(데스크톱 알림. iTerm2·Ghostty·WezTerm) / `osc777`(제목 따로. Ghostty·foot) / `bell`(벨) | `osc9` |

tmux 안에서는 알림 이스케이프를 패스스루로 감싸 보낸다. tmux 의 `allow-passthrough` 가 `all` 이어야 안 보이는 윈도우의 알림도 나간다
(`on` 은 보이는 패널만).

## CLI

`bin/agent-state` 는 Claude 세션 안에서는 PATH 에 있다. 셸에서는 플러그인 경로로 부른다.

```sh
agent-state list            # STATE AGENT REASON AGE PANE CWD
agent-state list --json     # 레코드 원문 (한 줄에 하나)
agent-state emit waiting --agent codex --reason input   # 다른 에이전트·스크립트용 입구
agent-state gc              # 주인 프로세스가 죽은 레코드·패널 표시 지우기
```

## 시험

`test/run` 이 가짜 훅 입력(Claude·Cursor)으로 번역 결과를 확인한다. 실제 에이전트는 부르지 않는다.

## 한계

- **허락 창에 답하는 순간에는 훅이 없다** (2.1.327 실측). 승인하면 그 도구가 끝날 때(`PostToolUse`)까지 `waiting` 이 남고,
  Esc 로 거절하거나 작업 도중 중단하면 다음 프롬프트까지 `waiting`/`running` 이 남는다. tmux 쪽에는 지금 패널의 표시를 지우는 키가 있다.
- 패널 안 Claude 가 띄운 `claude -p` 같은 중첩 세션은 같은 tmux 패널을 물려받지만, 패널의 주인(`@agent_pid`)이 살아 있으면 패널 표시와
  알림은 건드리지 않는다(레코드 파일은 따로 남는다).
