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

## 새 머신 설정

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply jjmean2
```

저장소는 `~/.local/share/chezmoi` 에 클론된다.

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
