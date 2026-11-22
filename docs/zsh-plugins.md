# zsh 플러그인

zsh 에는 플러그인이라는 장치가 따로 없다. 플러그인은 `source` 로 읽는 zsh 스크립트이고, 줄 편집기(ZLE)의 위젯을
감싸거나(`zle -N`), 입력 줄에 색을 칠하거나(`region_highlight`), 커서 뒤에 글자를 보여 주는(`POSTDISPLAY`) zsh 고유
장치를 쓴다. 그래서 이 저장소는 플러그인 관리자(oh-my-zsh, antidote, zinit …) 없이 두 파일로 관리한다.

| 파일 | 맡는 것 |
|---|---|
| `home/.chezmoiexternal.toml` | **무엇을 받나**: 플러그인마다 태그와 체크섬을 고정한 소스 묶음. `chezmoi apply` 가 `~/.local/share/zsh/plugins/<이름>` 에 푼다 |
| `home/dot_config/shell/plugins.zsh` | **어떤 순서와 설정으로 읽나**: 플러그인마다 블록 하나 (조건, 설정 변수, `source`) |

모든 머신(minimal 포함, `jw-ephemeral` 도)에 깔린다. 스크립트뿐이라 설치 스크립트가 필요 없고 (gitstatus 만 실행 파일이 하나 더 있다. 아래 "gitstatus" 절), 받지 못했으면 셸은
그 플러그인 없이 뜬다.

## 지금 있는 것

| 순서 | 플러그인 | 하는 일 | 쓰는 법 |
|---|---|---|---|
| 0 | [gitstatus](https://github.com/romkatv/gitstatus) | 프롬프트의 git 칸을 셸마다 뜨는 데몬(gitstatusd)에게 비동기로 묻는다 | 따로 없다. 프롬프트가 쓴다 (`shell/prompt.zsh`). 아래 "gitstatus" 절 |
| 1 | [fzf-tab](https://github.com/Aloxaf/fzf-tab) | Tab 완성 목록을 fzf 로 고른다 | Tab → 글자로 걸러내고 Enter. `<` `>` 로 종류 바꾸기. `cd` 는 오른쪽에 미리보기 |
| 2 | [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | 히스토리에서 찾은 나머지를 흐린 글씨로 보여 준다 | → 또는 End 로 받기, Option+→ 로 한 단어씩 |
| 3 | [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) | 입력 중인 명령에 색을 칠한다 | 없는 명령은 빨강. 짝이 맞지 않는 괄호 표시 |

순서에는 이유가 있다 (`plugins.zsh` 머리말). gitstatus 는 키나 위젯을 건드리지 않아 순서와 상관없고, 데몬이 일찍
뜨도록 맨 앞에 둔다. fzf-tab 은 compinit 과 fzf 의 Tab 바인딩 뒤에서 Tab 을 마지막으로 잡아야 하고,
syntax-highlighting 은 모든 위젯이 만들어진 뒤 맨 마지막에 읽혀야 한다. 그래서 순서에 기대지 않는 `rc.d/` 조각이
아니라 파일 하나에 순서대로 적는다.

셸 시작 시간에 더해지는 것: 세 개를 합쳐 약 13 ms (2026-11-17, Apple Silicon Mac, `zsh -i -c exit` 10번 평균 83 → 96 ms).
입력 제안이 첫 프롬프트에서 하는 준비는 이 숫자에 들어 있지 않다. gitstatus 는 데몬을 띄우기만 해서 약 3 ms 를 더한다
(2026-11-22, Linux 컨테이너, 다른 플러그인 없이 20번 평균 24 → 27 ms).

## gitstatus

다른 플러그인과 달리 **실행 파일(gitstatusd)이 따로 있다**. 플러그인 소스(zsh 함수)는 `.chezmoiexternal.toml` 이,
실행 파일은 OS·아키텍처마다 달라서 `home/.chezmoiexternals/gitstatus.toml.tmpl` 이 받는다
(`~/.local/share/gitstatus/gitstatusd-<os>-<arch>`). 플러그인은 원래 처음 실행할 때 실행 파일을 인터넷에서 받는데,
`plugins.zsh` 가 그것을 끄고(`GITSTATUS_AUTO_INSTALL=0`) chezmoi 가 체크섬을 고정해 받은 것만 쓴다.
받는 것은 macOS arm64·x86_64, Linux x86_64·aarch64 네 가지다.

- **어떻게 쓰이나**: `plugins.zsh` 가 데몬을 띄우고(`gitstatus_start -a`), `prompt.zsh` 가 프롬프트마다 묻는다. 20 ms 안에
  답이 오면 바로 그리고, 늦으면 지난 결과를 흐리게 그린 뒤 답이 오는 대로 다시 그린다. 자세한 흐름은 `prompt.zsh` 머리말.
- **없거나 꺼져 있으면**: 실행 파일이 없는 머신, `JW_ZSH_PLUGINS_DISABLE='gitstatus'` 로 끈 머신, 데몬이 죽은 셸에서는
  프롬프트마다 `git status` 를 직접 부른다 (`shell/_ps_set_git_status.bash`, bash 프롬프트와 같은 것). 표시는 같다.
  지금 어느 쪽인지는 `echo $_jw_git_engine` (`gitstatus` 또는 `sync`).
- **얼마나 빠른가**: 프롬프트 하나의 git 칸에 작은 저장소 5.0 → 0.8 ms, 파일 12만 개 저장소 약 100 → 34 ms
  (2026-11-22, Linux 컨테이너). 늦은 답도 기다리지 않으므로 큰 저장소에서도 Enter 뒤에 셸이 멈추지 않는다.
- **버전 올리기**: `.chezmoiexternal.toml` 의 태그와 체크섬을 바꾼 뒤, 그 태그의 `install.info` 에 적힌 플랫폼별 실행 파일
  `version` 과 `sha256` 을 `gitstatus.toml.tmpl` 에 옮긴다 (플러그인 태그와 실행 파일 버전이 다를 수 있다). 맞지 않으면
  데몬이 뜨지 않고 프롬프트는 `git status` 로 대신한다.
- **빼기**: 아래 "빼기" 에 더해 `gitstatus.toml.tmpl` 을 지우고, `.chezmoiremove` 에 `.local/share/gitstatus` 도 적는다.
  저장소(`.git`)나 git 설정에는 아무것도 남기지 않는다. 열려 있던 셸의 데몬은 그 셸이 닫힐 때 같이 끝난다.
- **데몬이 안 뜬다**: 새 셸에서 `GITSTATUS_LOG_LEVEL=DEBUG zsh` 로 띄우면 `$TMPDIR` 에 로그가 남는다
  (`gitstatus.JW.*.log`). 실행 파일이 있는지는 `ls ~/.local/share/gitstatus`.

## 더하기

1. 태그 묶음의 체크섬을 구한다.
   ```sh
   curl -fsSL https://github.com/<owner>/<repo>/archive/refs/tags/<태그>.tar.gz | shasum -a 256
   ```
2. `home/.chezmoiexternal.toml` 에 블록 하나. 디렉터리 이름은 진입 파일 `<이름>.plugin.zsh` 의 `<이름>` 과 같게 한다.
   ```toml
   [".local/share/zsh/plugins/<이름>"]
       type = "archive"
       url = "https://github.com/<owner>/<repo>/archive/refs/tags/<태그>.tar.gz"
       checksum.sha256 = "<체크섬>"
       stripComponents = 1
       exact = true
   ```
3. `plugins.zsh` 에 블록 하나를 **순서에 맞는 자리에** 넣는다. 위젯을 감싸는 플러그인은 fzf-tab 뒤, syntax-highlighting 앞이다.
   설정 변수는 플러그인 문서가 "source 전에" 라고 하면 `source $REPLY` 앞에 둔다.
   ```zsh
   if _jw_plugin <이름>; then
   	SOME_SETTING=...
   	source $REPLY
   fi
   ```
4. `chezmoi apply` 후 새 셸에서 확인한다.

## 버전 올리기

`url` 의 태그와 `checksum.sha256` 을 같이 바꾸고 `chezmoi apply`. `exact = true` 라서 새 버전에 없는 옛 파일은 지워진다.
체크섬이 다르면 apply 가 받은 것을 쓰지 않고 실패한다. 새 버전의 변경 기록(CHANGELOG)에서 설정 변수 이름이 바뀌지 않았는지 본다.

## 빼기

1. `plugins.zsh` 의 블록과 `.chezmoiexternal.toml` 의 블록을 지운다.
2. 머신에 남은 디렉터리는 chezmoi 가 지우지 않는다 (관리만 멈춘다). `home/.chezmoiremove` 에
   `.local/share/zsh/plugins/<이름>` 을 적으면 다음 apply 때 지워진다.

## 이 머신에서만 끄기

관리 밖 파일 `~/.config/shell/rc.d/plugins.local.zsh` 에 적는다 (`rc.d/` 는 `plugins.zsh` 보다 먼저 읽힌다).

```zsh
JW_ZSH_PLUGINS_DISABLE='fzf-tab zsh-syntax-highlighting'
```

## 문제가 생겼을 때

- **Tab 이 fzf-tab 이 아니다**: `bindkey '^I'` 가 `fzf-tab-complete` 여야 한다. 아니면 그 뒤에 Tab 을 다시 묶은 것이 있다.
  fzf-tab 의 내부 상태는 `Ctrl-X .` (fzf-tab-debug) 로 본다.
- **어느 플러그인 탓인지 모르겠다**: 위의 `JW_ZSH_PLUGINS_DISABLE` 로 하나씩 끄고 새 셸을 띄운다.
- **apply 가 체크섬 불일치로 멈춘다**: GitHub 가 태그 묶음을 다시 만들어 바이트가 달라진 경우다 (드물다). 받은 내용과
  태그를 확인하고 "더하기" 1번의 명령으로 체크섬을 다시 구해 바꾼다. 그동안은 `chezmoi apply --exclude=externals` 로
  나머지를 적용할 수 있다.
- **셸이 느려졌다**: `zsh-perf -i` 로 시작 과정의 명령별 시간을 본다.
