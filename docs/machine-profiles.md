# 머신 프로필: 어떤 머신에 무엇을 까나

개인 Mac, 회사 Mac, 그리고 잠깐 쓰는 서버·dev container 에서 같은 dotfiles 를 쓰되, 머신마다 **설치할 것**만 다르게
고르는 구조다. 원칙은 [tool-scope.md](tool-scope.md) 와 같다: 설정 파일은 모든 머신에 똑같이 깔고(도구가 없으면 그냥
쓰이지 않는다), 머신마다 갈리는 것은 "깔았을 때 무언가가 일어나는 것"(설치·인증·GUI 앱)뿐이다.

## 두 축: 층과 프로필

**층 — 무엇을 까나**

| 층 | 내용 | 어디에 |
|---|---|---|
| 필수 | 터미널 작업에 늘 쓰는 것. git, tmux, nvim, fzf, ripgrep, fd, jq, fasd 와 그 설정 | `packages.yaml` 의 `brews`/`tools`, 모든 설정 파일 |
| 선택 기능 | 머신에 따라 켜고 끄는 묶음 (아래 표) | `packages.yaml` 의 `features.<이름>`, `.chezmoiignore` |
| 머신 로컬 | 이 머신만의 덮어쓰기. dotfiles 가 관리하지 않는다 | mise `config.toml`, ghostty 테마, nvim `local-*.lua` 등 ([tool-scope.md](tool-scope.md)) |

**프로필 — 이 머신이 무엇인가**: `personal` / `work` / `ephemeral`. `chezmoi init` 때 한 번 묻고
(`~/.config/chezmoi/chezmoi.toml` 의 `data.profile`), **선택 기능 스위치의 처음 값을 정하는 데만** 쓴다.

## 선택 기능

| 스위치 | 내용 | personal | work | ephemeral |
|---|---|---|---|---|
| `karabiner` | Karabiner-Elements (macOS). init 때 묻는다 | 묻기 (기본 켬) | 묻기 (보안 SW 가 있으면 끔) | 끔 |
| `ide` | nvim IDE 모드: LazyVim 설정(`~/.config/nvim`)과 빌드 도구(tree-sitter-cli, cmake, imagemagick) | 켬 | 켬 | 끔 |
| `dev` | 언어 런타임: mise 로 `shared.toml` 의 node·python·go 등 설치 | 켬 | 켬 | 끔 |
| `credentials` | 로그인이 필요한 개인 도구 (gh) | 켬 | 끔 | 끔 |

- 처음 init 때 위 표대로 채워지고, 그 뒤로는 저장된 값을 그대로 쓴다. **프로필을 바꿔도 이미 저장된 스위치는 바뀌지 않는다.**
- 켜고 끄기: `chezmoi edit-config` 로 `[data.features]` 를 고치고 `chezmoi apply`.
- 꺼도 이미 설치된 것은 지우지 않는다 (관리만 멈춘다). 새 기능을 더할 때는 `packages.yaml` 에 묶음을, `.chezmoi.toml.tmpl` 에 기본값 한 줄을 넣는다.

## nvim 두 모드

| | 설정 위치 | 플러그인 | 언제 |
|---|---|---|---|
| nvim (IDE) | `~/.config/nvim` (LazyVim) | 첫 실행 때 네트워크로 받는다 | `features.ide` 가 켜진 머신 |
| nvim-lite | `~/.config/nvim-lite` | 없음 | 모든 머신에 깔린다. `ide` 를 끈 머신에서는 이것이 기본 nvim |

- nvim 의 `NVIM_APPNAME` 으로 고른다 (`:h NVIM_APPNAME`). 설정·데이터가 `~/.local/share/nvim-lite` 처럼 이름별로 따로 쌓인다.
- `~/.config/nvim/init.lua` 가 없고 nvim-lite 만 있으면 `shell/profile.sh` 가 `NVIM_APPNAME=nvim-lite` 를 export 한다. IDE 가 있는 머신에서도 `nvim-lite` alias 로 가볍게 열 수 있다.
- 플러그인에 기대지 않는 설정(한글 인코딩, 철자 검사, chezmoi 파일 형식, 셸 탭, `<leader>y` 경로 복사)은 `nvim-lite/lua/jw/` 에 한 벌만 두고, LazyVim 쪽 `lua/config/{options,keymaps}.lua` 가 `dofile` 로 읽는다.

## 임시 머신

두 종류의 요구가 반대라서 방법을 나눈다.

### dev container — 버리는 환경

sudo 를 써도 되고 되돌릴 필요가 없다. 평소처럼 init 하되 질문 없이 프로필을 준다.

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply --promptChoice profile=ephemeral --promptString "Email address=" jjmean2
```

필수 도구만 apt 등으로 설치되고, LazyVim·언어 런타임·gh 는 빠진다.

### 내 계정으로 접속하는 서버 — 되돌려야 하는 환경

chezmoi 에는 깔기 전으로 되돌리는 기능이 없다 (`chezmoi purge` 는 chezmoi 자신만 지우고 깐 파일은 남긴다). 그래서 저장소
루트의 `jw-ephemeral` 이 앞뒤를 맡는다.

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

## 기존 머신에 처음 적용할 때

`.chezmoi.toml.tmpl` 이 바뀌어서 apply 때마다 "config file template has changed" 경고가 난다. 머신마다 한 번:

```sh
chezmoi init     # profile 을 묻는다. 기존 karabiner 값은 그대로, 새 스위치는 프로필 기본값으로 채워진다
chezmoi apply
```

init 전에 apply 하면 새 스위치가 없어서 `ide`·`credentials` 묶음이 brew 목록에서 빠지고 `dev`(mise 런타임 설치)가
돌지 않는다. 이미 깔린 것은 지우지 않으므로 동작은 그대로이고, LazyVim 설정은 스위치가 없으면 계속 배포한다.

## 후속 후보

- tmux 상태바의 `gitmux` 를 설치 여부로 감싸기. 지금은 서버처럼 gitmux 가 없는 곳에서 git 표시가 비거나 오류가 난다.
- 셸이 만드는 상태 파일(`.zsh_history`, `.zcompdump`)을 `$XDG_STATE_HOME`·`$XDG_CACHE_HOME` 으로 옮기기.
- dev container 의 dotfiles 기능이 자동으로 부르는 `install.sh` 를 저장소 루트에 두기.
- Linux 실제 서버에서 `jw-ephemeral` 시험. 지금까지는 macOS 의 가짜 HOME 에서 install → uninstall(문서대로 stdin 실행),
  설치 중 실패 → 자동 되돌리기를 확인했고, 두 경우 모두 깔기 전과 파일 목록·내용이 같았다.
- 서버에서 nvim 의 `"+` 복사가 OSC 52 로 로컬 클립보드에 닿는지 확인.
