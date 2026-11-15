# dotfiles

[chezmoi](https://www.chezmoi.io/) 로 관리하는 개인 개발 환경 설정 저장소.

## 디렉토리 구조

| 경로 | 내용 |
|---|---|
| `home/` | chezmoi 소스 상태 (`.chezmoiroot` 로 지정). 홈 디렉토리에 배포된다 |
| `home/.chezmoidata/packages.yaml` | 설치 패키지 목록 (필수 / OS 별 / 머신별 기능) |
| `home/.chezmoiscripts/` | 패키지/도구 설치 스크립트. `run_onchange_` 라서 내용이 바뀔 때만 다시 실행된다 |
| `docos/<project>/docker-compose.yml` | 로컬에서 띄우는 docker compose 서비스. `doco <project> up` 으로 실행 |
| `snippets/` | 기억해 두고 싶은 코드 스니펫 |
| `claude-plugins/` | 개인 Claude Code 플러그인. 루트의 `.claude-plugin/marketplace.json` 이 이 저장소를 마켓플레이스로 만든다 (`claude plugin marketplace add jjmean2/dotfiles`, 마켓플레이스 이름 `justwonder`). 지금은 작업 스킬 모음 `jw` 하나 |
| `docs/` | 설계·운영 문서. [`docs/tool-scope.md`](docs/tool-scope.md): 개발 도구를 모든 머신 / 일부 머신 / 이 머신 / 이 프로젝트 중 어디에 둘지. [`docs/machines.md`](docs/machines.md): 머신마다 무엇을 까나 (등급 minimal / full 과 기능), 임시 서버 설치·되돌리기 |
| `install.sh` | dev container 에 묻지 않고 까는 진입점. VS Code 의 dotfiles 기능이 실행한다 ([`docs/machines.md`](docs/machines.md)) |
| `jw-ephemeral` | 내 계정으로 접속한 서버에 sudo 없이 깔았다가 되돌리는 래퍼 ([`docs/machines.md`](docs/machines.md)) |

`home/` 밖의 파일은 chezmoi 가 배포하지 않는다.

## 설치

환경에 따라 처음 실행하는 것이 다르다. 설명은 아래 각 경우에 있다.

| 환경 | 처음 실행하는 것 | 깔리는 것 |
|---|---|---|
| 새 Mac | `sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin init --apply jjmean2` (경우 1) | 이메일·이름·등급·Karabiner 를 묻고 깐다. 등급의 기본은 full |
| Mac, 저장소를 원하는 위치에 | `chezmoi init --source <저장소 경로> --apply` (경우 2·3) | 위와 같다 |
| dev container, VS Code 가 자동으로 | VS Code 사용자 설정에 `"dotfiles.repository": "jjmean2/dotfiles"` (경우 4) | 필수 도구와 설정 + nvim IDE. 묻지 않는다 |
| dev container, 손으로 | `git clone https://github.com/jjmean2/dotfiles.git ~/dotfiles && ~/dotfiles/install.sh` (경우 4) | 위와 같다. `install.sh minimal` 은 필수만, `install.sh full` 은 Mac 과 같은 기능 |
| 내 계정으로 접속한 서버 | `curl -fsSL https://raw.githubusercontent.com/jjmean2/dotfiles/main/jw-ephemeral \| bash -s install` (경우 5) | 필수 도구와 설정만. sudo 를 쓰지 않고, `uninstall` 로 되돌린다 |

### 사전 준비

- macOS: `xcode-select --install` (git). Homebrew 는 설치 스크립트가 없으면 깔아 준다.
- Linux: `curl`, `git`. sudo 는 있으면 쓴다 (없으면 패키지 매니저로 까는 몇 가지만 빠진다. [`docs/machines.md`](docs/machines.md) 의 "Linux").
- 저장소는 공개라 읽기에는 인증이 필요 없다. 나중에 push 하려면 SSH 키를 등록하고 원격을
  `git@github.com:jjmean2/dotfiles.git` 으로 바꾼다 (`git remote set-url origin ...`).

### 경우 1. 새 머신, 저장소는 기본 위치

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin init --apply jjmean2
```

- `get.chezmoi.io` 가 chezmoi 바이너리를 `-b` 디렉토리에 받고(기본은 현재 디렉토리의 `./bin`),
  `jjmean2` 를 `https://github.com/jjmean2/dotfiles.git` 로 풀어 `~/.local/share/chezmoi` 에 클론한 뒤
  `init --apply` 를 실행한다. SSH 키가 이미 있으면 `--ssh` 를 붙여 SSH 로 클론할 수 있다.
- macOS 는 설치 스크립트가 brew 로 chezmoi 를 다시 설치하므로 `~/.local/bin/chezmoi` 는 지워도 된다.
  Linux 는 그대로 쓴다 (`~/.local/bin` 은 PATH 에 있다).
- chezmoi 를 이미 `brew install chezmoi` 로 받아 두었다면 설치 스크립트 없이 `chezmoi init --apply jjmean2` 만
  실행한다. `get.chezmoi.io` 는 바이너리를 받은 뒤 `--` 뒤의 인자를 chezmoi 에 그대로 넘기는 래퍼다.

### 경우 2. 이미 클론해 둔 저장소를 소스로 쓰기

```sh
brew install chezmoi            # 또는 sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
chezmoi init --source ~/dev/jwlee/dotfiles --apply
```

클론하지 않고 그 디렉토리를 소스로 등록한다. `home/.chezmoi.toml.tmpl` 이 `sourceDir` 에
그 경로(`.chezmoi.workingTree`)를 써 두므로, 이후 `chezmoi apply` 등은 옵션 없이 그 위치를 쓴다.
이 Mac 이 이 방식이다 (`~/.config/chezmoi/chezmoi.toml` 참고).

### 경우 3. 새 머신, 저장소를 원하는 위치에

```sh
git clone git@github.com:jjmean2/dotfiles.git ~/dev/jwlee/dotfiles   # 또는 https://github.com/jjmean2/dotfiles.git
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin init --source ~/dev/jwlee/dotfiles --apply
```

경우 1 과 2 를 합친 것이다. chezmoi 가 이미 있으면 둘째 줄 대신 `chezmoi init --source ~/dev/jwlee/dotfiles --apply`.
다른 브랜치로 시작하려면 클론할 때 `-b <브랜치>` 를 준다.

### 경우 4. dev container

저장소 루트의 `install.sh` 가 묻지 않고 깐다. 기본으로 깔리는 것은 필수 도구와 설정에 nvim IDE(LazyVim)를 더한 것이다
(등급 `minimal` 에 기능 `ide` 만 켠다). 자세한 내용과 확인한 범위는 [`docs/machines.md`](docs/machines.md).

**VS Code 가 자동으로.** VS Code 사용자 설정(`settings.json`)에 한 줄을 넣어 둔다. dev container 를 만들 때 VS Code 가 이 저장소를
컨테이너 안에 clone 하고 루트의 `install.sh` 를 실행한다.

```json
"dotfiles.repository": "jjmean2/dotfiles"
```

**손으로.** 컨테이너 안에서 clone 한 뒤 실행한다. 인자로 무엇을 깔지 고른다.

```sh
git clone https://github.com/jjmean2/dotfiles.git ~/dotfiles
~/dotfiles/install.sh            # 필수 도구와 설정 + nvim IDE (인자 없이 실행한 것과 같다. VS Code 가 실행하는 꼴)
~/dotfiles/install.sh minimal    # 필수 도구와 설정만. nvim 은 플러그인 없는 nvim-lite
~/dotfiles/install.sh full       # Mac 의 full 머신과 같은 기능 (ide, dev, credentials). 언어 런타임을 받느라 몇 분 걸린다
```

- 처음 한 번만 쓴다. 이미 chezmoi 로 init 한 곳에서는 아무것도 하지 않는다. 그 뒤로는 `chezmoi apply`, `chezmoi update` 를 쓴다.
- 이름과 이메일은 묻지 않는다. 컨테이너에 git 설정이 이미 있으면 그 값을 쓰고, 없으면 첫 커밋 때 git 이 정하라고 알려 준다
  (`git config --global user.name …`, `user.email …`).
- sudo 가 되면 패키지 매니저도 쓴다 (gcc 등). 안 되면 그 몇 가지만 빠진다.

### 경우 5. 내 계정으로 접속한 서버

sudo 를 쓰지 않고 필수 도구와 설정만 깔았다가, 끝나면 깔기 전으로 되돌린다. 자세한 내용은 [`docs/machines.md`](docs/machines.md).

```sh
curl -fsSL https://raw.githubusercontent.com/jjmean2/dotfiles/main/jw-ephemeral | bash -s install
exec $SHELL -l                                        # 적용
~/.local/state/jw-ephemeral/jw-ephemeral uninstall    # 되돌리기
```

### 이미 설정 파일이 있는 머신이라면

chezmoi 는 **자기가 관리하는 경로만** 건드리고, 그 경로에 이미 있던 파일은 첫 apply 때 **묻지 않고 덮어쓴다**
(아직 자기가 쓴 적이 없는 파일이라 "내가 쓴 뒤 바뀌었는지" 를 판단할 기록이 없기 때문이다). 격리 환경에서 확인한
동작은 다음과 같다.

| 기존 상태 | 첫 apply 결과 |
|---|---|
| 내용이 다른 일반 파일 (`~/.zshrc` 등) | 소스 내용으로 덮어씀. 프롬프트 없음 |
| Stow 등이 만든 심볼릭 링크 | 링크를 지우고 일반 파일로 교체. 링크가 가리키던 원본은 그대로 |
| `create_` 대상 (`~/.config/git/config` 등) | 있으면 그대로 둠 |
| chezmoi 가 관리하지 않는 파일 | 건드리지 않음 |
| chezmoi 가 한 번 쓴 뒤 손으로 고친 파일 | 다음 apply 때 "changed since chezmoi last wrote it" 프롬프트 (overwrite / diff / skip) |

그래서 기존 머신에서는 `--apply` 없이 init 한 뒤 차이를 보고 적용한다.

```sh
chezmoi init jjmean2              # 클론과 config 생성만
chezmoi managed                   # 건드릴 경로 목록
chezmoi diff                      # 기존 파일과의 차이 (심볼릭 링크 교체도 여기 보인다)
chezmoi apply --dry-run -v        # 실제로 할 일 미리보기
chezmoi apply -v
```

남기고 싶은 머신별 내용은 적용 전에 `*.local` 파일이나 `.chezmoiignore` 에 있는 머신 전용 파일로 옮긴다.
Stow 로 관리하던 머신은 `stow -D <패키지>` 로 링크를 먼저 걷어도 되고, 그냥 두어도 chezmoi 가 링크를 파일로 바꾼다.

### 첫 apply 에서 일어나는 일

1. `.chezmoi.toml.tmpl` 이 이메일, git 이름, 머신 등급(minimal 인지), macOS 면 Karabiner 를 쓸지 묻고
   `~/.config/chezmoi/chezmoi.toml` 을 만든다 (한 번만 묻는다). 나머지 기능은 등급에 따라 저장소의 선언대로 켜진다.
2. `run_onchange_before_*` (macOS): Homebrew 설치, `packages.yaml` 의 brew/cask 설치. 몇 분 걸린다.
3. `home/` 의 파일이 홈에 배포된다. fasd 스크립트도 이때 받는다 (`home/.chezmoiexternal.toml`).
4. `run_onchange_after_*`: (Linux) mise 로 필수 도구를 `~/.local` 에 받고 나머지는 배포판 패키지로 설치, `mise install` 로 `conf.d/shared.toml` 의 런타임 설치, (macOS) tmux/ghostty terminfo.
5. 이후 `chezmoi apply` 는 바뀐 파일만 다시 쓰고, 스크립트는 내용이 바뀐 것만 다시 돈다.

### 설치 후 확인

```sh
chezmoi doctor        # source-dir, config-file 이 기대한 위치인지
chezmoi data          # email 과 minimal 이 맞는지
chezmoi execute-template '{{ includeTemplate "enabled-features" . }}'   # 이 머신에서 켜진 기능
chezmoi status        # 비어 있어야 정상
exec $SHELL -l        # 새 셸 (PATH, LG_CONFIG_FILE 등)
nvim                  # 첫 실행에서 lazy.nvim 이 LazyVim 과 플러그인의 최신 버전을, mason 이 LSP 서버와 포맷터를 받는다. :checkhealth
tmux new -s test      # 상태바와 prefix G 팝업 확인
```

### nvim (LazyVim)

nvim 설정은 [LazyVim starter](https://github.com/LazyVim/starter) 구조다. LazyVim 이 기본 플러그인·옵션·키맵을 깔고,
사용자 설정은 그 위에 덮어쓴다: 옵션·키맵·autocmd 는 `home/dot_config/nvim/lua/config/{options,keymaps,autocmds}.lua`,
플러그인 추가·변경·끄기는 `lua/plugins/*.lua` 의 lazy.nvim spec. 기본값은 [lazyvim.org](https://www.lazyvim.org)
(플러그인마다 "Full Spec" 이 실려 있다). 직접 조립하던 이전 설정은 git 태그 `pre-lazyvim` 에 있다.

상태 파일 두 개는 성격이 달라서 따로 둔다.

- `lazyvim.json` (저장소에서 추적): `:LazyExtras` 로 켠 extras 목록과 읽은 NEWS 버전. 어떤 기능을 켤지 정하는
  공용 시작점이다. LazyVim 이 이 저장소의 파일에 직접 쓰고(`lazy.lua.tmpl` 의 `vim.g.lazyvim_json`),
  `home/.chezmoiignore` 가 배포에서 뺀다. 바뀌면 `nvim-extras-push "chore(nvim): lang.typescript extra 켜기"` 가
  이 파일만 골라 커밋·push 한다 (PR 없이 main 에 바로). 다른 머신에서는 pull 한 뒤 nvim 을 다시 띄우면 새 extra 가
  설치된다.
- `lazy-lock.json` (머신마다, 저장소 밖): 플러그인마다 설치된 commit. lazy.nvim 기본 위치
  `~/.config/nvim/lazy-lock.json` 에 있고 chezmoi 가 관리하지 않는다. lazy.nvim 은 관리 밖 `local-*.lua` 로 더한
  머신 전용 플러그인까지 기록하므로 공용 저장소에 두지 않는다. 그래서 머신마다 플러그인 버전이 다를 수 있고,
  새 머신은 처음 띄울 때 최신 버전을 받는다 (mise 의 `"latest"` 와 같은 결).

업데이트는 머신마다 `:Lazy update` 로 한다. 업데이트가 뭔가를 깨뜨리면 직전 lockfile 로 되돌린다. `:Lazy update` /
`sync` / `restore` 직전마다 lockfile 이 `~/.local/state/nvim/lazy-lock-backups/` 에 시각을 붙여 복사된다 (최근 10개,
`lazy.lua.tmpl`). update 가 끝나면 lockfile 이 새 commit 으로 덮어써지기 때문이다.

```sh
ls ~/.local/state/nvim/lazy-lock-backups/                    # 업데이트 직전 시각이 이름
cp ~/.local/state/nvim/lazy-lock-backups/lazy-lock.<시각>.json ~/.config/nvim/lazy-lock.json
nvim +'Lazy restore'                                         # lockfile 의 commit 으로 되돌린다
```

그래서 `:LazyExtras` 는 머신별 설정이 아니다 (어느 머신에서 켜든 저장소가 바뀐다). 한 머신이나 한 프로젝트에서만 쓰는
언어는 관리 밖 `lua/plugins/local-*.lua` 나 프로젝트의 `.lazy.lua` 에 spec 으로 쓴다: [`docs/tool-scope.md`](docs/tool-scope.md).

### 자주 하는 조정

- 이메일이나 git 이름을 바꾸려면: `chezmoi init --prompt` (다시 묻는다). 옵션 없이 `chezmoi init` 을 다시 실행하면 기존 값을 유지한다.
- 기능을 켜고 끄려면: `chezmoi edit-config` 로 `[data.features]` 에 `<이름> = true / false` 를 적고 `chezmoi apply`.
  기본값과 다르게 둘 것만 적는다. 아래 "머신별 기능" 규칙 참고.
- `config file template has changed` 경고가 나오면 `chezmoi init` 을 실행한다. 새로 생긴 질문만 묻고 기존 답과
  `[data.features]` 에 적어 둔 값은 유지한다.
- 스크립트를 강제로 다시 돌리려면 내용을 조금 바꾸거나 `chezmoi state delete-bucket --bucket=entryState` 후 `chezmoi apply`.
- 머신 전용 값은 `*.local` 파일, `~/.config/mise/config.toml`, `~/.config/ghostty/auto/theme.ghostty` 처럼 chezmoi 가 관리하지 않는 자리에 둔다 (`home/.chezmoiignore` 참고).

## 규칙

- **플랫폼 전용 파일**: `.zshrc` → `.zshrc.darwin` / `.zshrc.linux` 처럼 이름에 OS 토큰을 붙이면,
  `home/.chezmoiignore` 가 다른 OS 의 파일을 설치하지 않는다. 기본 파일이 런타임에 해당 OS 파일과
  `.local` 파일을 찾아 불러온다. 실행할 내용이 없는 플랫폼 파일은 만들지 않는다.
- **머신별 기능**: 머신마다 설치 여부가 다른 것은 `packages.yaml` 의 `packages.features.<이름>` 에 블록 하나
  (기본값 `tier`, 패키지 묶음, 꺼진 머신에서 뺄 설정 경로)로 선언한다. 머신의 `chezmoi.toml` 에는 등급(`minimal`)과
  기본값과 다르게 둘 스위치만 적는다. 지금 있는 기능: `ide`, `dev`, `credentials`, `karabiner`. 켜지는 규칙과 기능을
  더하는 방법은 [`docs/machines.md`](docs/machines.md) 한 곳에 있다. 공용 설정 파일 안에서 선택 도구를 부르는 부분은
  템플릿이 아니라 실행 시점의 `command -v` 확인으로 처리한다. 기능을 꺼도 설치된 앱과 이미 배포된 설정 파일은 지우지 않는다
  (관리만 멈춘다). 필요하면 `brew uninstall --cask <이름>` 과 설정 디렉터리 삭제를 손으로 한다.
- **도구의 범위**: 다른 머신에서도 똑같이 필요한 도구만 dotfiles 에 넣는다. 한 머신에서만 쓰면 머신 전용 파일
  (`mise use -g` → `~/.config/mise/config.toml`, `~/.config/nvim/lua/plugins/local-*.lua`), 한 프로젝트에서만 쓰면
  그 프로젝트의 `mise.local.toml` + `.lazy.lua` (`.git/info/exclude` 로 무시) 에 둔다. 범위별 절차와 예시는
  [`docs/tool-scope.md`](docs/tool-scope.md).
- **로컬 오버라이드**: `*.local` 파일은 gitignore 대상이며 chezmoi 가 관리하지 않는다. 머신별 설정은 여기에 둔다.
- **셸 설정** (`home/dot_config/shell/` → `~/.config/shell/`): `profile.sh`(로그인)와 `rc.sh`(대화형)는 다른 것이 기대는
  뼈대만 순서대로 갖는다 (기본 PATH → brew → mise, 프롬프트·키·완성 시스템). 나머지는 파일 하나에 하나씩 둔다.
  | 디렉터리 | 내용 | 읽히는 때 |
  |---|---|---|
  | `profile.d/<도구>.sh` | 도구 하나의 환경 (PATH 한 줄, 환경변수) | 로그인 셸. brew·mise 뒤, 개인 도구 PATH 앞 |
  | `rc.d/<도구>.sh` | 도구 하나의 대화형 초기화 (fzf, fasd 등) | 대화형 셸. 프롬프트와 완성 시스템이 준비된 뒤 |
  | `terminal/<터미널>.<셸>` | 터미널 하나의 셸 통합 (iTerm2, tmux) | 대화형 셸. 맨 나중 |
  | `functions.d/` | 함수 모음 | 대화형 셸. 프롬프트보다 앞 |

  각 파일은 자기 조건(도구가 깔렸는지, 그 터미널 안인지)을 스스로 확인하므로 없는 머신에서는 아무 일도 하지 않는다.
  확장자가 셸을 가린다 (`.sh` 는 zsh·bash 모두, `.zsh` / `.bash` 는 그 셸만). zsh 완성을 등록하는 스크립트(`compdef` 를
  부르는 것)는 `profile.d` 가 아니라 `rc.d/` 에 둔다. 완성 시스템보다 먼저 읽히면 스스로 compinit 을 돌리는
  것이 있다 (bun 의 `_bun`. `rc.d/bun.zsh` 머리말). 이 머신에만 필요한 것은 같은 디렉터리에
  관리 밖 파일 `<이름>.local.sh` 로 둔다. 이름에 `.local.` 이 든 파일은 그 디렉터리의 관리 파일을 다 읽은 뒤에 읽히므로,
  도구 파일이 만든 변수를 쓸 수 있고 PATH·키 바인딩·alias 에서 항상 이긴다.
  그 안에서는 이름순으로 읽히고, 조각끼리는 순서에 기대지 않는 것이 원칙이다.
  PATH 는 나중에 읽힌 것이 이기므로 같은 이름의 명령을 내놓는 도구끼리만 숫자 접두로 먼저 세운다 (지금은
  `profile.d/10-swiftly.sh` 하나: swiftly 의 clang 이 llvm 의 것을 가리지 않게). 맨 끝이어야 하는 것(SDKMAN)은
  디렉터리가 아니라 `rc.sh` 끝에 둔다. 읽는 규칙은 `load-dir.sh` 머리말.
- **초기값만 제공하는 파일**: `create_` 접두사(빈 파일은 `create_empty_`). 대상에 파일이 없을 때만 만들고 이후에는 건드리지 않는다.
  (예: `git config --global` 이 기록하는 `~/.config/git/config`)
- **개인 도구**: `home/dot_jongwan/bin/` → `~/.jongwan/bin/`. 저장소 밖에서 넣은 도구와 섞여 있어도 chezmoi 는 관리하는 파일만 건드린다.
- **한글 상태에서 tmux prefix / Esc (macOS)**: 입력기가 Ghostty 앞단에서 평문자를 가로채 조합하므로, 한글 상태에서는
  `prefix c` 의 `c` 가 tmux 에 닿지 않고 vim normal 모드도 자모를 받는다. tmux 는 입력기 상태를 알 수 없어 자체 해법이 없다.
  그래서 Karabiner-Elements 규칙(`home/dot_config/private_karabiner/private_karabiner.json`)이 Ghostty 가 앞에 있고 입력기가 한글일 때
  `ctrl+b` / `Esc` / `ctrl+[` 를 "영문 전환 + 그 키" 로 바꾼다. 제어 조합은 입력기를 통과하므로 전환이 늦어도 prefix 는 들어가고,
  뒤따르는 키는 영문 상태에서 들어간다. 부작용은 zsh/nvim 에서 `ctrl+b` 를 눌러도 영문으로 바뀌는 것 하나다.
  이 머신에서 아예 쓰지 않으려면 기능 스위치 `features.karabiner = false` (설치도, 설정 배포도 하지 않는다. 위 "머신별 기능").
  잠깐 끄려면 Karabiner 설정 창 Complex Modifications 탭에서 규칙을 끄거나 메뉴바에서 Quit. 설정 창에서 뭔가 바꾸면 Karabiner 가
  `karabiner.json` 을 다시 써서 `chezmoi status` 에 차이가 생기므로, 유지할 변경은 `chezmoi re-add` 로 가져온다.
- **tmux-dev (세션 = 프로젝트, 윈도우 = 워크트리, 패널 = 역할)**: `home/dot_config/tmux/plugins/tmux-dev/` →
  `~/.config/tmux/plugins/tmux-dev/`. tmux 계층을 개발 계층에 대응시키는 확장이며 tmux 의 세션·윈도우를 대체하지 않고
  얹는다(`prefix c` 의 보통 윈도우, 저장소 아닌 세션은 그대로). "플러그인" 의 실체는 tmux.conf 의 `run-shell` 한 줄이
  진입 스크립트 `tmux-dev.tmux` 를 돌리고 그 스크립트가 `bind-key` 를 부르는 것이다(TPM 은 그 위의 설치기일 뿐).
  키·팝업 크기·레이아웃은 `@tmux-dev-*` 사용자 옵션으로 `run-shell` 앞에서 바꾼다. 셸에서는 `tmux-dev project|worktree`
  (bin 이 PATH 에 들어 있다, `--help`).
  - `prefix S` (`tmux-dev project`): 디렉토리 하나를 고르면 그 디렉토리의 세션으로 간다. 없으면 만든다.
  - `prefix W` (`tmux-dev worktree`): 저장소의 워크트리·브랜치를 고르면 그 워크트리의 윈도우로 간다. 없으면 만들고, ctrl-x 로 정리한다.
  - 키, 명령줄 옵션, 설정 항목, 파일 위치, Claude Code 연동은 사용 가이드 [`docs/tmux-dev/`](docs/tmux-dev/README.md)
    (시작하기 · 작업별 안내 · 레퍼런스 · 개념 · 문제 해결). 설계 결정의 기록은 [`docs/tmux-dev/design/`](docs/tmux-dev/design/).
  - tmux.conf 나 진입 스크립트가 바뀌면 `run_onchange_after_40-reload-tmux.sh.tmpl` 이 apply 뒤 살아 있는 tmux 서버에
    `source-file` 을 보낸다 (파일 해시를 주석에 박아 그 파일이 바뀔 때만 실행되는 chezmoi 관례). 서버가 없으면 건너뛴다.

## 자주 쓰는 명령

```sh
chezmoi diff               # 적용 전 차이 확인
chezmoi apply -v           # 소스 상태를 홈에 적용
chezmoi edit --apply FILE  # 소스 파일을 편집하고 바로 적용
chezmoi re-add             # 홈에서 직접 고친 파일을 소스로 다시 가져오기
chezmoi cd                 # 소스 디렉토리로 이동
chezmoi update             # git pull + apply
```
