# 저장소 규칙

이 저장소에 파일을 더하거나 옮길 때 따르는 규칙이다. 머신마다 무엇을 까는지는 [`machines.md`](machines.md),
개발 도구를 어느 범위에 둘지는 [`tool-scope.md`](tool-scope.md) 에 따로 있다.

## 플랫폼 전용 파일

`.zshrc` → `.zshrc.darwin` / `.zshrc.linux` 처럼 이름에 OS 토큰을 붙이면,
`home/.chezmoiignore` 가 다른 OS 의 파일을 설치하지 않는다. 기본 파일이 런타임에 해당 OS 파일과
`.local` 파일을 찾아 불러온다. 실행할 내용이 없는 플랫폼 파일은 만들지 않는다.

## 머신별 기능

머신마다 설치 여부가 다른 것은 `packages.yaml` 의 `packages.features.<이름>` 에 블록 하나
(기본값 `tier`, 패키지 묶음, 꺼진 머신에서 뺄 설정 경로)로 선언한다. 머신의 `chezmoi.toml` 에는 등급(`minimal`)과
기본값과 다르게 둘 스위치만 적는다. 지금 있는 기능: `ide`, `dev`, `credentials`, `karabiner`, `herdr`. 켜지는 규칙과 기능을
더하는 방법은 [`machines.md`](machines.md) 한 곳에 있다. 공용 설정 파일 안에서 선택 도구를 부르는 부분은
템플릿이 아니라 실행 시점의 `command -v` 확인으로 처리한다. 기능을 꺼도 설치된 앱과 이미 배포된 설정 파일은 지우지 않는다
(관리만 멈춘다). 필요하면 `brew uninstall --cask <이름>` 과 설정 디렉터리 삭제를 손으로 한다.

## 도구의 범위

다른 머신에서도 똑같이 필요한 도구만 dotfiles 에 넣는다. 한 머신에서만 쓰면 머신 전용 파일
(`mise use -g` → `~/.config/mise/config.toml`, `~/.config/nvim/lua/plugins/local-*.lua`), 한 프로젝트에서만 쓰면
그 프로젝트의 `mise.local.toml` + `.lazy.lua` (`.git/info/exclude` 로 무시) 에 둔다. 범위별 절차와 예시는
[`tool-scope.md`](tool-scope.md).

## 로컬 오버라이드

`*.local` 파일은 gitignore 대상이며 chezmoi 가 관리하지 않는다. 머신별 설정은 여기에 둔다.

## 셸 설정

`home/dot_config/shell/` → `~/.config/shell/`.

`profile.sh`(로그인)와 `rc.sh`(대화형)는 다른 것이 기대는
뼈대만 순서대로 갖는다 (기본 PATH → brew → mise, 프롬프트·키·완성 시스템). 나머지는 파일 하나에 하나씩 둔다.

| 디렉터리 | 내용 | 읽히는 때 |
|---|---|---|
| `profile.d/<도구>.sh` | 도구 하나의 환경 (PATH 한 줄, 환경변수) | 로그인 셸. brew·mise 뒤, 개인 도구 PATH 앞 |
| `rc.d/<도구>.sh` | 도구 하나의 대화형 초기화 (fzf, zoxide 등) | 대화형 셸. 프롬프트와 완성 시스템이 준비된 뒤 |
| `plugins.zsh` | zsh 플러그인. 서로 순서가 있어 파일 하나에 순서대로 적는다 ([`zsh-plugins.md`](zsh-plugins.md)) | zsh 대화형 셸. `rc.d/` 다음 |
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

## 초기값만 제공하는 파일

`create_` 접두사(빈 파일은 `create_empty_`). 대상에 파일이 없을 때만 만들고 이후에는 건드리지 않는다.
(예: `git config --global` 이 기록하는 `~/.config/git/config`)

## 개인 도구

`home/dot_jongwan/bin/` → `~/.jongwan/bin/`. 저장소 밖에서 넣은 도구와 섞여 있어도 chezmoi 는 관리하는 파일만 건드린다.
