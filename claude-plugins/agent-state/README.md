# agent-state

Claude Code 가 지금 무엇을 하는지(작업 중·사람을 기다림·끝남·오류)를 **터미널 도구가 읽을 수 있게 기록**하고,
사람이 필요해지면 **터미널 알림**을 보내는 Claude Code 플러그인. 마켓플레이스 `justwonder` 에 있다.

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
| `running` | 작업 중 | `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `PostToolUseFailure` |
| `waiting` | 사람을 기다림 (`reason`: permission / question / plan / input) | `PermissionRequest`, `Notification` |
| `done` | 응답을 끝냄 | `Stop` |
| `error` | API 오류로 멈춤 (`reason`: 오류 종류) | `StopFailure` |
| (없음) | 세션이 끝남 | `SessionEnd` |

상태가 바뀔 때마다 두 곳에 쓴다.

- **레코드 파일** `$(agent-state dir)/claude-<session>.json` — 아무 도구나 읽는 원본. macOS 는 사용자 임시 디렉터리, Linux 는 `$XDG_RUNTIME_DIR`.
- **tmux 패널 옵션** `@agent_state` `@agent_reason` `@agent_name` `@agent_pid` `@agent_since` — tmux 안일 때만. tmux 포맷이 바로 읽는다.

`waiting`·`done`·`error` 로 바뀌면 알림을 보낸다(아래 옵션).

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

## 한계

- **Esc 로 허락을 거절하거나 작업 도중 중단하면 Claude Code 가 아무 훅도 부르지 않는다** (2.1.327 실측). 표시는 `waiting`/`running` 으로
  남았다가 다음 프롬프트에서 바로잡힌다. tmux 쪽에는 지금 패널의 표시를 지우는 키가 있다.
- 패널 안 Claude 가 띄운 `claude -p` 같은 중첩 세션은 같은 tmux 패널을 물려받지만, 패널의 주인(`@agent_pid`)이 살아 있으면 패널 표시와
  알림은 건드리지 않는다(레코드 파일은 따로 남는다).
