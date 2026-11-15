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

## Linux: 도구는 사용자 영역에 받는다

Linux 는 dev container 나 서버라서 배포판과 권한을 고를 수 없을 때가 많다. 그래서 필수 도구를 배포판 패키지가 아니라
미리 빌드된 바이너리로 받는다. 목록은 `packages.yaml` 의 `packages.linux` 와 기능의 `linux:` 묶음이다.

| 종류 | 무엇 | 어떻게 |
|---|---|---|
| `tools` | tmux, fzf, rg, fd, jq, nvim (기능: gh, tree-sitter) | mise 가 `~/.local/opt/<이름>` 에 받고 `~/.local/bin/<이름>` 으로 링크한다. sudo 가 필요 없다 |
| `pkgs` | bash, bash-completion, gettext (기능 `ide`: gcc, libc6-dev) | 패키지 매니저(apt, apk, dnf, pacman). root 이거나 sudo 를 쓸 수 있을 때만 |
| fasd | 셸 스크립트 파일 하나 | `home/.chezmoiexternal.toml` 이 받아 `~/.jongwan/bin/fasd` 에 둔다 (macOS 도 같다) |

- **배포판과 상관없이 같은 최신 버전**이 깔린다. 시스템에 같은 도구가 있어도 받고, `~/.local/bin` 이 PATH 앞이라 받은 것이 쓰인다.
- **받은 바이너리가 실행되지 않는 시스템**(Alpine 의 musl, 오래된 glibc)에서는 그 도구만 `pkg` 이름으로 패키지 매니저에 넘긴다.
  Alpine arm64 에서는 rg 와 nvim 이 이렇게 apk 로 깔린다. 이때는 배포판의 버전이 깔리므로 오래된 것일 수 있다.
- **sudo 를 쓸 수 없으면** `pkgs` 와 위 대체 설치만 빠진다. 무엇이 빠졌는지 알리고 apply 는 끝까지 간다.
- **mise 로 받기에 실패하면**(네트워크 등) 설치 스크립트가 실패로 끝난다. 설정 파일은 그 전에 이미 깔려 있다 (Linux 의 설치
  스크립트는 파일 적용 뒤에 돈다). `chezmoi apply` 를 다시 실행하면 그 스크립트가 다시 돌고, 이미 받은 도구는 건너뛴다.
- `pkgs` 의 이름은 apt 기준이다. 다른 배포판에서 이름이 다른 패키지(`libc6-dev`)는 건너뛴다.
- 받아 둔 도구를 새 버전으로 바꾸려면 `~/.local/bin/<이름>` 을 지우고 설치 스크립트를 다시 돌린다:
  `chezmoi state delete-bucket --bucket=entryState && chezmoi apply`. `~/.local/bin` 에 없는 도구만 다시 받는다.
- 서버용 `jw-ephemeral` 도 같은 `tools` 목록을 읽어 자기 디렉터리 안에 받는다 (아래 "임시 머신").

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

minimal 이면 필수 도구만 깔리고(위 "Linux: 도구는 사용자 영역에 받는다"), LazyVim·언어 런타임·gh 는 빠진다. 기능 하나만 더하려면
init 뒤에 `chezmoi edit-config` 로 `[data.features]` 에 `ide = true` 처럼 적고 `chezmoi apply`.

**컨테이너에서 확인한 것** (2026-11-15, Docker. 저장소를 `--source` 로 준 것만 다르고 나머지는 위 명령과 같다)

| 환경 | 결과 |
|---|---|
| Debian 13, Ubuntu 24.04, Fedora (minimal) | 필수 도구 전부 `~/.local` 에. 로그인 셸에서 찾히고, tmux 가 이 저장소의 `tmux.conf` 로 붙고, nvim-lite 가 오류 없이 뜬다 |
| Alpine 3.22 (minimal, root) | nvim 은 apk 로 (arm64 는 rg 도). bash 가 없는 이미지라 apk 로 깐다 |
| sudo 없는 사용자 (Debian 12, minimal) | 도구는 전부 깔리고 `pkgs`(bash-completion, gettext)만 빠진다 |
| Debian 13 (full 에서 `dev` 만 끈 것) | gh·tree-sitter 는 `~/.local` 에, gcc·libc6-dev 는 apt. LazyVim 이 플러그인을 받고 nvim-treesitter 가 파서를 빌드한다 |

`dev`(언어 런타임)는 Debian 13 에서 go·node·python·ruby 가 깔리는 것까지 보았다. deno 는 내려받기가 느려 끝까지 기다리지 않았다.
Mason 이 까는 LSP 서버, pacman(Arch)은 돌려 보지 못했다.

**알려진 한계**

- tree-sitter 바이너리는 glibc 2.39 이상이 필요하다. Debian 12(glibc 2.36)에서는 실행되지 않고 배포판 패키지도 없어서,
  `ide` 를 켜도 nvim-treesitter 가 파서를 빌드하지 못한다. 다른 도구는 Debian 12 에서도 된다.
- Alpine 에서 sudo 도 root 도 없으면 nvim 과 bash 를 깔 수 없다. bash 가 없으면 이 저장소의 bash 스크립트
  (`40-reload-tmux` 등)가 실패해서 `chezmoi apply` 가 실패로 끝난다 (설정 파일은 깔린 뒤다).
- 패키지 매니저로 대신 깐 도구는 배포판의 버전이라 오래됐을 수 있다 (nvim-lite 는 nvim 0.10 이상이 필요하다).

### 내 계정으로 접속하는 서버 — 되돌려야 하는 환경

chezmoi 에는 깔기 전으로 되돌리는 기능이 없다 (`chezmoi purge` 는 chezmoi 자신만 지우고 깐 파일은 남긴다). 그래서 저장소
루트의 `jw-ephemeral` 이 앞뒤를 맡는다. 항상 minimal 이다.

```sh
curl -fsSL https://raw.githubusercontent.com/jjmean2/dotfiles/main/jw-ephemeral | bash -s install
exec $SHELL -l                                        # 적용
~/.local/state/jw-ephemeral/jw-ephemeral status       # 상태
~/.local/state/jw-ephemeral/jw-ephemeral uninstall    # 되돌리기
```

- **sudo 를 쓰지 않는다.** 자기 파일(chezmoi 바이너리, 저장소 사본, chezmoi 설정·상태·캐시, 백업, 도구)은 모두 `~/.local/state/jw-ephemeral` 한곳에 둔다. `~/.config/chezmoi`, `~/.local/share/chezmoi`, `~/.cache/chezmoi` 를 쓰지 않는다.
- 설정은 `chezmoi apply --exclude=scripts,remove` 로 깐다. 설치 스크립트는 `~/.local` 에 도구를 깔고 시스템 패키지를 건드리므로 돌리지 않고,
  `.chezmoiremove` 의 삭제(옛 이름 정리용)는 서버에 우연히 같은 경로가 있을 때 백업 없이 지우게 되므로 하지 않는다.
- 설치가 중간에 실패하면(네트워크 등) 그때까지 한 일을 자동으로 되돌린다.
- mise 는 실행하는 동안 `HOME` 까지 `~/.local/state/jw-ephemeral` 안으로 돌린다. 서명 검증 캐시처럼 `MISE_*` 설정을 따르지 않는 것이 있어서다.
- 필수 도구는 `mise install-into` 로 미리 빌드된 바이너리를 받는다. 목록은 일반 Linux 설치와 같은 `packages.yaml` 의 `packages.linux.tools`
  (tmux, fzf, rg, fd, jq, nvim)다. 서버에 이미 있으면(nvim 은 0.10 이상) 받지 않고 그것을 쓴다. 받은 것이 그 서버에서 실행되지
  않으면(musl 등) 그 도구 없이 쓴다. fasd 는 chezmoi 가 까는 파일이라 다른 설정 파일과 같이 깔리고 지워진다. git 은 서버에 있는 것을 쓴다.
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
- 실제 서버에서 `jw-ephemeral` 시험. 지금까지는 Docker 컨테이너(Debian 13, Alpine 3.22)의 sudo 없는 사용자로
  install → uninstall 을 돌려 깔기 전과 홈의 파일 내용·디렉터리 목록이 같은 것을 확인했다 (2026-11-15). 그 전에는 macOS 의
  가짜 HOME 에서 설치 중 실패 → 자동 되돌리기도 확인했다. 오래된 배포판의 서버, 서버에 있는 tmux 가 오래된 경우는 아직이다.
- 서버에서 nvim 의 `"+` 복사가 OSC 52 로 로컬 클립보드에 닿는지 확인.
