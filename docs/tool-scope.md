# 개발 도구를 어디에 둘까: 모든 머신 · 일부 머신 · 이 머신 · 이 프로젝트

새 언어나 도구(예: zig/zls)를 쓰기 시작할 때 "dotfiles 에 넣어야 하나?" 를 정하는 기준과, 범위별로 실제로 따라 할 수
있는 절차를 모은다. 이 저장소의 원칙은 **dotfiles 는 머신을 쓰기 위한 최소 공통 설정만 관리한다** 이다. 관리하는 것은
머신 간에 맞추고, 관리하지 않는 것은 맞출 필요가 없다. "어떤 머신에 도구가 없음" 이나 "도구 제거" 까지 dotfiles 로
맞추지는 않는다.

## 한눈에 고르기

| 범위 | 언제 | 설치 (도구 자체) | nvim 연결 (LSP·파서·포맷터) | dotfiles 수정 |
|---|---|---|---|---|
| **모든 머신** | 매일 쓰는 주력 도구 (프론트엔드 등) | `home/dot_config/mise/conf.d/shared.toml`, `packages.yaml` | `:LazyExtras` → `lazyvim.json`, `lua/plugins/*.lua` | 함 |
| **일부 머신 (관리)** | 개인 머신 둘에서만 맞춰 쓰는 것 | `features.<이름>` 스위치 (아래 B) | 모든 머신과 같은 nvim 설정. 도구가 없는 머신에서는 런타임에 건너뜀 | 함 |
| **이 머신만** | 한 머신에서 잠깐, 또는 관리할 만큼 중요하지 않은 것 | `mise use -g …` → `~/.config/mise/config.toml` | `~/.config/nvim/lua/plugins/local-*.lua` (관리 밖 파일) | 안 함 |
| **이 프로젝트만** | 특정 저장소에서만 쓰는 도구·버전 (Zig/Ghostty 등) | 프로젝트의 `mise.local.toml` | 프로젝트의 `.lazy.lua` | 안 함 |

헷갈리면: **다른 머신에서도 똑같이 필요하면 dotfiles, 아니면 머신이나 프로젝트에 둔다.** 나중에 범위를 넓히는 것은 쉽다
(파일 내용을 dotfiles 쪽으로 옮기면 된다).

## 알아 둘 동작

- **`:LazyExtras` 는 머신별이 아니다.** `lazyvim.json` 은 이 저장소의 파일에 직접 쓰이고 git 으로 추적된다
  (`lua/config/lazy.lua.tmpl` 의 `vim.g.lazyvim_json`). 어느 머신에서 extra 를 켜면 저장소가 바뀌고, 커밋하면 모든 머신의
  설정이 된다. 한 머신이나 한 프로젝트에서만 쓰려면 아래 C, D 처럼 spec 파일로 쓴다.
- **도구가 없으면 nvim 은 조용히 건너뛴다.** `vim.lsp.enable("zls")` 를 했는데 PATH 에 `zls` 가 없으면 Neovim 은 서버를
  시작하지 않고 `:LspLog` 에만 남긴다 (`:checkhealth vim.lsp` 에는 경고). 그래서 공용 nvim 설정에 언어를 켜 두어도 그
  도구가 없는 머신에서 문제가 되지 않는다.
- **컴파일러와 버전이 맞아야 하는 LSP 는 Mason 이 아니라 mise 로.** zls ↔ zig 처럼 0.x 마이너 버전이 맞아야 하는 서버는
  컴파일러와 같은 mise 파일에 함께 고정한다. nvim 쪽에서는 `servers = { zls = { mason = false } }` 로 Mason 설치를 끈다.
  Mason 의 bin 디렉터리는 nvim 안에서 PATH 맨 앞에 붙으므로, Mason 에 같은 서버가 설치돼 있으면 mise 것을 가린다.
- **local spec 파일에서 extra 를 import 하지 않는다.** LazyVim 은 "extras 는 사용자 `plugins` 보다 먼저 import" 를 검사하고
  어기면 경고한다 (`lazyvim/config/init.lua`). `lua/plugins/` 나 `.lazy.lua` 는 그보다 뒤에 붙으므로
  `{ import = "lazyvim.plugins.extras.lang.zig" }` 대신 extra 가 하는 일 중 필요한 spec 만 직접 쓴다.
  extra 내용은 `~/.local/share/nvim/lazy/LazyVim/lua/lazyvim/plugins/extras/` 에서 읽을 수 있다.
- **프로젝트 설정은 그 디렉터리에서 띄워야 적용된다.** mise 는 셸의 현재 디렉터리로, lazy.nvim 의 `.lazy.lua` 는 nvim
  시작 시 cwd 와 그 상위에서 찾는다. `cd <프로젝트> && nvim` (tmux-dev 레이아웃은 프로젝트 디렉터리에서 띄운다).

---

## A. 모든 머신: dotfiles 에 넣는다

### 예 A-1. LazyVim extra 켜기 (예: Python)

```sh
nvim                 # :LazyExtras → lang.python 에서 x → nvim 재시작 (Mason 이 pyright 등 설치)
nvim-lock-push "chore(nvim): lang.python extra 켜기"   # lazyvim.json + lazy-lock.json 만 커밋·push
```

다른 머신: `chezmoi git -- pull --ff-only` → `nvim` → `:Lazy restore`.

### 예 A-2. 모든 머신에 런타임 추가

`home/dot_config/mise/conf.d/shared.toml` 의 `[tools]` 에 한 줄 추가하고 PR. 머지 뒤 `chezmoi apply` 하면 설치 스크립트가
`mise install` 을 다시 돈다 (파일 해시가 스크립트에 박혀 있다).

```toml
[tools]
deno = "latest"
```

---

## B. 일부 머신 (관리): `features.<이름>` 스위치

개인 머신 여러 대에서 **같게 맞추고 싶은** 도구. 스위치 값은 머신의 `~/.config/chezmoi/chezmoi.toml` 에 있고 저장소에는
들어가지 않는다. `false` 는 "이 머신에서 안 쓴다" 가 아니라 "dotfiles 가 관리하지 않는다" 이다 (손으로 깔아 써도 된다).
자세한 규칙은 README 의 "머신별 기능".

### 예 B-1. 기존 스위치 바꾸기

```sh
$EDITOR ~/.config/chezmoi/chezmoi.toml   # [data.features] karabiner = true / false
chezmoi apply                            # 켠 기능의 패키지 설치, 설정 파일 배포
```

### 예 B-2. 새 기능 추가 (brew 앱 하나)

1. `home/.chezmoidata/packages.yaml` 의 `packages.darwin.features` 에 묶음:
   ```yaml
   features:
     myapp:
       casks:
         - myapp
   ```
2. `home/.chezmoi.toml.tmpl` 의 darwin 블록에 묻는 줄 (`karabiner` 를 본뜬다) 과 `[data.features]` 의 `myapp = {{ $myapp }}`.
3. 그 도구 전용 설정 파일이 있으면 `home/.chezmoiignore` 에 스위치가 꺼졌을 때 뺄 경로.
4. PR → 머지 → 각 머신에서 `chezmoi init` (새 질문만 묻는다) → `chezmoi apply`.

mise 로 설치하는 도구라면 brew 묶음 대신 `home/dot_config/mise/conf.d/<이름>.toml` 을 만들고 3 처럼 스위치로 뺀다.
이때 `run_onchange_after_20-install-mise-tools.sh.tmpl` 에 그 파일의 해시와 스위치 값을 넣어야 켜거나 버전을 바꿀 때
`mise install` 이 다시 돈다.

---

## C. 이 머신만: 관리 밖 파일에 둔다 (dotfiles 수정 없음)

### 예 C-1. 이 머신 전체에 도구 설치

```sh
mise use -g gleam@latest        # ~/.config/mise/config.toml 에 기록 (chezmoi 가 관리하지 않는 머신 전용 파일)
mise ls --global                # 무엇이 어느 파일에서 왔는지
```

`shared.toml` 에 이미 있는 도구를 이 머신에서만 다른 버전으로 쓰려면 반드시 `-p` 로 머신 파일을 지정한다
(안 그러면 공유 파일이 바뀌어 `chezmoi status` 에 잡힌다):

```sh
mise use -g -p ~/.config/mise/config.toml node@22
```

### 예 C-2. 이 머신의 nvim 에만 언어 연결 (Zig 를 이 머신 어디서나)

```sh
mise use -g zig@0.17 zls@0.17
```

```lua
-- ~/.config/nvim/lua/plugins/local-zig.lua  (chezmoi 관리 밖. 이 머신에만 있다)
return {
  { "nvim-treesitter/nvim-treesitter", opts = { ensure_installed = { "zig" } } },
  { "neovim/nvim-lspconfig", opts = { servers = { zls = { mason = false } } } },
}
```

chezmoi 는 관리하지 않는 파일을 지우지 않는다 (`.chezmoiremove` 에 적힌 옛 파일만 지운다). 관리 밖 파일이 무엇이 있는지는:

```sh
chezmoi unmanaged ~/.config/nvim
```

git 기록이 없어 잊기 쉬우므로 이름을 `local-*.lua` 로 맞춰 둔다. 지우려면 파일만 지우고 nvim 재시작.

---

## D. 이 프로젝트만: 프로젝트 안에 둔다 (dotfiles 수정 없음)

남의 저장소(오픈소스 기여)나 팀 저장소처럼 **설정 파일을 커밋할 수 없는** 곳은 `.git/info/exclude` 로 이 클론에서만
무시한다 (`.gitignore` 와 같은 문법, 커밋되지 않음). 자기 저장소라면 `mise.toml` / `.lazy.lua` 를 그냥 커밋해도 된다.

### 예 D-1. Ghostty 기여용 Zig 환경 (이 Mac 에 적용한 그대로)

```sh
cd ~/dev/opensources/ghostty
mise use --env local zig@0.17 zls@0.17          # → mise.local.toml, zls 설치
printf '\n# 이 클론에서만 쓰는 로컬 개발 환경 (커밋하지 않음)\nmise.local.toml\n.lazy.lua\n' >> .git/info/exclude
```

```lua
-- ~/dev/opensources/ghostty/.lazy.lua
-- lazy.nvim 의 local spec: nvim 을 이 디렉터리(또는 하위)에서 띄우면 읽어 spec 맨 끝에 붙인다.
return {
  { "nvim-treesitter/nvim-treesitter", opts = { ensure_installed = { "zig" } } },
  { "neovim/nvim-lspconfig", opts = { servers = { zls = { mason = false } } } },
}
```

```sh
git status --short              # 아무것도 안 나와야 한다 (두 파일 모두 무시됨)
zig version && zls --version    # 0.17.x / 0.17.x  (ghostty 디렉터리 안에서)
nvim src/main.zig
```

처음 띄우면 `.lazy.lua` 를 신뢰할지 묻는다 (`vim.secure`). 파일에는 허용(allow) 선택지가 없고
`(i)gnore / (v)iew / (d)eny` 만 나온다 (Neovim 0.12):

1. **v** 를 고르면 `.lazy.lua` 가 버퍼로 열린다. 내용을 확인하고 `:trust` (현재 버퍼를 신뢰 목록에 추가).
2. 이번 시작에서는 이미 건너뛰었으므로 nvim 을 다시 띄운다. 이후로는 묻지 않고, 파일 내용이 바뀌면 다시 묻는다.

확인:

```vim
:checkhealth vim.lsp      " zls 가 붙었는지, 실행 파일 경로가 ~/.local/share/mise/installs/zls/... 인지
```

2026-11-09 이 Mac 에서 확인한 결과: `zls 0.17.0` (mise) 이 `root=~/dev/opensources/ghostty` 로 붙고, zig treesitter
강조 동작.

### 예 D-2. 프로젝트마다 다른 Node 버전

```sh
cd ~/dev/some-legacy-app
mise use --env local node@18    # 이 디렉터리에서만 node 18. nvim 의 vtsls·eslint 도 이 node 로 돈다 (같은 PATH)
echo 'mise.local.toml' >> .git/info/exclude
```

팀이 이미 `.nvmrc` / `.node-version` 을 커밋해 두었다면 mise 가 읽을 수 있으므로 따로 만들 필요가 없다
(`mise settings add idiomatic_version_file_enable_tools node`).

### 예 D-3. 남이 커밋해 둔 `.lazy.lua` 를 열 때

`.lazy.lua` 는 Lua 코드라 실행 전에 확인을 받는다. 처음 보는 저장소에서 질문이 나오면 **v** (view) 로 내용을 읽고,
믿을 수 있으면 `:trust` 후 nvim 재시작, 아니면 그대로 닫는다 (또는 질문에서 **d** (deny): 다시 묻지 않고 계속 무시).
신뢰 목록 관리는 `:trust` (현재 버퍼 허용), `:trust ++deny`, `:trust ++remove`. 목록 파일은
`~/.local/state/nvim/trust`. `:trust <파일>` 처럼 파일을 인자로 주는 형태는 내용을 보지 않고 신뢰하게 되므로
(도움말의 TOCTOU 경고) 쓰지 않는다.

---

## 범위 넓히기 / 정리하기

| 하고 싶은 것 | 할 일 |
|---|---|
| D 나 C 로 쓰던 것을 모든 머신으로 | `.lazy.lua` / `local-*.lua` 의 spec 을 `home/dot_config/nvim/lua/plugins/` 로, mise 줄을 `shared.toml` 로 옮겨 PR. extra 가 있으면 spec 대신 `:LazyExtras` |
| 프로젝트에서 그만 쓰기 | 그 두 파일 삭제 (`mise.local.toml`, `.lazy.lua`). 설치된 버전은 `mise prune` 으로 정리 |
| 이 머신에서 그만 쓰기 | `mise unuse -g zig zls`, `local-*.lua` 삭제 |
