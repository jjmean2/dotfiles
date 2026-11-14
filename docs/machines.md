# 머신마다 무엇을 까나: 등급과 기능

개인 Mac, 회사 Mac, 그리고 잠깐 쓰는 서버·dev container 에서 같은 dotfiles 를 쓰되, 머신마다 **설치할 것**만 다르게
고르는 구조다. 원칙은 [tool-scope.md](tool-scope.md) 와 같다: 설정 파일은 모든 머신에 똑같이 깔고(도구가 없으면 그냥
쓰이지 않는다), 머신마다 갈리는 것은 "깔았을 때 무언가가 일어나는 것"(설치·인증·GUI 앱)뿐이다.

## 세 층

| 층 | 내용 | 어디에 |
|---|---|---|
| 필수 | 터미널 작업에 늘 쓰는 것. git, tmux, nvim, fzf, ripgrep, fd, jq, fasd 와 그 설정 | `packages.yaml` 의 `packages.<os>`, 모든 설정 파일 |
| 기능 | 머신에 따라 켜고 끄는 묶음 (아래 표). 기능 하나 = 패키지 + 전용 설정 파일 + 후처리 | `packages.yaml` 의 `packages.features.<이름>` |
| 머신 로컬 | 이 머신만의 덮어쓰기. dotfiles 가 관리하지 않는다 | mise `config.toml`, ghostty 테마, nvim `local-*.lua` 등 ([tool-scope.md](tool-scope.md)) |

## 기능이 켜지는 규칙

기능의 목록과 기본값은 저장소(`home/.chezmoidata/packages.yaml`)에 있고, 머신(`~/.config/chezmoi/chezmoi.toml`)에는
그 머신에 대한 답만 있다.

```toml
[data]
  minimal = false        # 등급. true 면 필수 도구와 설정만
[data.features]
  karabiner = true       # 기본값과 다르게 둘 것, 그리고 init 때 물은 것만 적는다
```

1. `[data.features]` 에 `<이름> = true / false` 가 있으면 그 값이다.
2. 없으면 기능의 `tier` 가 정한다. `full` 은 minimal 이 아닌 머신에서 켜고, `opt-in` 은 끈다.

| 기능 | tier | 내용 | full 머신 | minimal 머신 |
|---|---|---|---|---|
| `ide` | full | nvim IDE 모드: LazyVim 설정(`~/.config/nvim`)과 빌드 도구(tree-sitter-cli, cmake, imagemagick) | 켬 | 끔 |
| `dev` | full | 언어 런타임: mise 로 `shared.toml` 의 node·python·go 등 설치 | 켬 | 끔 |
| `credentials` | full | 로그인이 필요한 도구 (gh). 회사 머신에서도 회사 계정으로 쓴다 | 켬 | 끔 |
| `karabiner` | opt-in | Karabiner-Elements (macOS). 보안 소프트웨어가 관리하는 머신에서는 깔면 안 되므로 init 때 묻는다 | 물은 답 | 끔 (묻지 않음) |

- **지금 켜진 것 확인**: `chezmoi execute-template '{{ includeTemplate "enabled-features" . }}'`
- **켜고 끄기**: `chezmoi edit-config` 로 `[data.features]` 에 한 줄을 적고 `chezmoi apply`. minimal 머신에서 `ide` 만 켜려면
  `ide = true`, full 머신에서 `dev` 만 끄려면 `dev = false`.
- **꺼도 이미 설치된 것은 지우지 않는다** (관리만 멈춘다). `false` 는 "이 머신에서 안 쓴다" 가 아니라 "dotfiles 가 관리하지
  않는다" 이다. 손으로 깔아 써도 된다.
- **적지 않은 기능은 저장소의 선언을 따른다.** 저장소에 새 기능을 `tier: full` 로 더하면 다음 `chezmoi apply` 때 full 머신
  전부에 깔린다 (머신마다 `chezmoi init` 을 다시 할 필요가 없다). 어떤 머신에서 원하지 않으면 그 머신에 `false` 한 줄을 적는다.
- **새 기능 더하기**: `packages.yaml` 의 `packages.features` 에 블록 하나. 설치 스크립트와 `.chezmoiignore` 는 그 목록을 돈다.
  ```yaml
  myapp:
    tier: opt-in               # 켠다고 적은 머신에서만. 모든 full 머신이면 full
    ignore: [.config/myapp]    # 꺼진 머신에는 배포하지 않을 전용 설정 (없으면 생략)
    darwin: { casks: [myapp] }
  ```
  깔면 안 되는 머신이 있어서 사람이 정해야 하는 기능만 `opt-in` 으로 두고 `.chezmoi.toml.tmpl` 에 질문 한 줄을 더한다
  (`karabiner` 를 본뜬다). 그 템플릿에서는 `packages.yaml` 을 읽을 수 없어서 질문은 거기에 직접 적는다.

### 머신마다 다른 것은 세 종류다

| 무엇이 다른가 | 어디에 두나 |
|---|---|
| 값 (git 이메일·이름) | `chezmoi init` 이 묻고 머신의 `chezmoi.toml` 에 적는다. 다시 답하려면 `chezmoi init --prompt` |
| 묶음 (회사 머신에만 까는 도구 등) | `tier: opt-in` 기능. 그 머신의 `[data.features]` 에 `true` |
| 한 머신 안에서 저장소마다 다른 git 신원 | 관리 밖 `~/.config/git/config` 에 `includeIf "gitdir:~/work/"` 로 머신 전용 파일을 include |

## nvim 두 모드

| | 설정 위치 | 플러그인 | 언제 |
|---|---|---|---|
| nvim (IDE) | `~/.config/nvim` (LazyVim) | 첫 실행 때 네트워크로 받는다 | `ide` 가 켜진 머신 |
| nvim-lite | `~/.config/nvim-lite` | 없음 | 모든 머신에 깔린다. `ide` 가 꺼진 머신에서는 이것이 기본 nvim |

- nvim 의 `NVIM_APPNAME` 으로 고른다 (`:h NVIM_APPNAME`). 설정·데이터가 `~/.local/share/nvim-lite` 처럼 이름별로 따로 쌓인다.
- `~/.config/nvim/init.lua` 가 없고 nvim-lite 만 있으면 `shell/profile.sh` 가 `NVIM_APPNAME=nvim-lite` 를 export 한다. IDE 가 있는 머신에서도 `nvim-lite` alias 로 가볍게 열 수 있다.
- 플러그인에 기대지 않는 설정(한글 인코딩, 철자 검사, chezmoi 파일 형식, 셸 탭, `<leader>y` 경로 복사)은 `nvim-lite/lua/jw/` 에 한 벌만 두고, LazyVim 쪽 `lua/config/{options,keymaps}.lua` 가 `dofile` 로 읽는다.

## 임시 머신

두 종류의 요구가 반대라서 방법을 나눈다.

### dev container — 버리는 환경

sudo 를 써도 되고 되돌릴 필요가 없다. 평소처럼 init 하되 질문 없이 답을 준다.

```sh
# 필수 도구와 설정만
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply --promptBool minimal=true --promptString "Email address=" --promptString "Full name (git user.name)=" jjmean2
# nvim IDE·언어 런타임·gh 까지 (Mac 의 full 머신과 같은 기능)
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply --promptBool minimal=false --promptString "Email address=" --promptString "Full name (git user.name)=" jjmean2
```

minimal 이면 필수 도구만 apt 등으로 설치되고, LazyVim·언어 런타임·gh 는 빠진다. 기능 하나만 더하려면 init 뒤에
`chezmoi edit-config` 로 `[data.features]` 에 `ide = true` 처럼 적고 `chezmoi apply`.

### 내 계정으로 접속하는 서버 — 되돌려야 하는 환경

chezmoi 에는 깔기 전으로 되돌리는 기능이 없다 (`chezmoi purge` 는 chezmoi 자신만 지우고 깐 파일은 남긴다). 그래서 저장소
루트의 `jw-ephemeral` 이 앞뒤를 맡는다. 항상 minimal 이다.

```sh
curl -fsSL https://raw.githubusercontent.com/jjmean2/dotfiles/main/jw-ephemeral | bash -s install
exec $SHELL -l                                        # 적용
~/.local/state/jw-ephemeral/jw-ephemeral status       # 상태
~/.local/state/jw-ephemeral/jw-ephemeral uninstall    # 되돌리기
```

- **sudo 를 쓰지 않는다.** 자기 파일(chezmoi 바이너리, 저장소 사본, chezmoi 설정·상태, 백업, 도구)은 모두 `~/.local/state/jw-ephemeral` 한곳에 둔다. `~/.config/chezmoi`, `~/.local/share/chezmoi` 를 쓰지 않는다.
- 설정은 `chezmoi apply --exclude=scripts,remove` 로 깐다. 설치 스크립트는 sudo·시스템 패키지를 쓰므로 돌리지 않고,
  `.chezmoiremove` 의 삭제(옛 이름 정리용)는 서버에 우연히 같은 경로가 있을 때 백업 없이 지우게 되므로 하지 않는다.
- 설치가 중간에 실패하면(네트워크 등) 그때까지 한 일을 자동으로 되돌린다.
- mise 는 실행하는 동안 `HOME` 까지 `~/.local/state/jw-ephemeral` 안으로 돌린다. 서명 검증 캐시처럼 `MISE_*` 설정을 따르지 않는 것이 있어서다.
- 필수 도구는 `mise install-into` 로 미리 빌드된 바이너리를 받는다 (fzf, rg, fd, jq, nvim). 서버에 이미 있으면(nvim 은 0.10 이상) 그것을 쓴다. fasd 는 스크립트 하나를 받는다. git·tmux 는 서버에 있는 것을 쓴다 (tmux 는 sudo 없이 받을 바이너리가 없다).
- 도구 디렉터리는 `shell/profile.sh`·`rc.sh` 가 있을 때만 PATH 맨 앞에 넣는다.

**되돌리기의 범위**

| 무엇 | 어떻게 |
|---|---|
| chezmoi 가 깐 파일 | 깔기 전에 있던 것은 백업(tar)에서 복원, 없던 것은 삭제 (`chezmoi managed` 목록 기준) |
| 런타임 상태 | `jw-ephemeral` 의 `RUNTIME_PATHS` 중 깔기 전에 없던 것만 삭제 (nvim-lite 데이터, fasd 캐시, zsh 히스토리 등) |
| 디렉터리 | 깔면서 새로 생긴 디렉터리를 깊은 것부터, 비어 있을 때만 삭제 |
| 그 밖에 쓰는 동안 만든 파일 | 건드리지 않는다 |

다른 사람과 같이 쓰는 계정이면 rc 파일을 덮어쓰는 것 자체가 문제라 이 방식을 쓰지 않는다.

## 이전 구조(프로필)로 init 한 머신

2026-11-14 까지는 `profile = personal | work | ephemeral` 이 `ide`·`dev`·`credentials` 의 처음 값을 정해 머신에 적어 두었다.
그 머신은 init 을 다시 하지 않아도 그대로 동작한다 (적혀 있는 값이 그대로 쓰인다). 다만 `.chezmoi.toml.tmpl` 이 바뀌어서
apply 때마다 "config file template has changed" 경고가 나오므로 머신마다 한 번:

```sh
chezmoi init     # 묻지 않는다. profile 을 minimal 로 옮기고, 기본값 그대로 적혀 있던 스위치를 지운다
chezmoi apply
```

`ephemeral` 은 `minimal = true` 로, 나머지는 `false` 로 옮겨진다. `ide`·`dev`·`credentials` 는 프로필 기본값과 같으면 지워져서
앞으로 저장소의 선언을 따르고, 다르면(손으로 바꾼 값) 남는다. `karabiner` 는 물었던 답 그대로 남는다.

## 후속 후보

- tmux 상태바의 `gitmux` 를 설치 여부로 감싸기. 지금은 서버처럼 gitmux 가 없는 곳에서 git 표시가 비거나 오류가 난다.
- 셸이 만드는 상태 파일(`.zsh_history`, `.zcompdump`)을 `$XDG_STATE_HOME`·`$XDG_CACHE_HOME` 으로 옮기기.
- dev container 의 dotfiles 기능이 자동으로 부르는 `install.sh` 를 저장소 루트에 두기.
- Linux 실제 서버에서 `jw-ephemeral` 시험. 지금까지는 macOS 의 가짜 HOME 에서 install → uninstall(문서대로 stdin 실행),
  설치 중 실패 → 자동 되돌리기를 확인했고, 두 경우 모두 깔기 전과 파일 목록·내용이 같았다.
- 서버에서 nvim 의 `"+` 복사가 OSC 52 로 로컬 클립보드에 닿는지 확인.
