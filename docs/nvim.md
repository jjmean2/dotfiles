# nvim (LazyVim)

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
언어는 관리 밖 `lua/plugins/local-*.lua` 나 프로젝트의 `.lazy.lua` 에 spec 으로 쓴다: [`tool-scope.md`](tool-scope.md).
