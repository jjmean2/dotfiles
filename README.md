# dotfiles

[chezmoi](https://www.chezmoi.io/) 로 관리하는 개인 개발 환경 설정 저장소.

## 디렉토리 구조

| 경로 | 내용 |
|---|---|
| `home/` | chezmoi 소스 상태 (`.chezmoiroot` 로 지정). 홈 디렉토리에 배포된다 |
| `home/.chezmoidata/packages.yaml` | OS 별 설치 패키지 목록 |
| `home/.chezmoiscripts/` | 패키지/도구 설치 스크립트. `run_onchange_` 라서 내용이 바뀔 때만 다시 실행된다 |
| `docos/<project>/docker-compose.yml` | 로컬에서 띄우는 docker compose 서비스. `doco <project> up` 으로 실행 |
| `snippets/` | 기억해 두고 싶은 코드 스니펫 |

`home/` 밖의 파일은 chezmoi 가 배포하지 않는다.

## 설치

### 사전 준비

- macOS: `xcode-select --install` (git). Homebrew 는 설치 스크립트가 없으면 깔아 준다.
- Linux: `curl`, `git`, `sudo`.
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

### 첫 apply 에서 일어나는 일

1. `.chezmoi.toml.tmpl` 이 이메일을 묻고 `~/.config/chezmoi/chezmoi.toml` 을 만든다 (한 번만 묻는다).
2. `run_onchange_before_*`: Homebrew 설치, `packages.yaml` 의 brew/cask 설치 (macOS) 또는 배포판 패키지와 mise 본체 설치 (Linux). 몇 분 걸린다.
3. `home/` 의 파일이 홈에 배포된다.
4. `run_onchange_after_*`: `mise install` 로 `conf.d/shared.toml` 의 런타임 설치, fasd, (macOS) tmux/ghostty terminfo.
5. 이후 `chezmoi apply` 는 바뀐 파일만 다시 쓰고, 스크립트는 내용이 바뀐 것만 다시 돈다.

### 설치 후 확인

```sh
chezmoi doctor        # source-dir, config-file 이 기대한 위치인지
chezmoi data          # email 이 맞는지
chezmoi status        # 비어 있어야 정상
exec $SHELL -l        # 새 셸 (PATH, LG_CONFIG_FILE 등)
nvim                  # 첫 실행에서 lazy.nvim 이 플러그인을, mason 이 LSP 서버를 받는다. :checkhealth
tmux new -s test      # 상태바와 prefix G 팝업 확인
```

### 자주 하는 조정

- 이메일을 바꾸려면: `chezmoi init --prompt` (다시 묻는다). 옵션 없이 `chezmoi init` 을 다시 실행하면 기존 값을 유지한다.
- 스크립트를 강제로 다시 돌리려면 내용을 조금 바꾸거나 `chezmoi state delete-bucket --bucket=entryState` 후 `chezmoi apply`.
- 머신 전용 값은 `*.local` 파일, `~/.config/mise/config.toml`, `~/.config/ghostty/auto/theme.ghostty` 처럼 chezmoi 가 관리하지 않는 자리에 둔다 (`home/.chezmoiignore` 참고).

## 규칙

- **플랫폼 전용 파일**: `.zshrc` → `.zshrc.darwin` / `.zshrc.linux` 처럼 이름에 OS 토큰을 붙이면,
  `home/.chezmoiignore` 가 다른 OS 의 파일을 설치하지 않는다. 기본 파일이 런타임에 해당 OS 파일과
  `.local` 파일을 찾아 불러온다. 실행할 내용이 없는 플랫폼 파일은 만들지 않는다.
- **로컬 오버라이드**: `*.local` 파일은 gitignore 대상이며 chezmoi 가 관리하지 않는다. 머신별 설정은 여기에 둔다.
- **초기값만 제공하는 파일**: `create_` 접두사(빈 파일은 `create_empty_`). 대상에 파일이 없을 때만 만들고 이후에는 건드리지 않는다.
  (예: `git config --global` 이 기록하는 `~/.config/git/config`)
- **개인 도구**: `home/dot_jongwan/bin/` → `~/.jongwan/bin/`. 저장소 밖에서 넣은 도구와 섞여 있어도 chezmoi 는 관리하는 파일만 건드린다.

## 자주 쓰는 명령

```sh
chezmoi diff               # 적용 전 차이 확인
chezmoi apply -v           # 소스 상태를 홈에 적용
chezmoi edit --apply FILE  # 소스 파일을 편집하고 바로 적용
chezmoi re-add             # 홈에서 직접 고친 파일을 소스로 다시 가져오기
chezmoi cd                 # 소스 디렉토리로 이동
chezmoi update             # git pull + apply
```
