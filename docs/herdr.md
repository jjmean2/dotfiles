# Herdr: 코딩 에이전트용 멀티플렉서

[Herdr](https://herdr.dev) 는 여러 코딩 에이전트를 한 화면에서 돌리기 위한 터미널 멀티플렉서다. 패널 안의 에이전트를 알아보고
상태(blocked / working / done / idle)를 사이드바에 모아 보여 준다. 이 dotfiles 에서는 **tmux 와 별개로, 다른 터미널 탭에서
병렬로** 쓴다. 한쪽 안에 다른 쪽을 띄우는 중첩은 하지 않는다.

2026-11-27 에 정한 설계다. 근거는 Herdr 0.9.5 의 문서와 소스(`herdrdev/herdr`). 아직 써 보는 단계라 기능 스위치는 opt-in 이다.

## 방침

- **tmux 설정에 맞추지 않는다.** 키와 화면은 Herdr 의 방식을 따르고 기본값과 다르게 둘 것만 적는다.
  - 사이드바가 대시보드다. Agent 목록은 급한 순서(`agent_panel_sort = "priority"`), 상태는 모양으로도 구분(`symbols`).
  - 기본 키맵(prefix `ctrl+b`)은 그대로 두고, 자주 쓰는 것만 prefix 없는 `ctrl+alt` 조합을 덧붙인다.
  - 워크트리·이동 화면·세션 복원은 내장 기능을 쓴다. tmux-dev·agent-state 같은 것을 다시 만들지 않는다.
- **단위**: workspace = 저장소 (워크트리는 그 아래에 묶인다), tab = 작업 하나 (에이전트 + 그 작업의 셸), pane = 역할.
  이름 있는 세션(`herdr session attach <이름>`)은 정말 나눠야 하는 맥락에만.

| 하고 싶은 것 | 키 |
|---|---|
| 다음에 볼 에이전트로 | `ctrl+alt+o` (지금 알림의 패널), `ctrl+alt+n` / `ctrl+alt+p` (급한 순서로 다음·이전) |
| 에이전트·터미널 목록에서 고르기 | `ctrl+alt+g` (`prefix+g`). 안에서 `b`/`w`/`i`/`d` 로 상태별 거르기 |
| 패널 이동 / zoom | `ctrl+alt+h/j/k/l` / `ctrl+alt+z` |
| 탭 이동 | `ctrl+alt+[` / `ctrl+alt+]` |
| 워크트리 만들기 / 열기 | `prefix+shift+g` / `prefix+shift+o` (지우기는 사이드바 메뉴에서 확인을 거쳐) |
| lazygit / 임시 셸 / nvim | `prefix+alt+g` / `prefix+t` / `prefix+alt+e` |
| 스크롤백을 편집기로 | `prefix+e` (내장) |
| 전체 키 보기 | `prefix+?` |

## 파일

| 파일 | 내용 |
|---|---|
| `home/.chezmoitemplates/herdr/config.toml` | 관리 기본값. 모든 머신에 같다. 키마다 이유를 주석으로 적었다 |
| `home/dot_config/herdr/config.toml.tmpl` | 위 기본값과 머신 로컬 파일을 합쳐 `~/.config/herdr/config.toml` 을 만든다 |
| `~/.config/herdr/config.local.toml` | 머신 로컬. chezmoi 가 관리하지 않는다 (저장소 규칙의 `*.local`) |
| `home/.chezmoiscripts/run_onchange_after_41-reload-herdr.sh.tmpl` | 합친 결과가 바뀌면 `herdr server reload-config` |
| `home/dot_config/shell/rc.d/herdr.sh` | Herdr 패널 안에서 agent-state 알림을 끈다 (아래 "agent-state 와의 관계") |
| `home/.chezmoidata/packages.yaml` 의 `features.herdr` | 설치(brew / mise)와 설정 배포. opt-in |

켜기: `chezmoi edit-config` 로 `[data.features]` 에 `herdr = true` 를 적고 `chezmoi apply` ([machines.md](machines.md)).

## 관리 설정과 로컬 설정

Herdr 는 설정 파일 하나(`~/.config/herdr/config.toml`, 또는 `HERDR_CONFIG_PATH`)만 읽고 include 가 없다
(소스 `src/config/io.rs`). 그래서 chezmoi 가 apply 때 둘을 **TOML 값으로 읽어 합친다**.

- 같은 키는 로컬이 이긴다. 표는 키 단위로 깊이 합쳐지고, 배열(`ui.sidebar.agents.rows` 등)은 통째로 바뀐다.
- `[[keys.command]]` 만 예외로 이어 붙인다 (기본값의 명령 + 로컬의 명령). 로컬에 명령 하나를 더하려고 기본값의 명령을
  다 옮겨 적지 않아도 되게.
- 값으로 읽었다 다시 쓰므로 배포된 파일에는 주석이 없고 키가 이름순이다. 설명은 소스 파일에서 본다.
- 로컬 파일을 고친 뒤에는 `chezmoi apply`. 해시가 합친 결과에 걸려 있어 서버에도 다시 읽힌다.
- 로컬 파일이 TOML 로 깨져 있으면 apply 가 그 자리에서 오류를 내고 멈춘다 (`fromToml` 오류).

로컬에 둘 만한 것: 이 머신의 테마나 알림 방식(`[ui.toast] delivery = "system"`), 사이드바 폭, 이 머신에서만 쓰는 명령.

```toml
# ~/.config/herdr/config.local.toml 예
[ui.toast]
delivery = "system"

[[keys.command]]
key = "prefix+alt+d"
type = "popup"
command = "lazydocker"
```

**Herdr 가 스스로 쓰는 경우.** Settings 화면에서 테마·상태 표시·소리·알림 방식을 고르면 Herdr 가 배포된 파일의 그 키를 직접 고친다
(`src/config/write.rs`). 첫 실행 안내를 끝낼 때(`onboarding`)와 `herdr config reset-keys` 도 그렇다. 이런 변경은 다음
`chezmoi apply` 가 덮어쓰려 한다(chezmoi 가 바뀐 것을 알리고 묻는다). Settings 는 시험용으로 쓰고, 남길 값은 기본값 파일이나
로컬 파일로 옮긴다. `onboarding = false` 는 처음부터 기본값에 적어 두었다.

## 알림과 agent-state 와의 관계

Herdr 패널 안에는 `TMUX` 가 없으므로 agent-state 훅은 tmux 패널 옵션을 쓰지 않고 레코드 파일과 알림만 낸다
([agent-state.md](agent-state.md)). Herdr 는 상태를 화면으로 스스로 감지해 알림(`ui.toast`)을 보내므로, 둘 다 켜 두면 같은 일로
두 번 온다. 그래서 `rc.d/herdr.sh` 가 Herdr 패널(`HERDR_ENV=1`)에서 `AGENT_STATE_NOTIFY_ON=off` 를 내보낸다. 상태 기록은 그대로다.

- 알림은 `delivery = "terminal"`: 바깥 Ghostty 의 데스크톱 알림이고 `herdr --remote` 에서도 동작한다.
- 확인할 것: Claude Code 가 플러그인 옵션의 **기본값**도 `CLAUDE_PLUGIN_OPTION_NOTIFY_ON` 으로 넘긴다면, 그 값이 환경 변수보다
  우선해서(`bin/agent-state` 의 `notify`) 이 끄기가 듣지 않는다. 그때는 이 방식 대신 다른 길을 찾는다.

**agent-state 연결 (후속).** 화면 감지는 상태만 알고 **왜** 막혔는지(permission / question / plan)는 모른다. agent-state 훅이
`HERDR_ENV=1` 일 때 `herdr pane report-metadata "$HERDR_PANE_ID" --source agent-state --token reason=<이유>` 를 부르면
사이드바의 `$reason` 칸에 이유가 나온다. 상태 자체는 Herdr 감지에 맡긴다(승인·거절 직후처럼 훅이 오지 않는 공백을 화면 감지가
메운다). 아직 만들지 않았고, 그전까지 `$reason` 칸은 값이 없어 저절로 사라진다.

## 한글 입력 (macOS)

- prefix: Karabiner 규칙([karabiner.md](karabiner.md))이 Ghostty 에서 `ctrl+b` 를 "영문 전환 + ctrl+b" 로 바꾸므로 tmux 와 같이
  prefix 뒤의 글자 키가 듣는다.
- Herdr 자체 기능 `switch_ascii_input_source_in_prefix` 는 켜지 않는다. Herdr 는 prefix 모드에 들어갈 때 Carbon TIS 로
  지금 입력기를 기억하고 영문으로 바꾼 뒤, 모드가 끝나면 기억한 입력기로 되돌린다(`src/platform/macos.rs`). 그런데 Karabiner 가
  먼저 영문으로 바꿔 두므로 Herdr 는 "이미 영문" 으로 보고 아무것도 기억하지 않는다. 둘을 같이 켜도 효과가 없다.
  이 기능을 쓰려면 Herdr prefix 를 Karabiner 규칙에 없는 키로 바꾸면 된다.
- `reveal_hidden_cursor_for_cjk_ime`: Claude Code 처럼 커서를 숨기는 TUI 에서 한글 후보 창이 커서를 따라오게 한다.
  에이전트 패널(`cjk_ime_agents`)에서만.

## 처음 한 번

```sh
herdr integration install claude   # 서버를 다시 띄웠을 때 Claude 대화를 이어 붙이기 위한 세션 보고 훅
herdr                              # 시작 경고(잘못된 키)가 없는지 본다. prefix+? 로 키 확인
```

`integration install claude` 는 `~/.claude/settings.json` 에 훅을 더한다 (chezmoi 가 관리하지 않는 파일이라 충돌하지 않는다).
상태 감지는 통합 없이도 된다.

## 하지 않은 것

- 플러그인: 아직 없다. 마켓플레이스는 검수가 없고 플러그인은 내 권한으로 돈다. 쓰게 되면 `herdr plugin install <repo> --ref <태그>`
  로 고정하고 여기에 적는다.
- 워크트리 위치: 기본값 `~/.herdr/worktrees` 그대로. tmux-dev(`~/.local/share/tmux-dev/worktrees`)와 나눠 두어 어느 도구가
  만든 것인지 구분한다. 같은 저장소의 워크트리는 양쪽 피커에 다 보이므로, 한쪽에서 정리할 때 다른 쪽에서 쓰던 것이 아닌지 본다.
- 검증: 이 설정은 chezmoi 렌더링(로컬 파일 유무, 덮어쓰기, 명령 이어 붙이기, 깨진 로컬 파일)과 TOML 문법까지만 확인했다.
  Herdr 에 실제로 읽힌 적은 아직 없다.
