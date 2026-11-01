-- git: gitsigns.nvim.
--
-- 역할 분담 (2단계에서 정함, 키 배치는 LazyVim 과 같다)
--   편집 중 "이 줄이 바뀌었나, 무엇이 바뀌었나, 되돌릴까" → gitsigns (이 파일), <leader>gh*
--   목록 (저장소 전체 hunk, status)                        → snacks 피커, <leader>gd / gs
--   로그, 파일 히스토리, 스테이징·커밋·브랜치             → lazygit. nvim 안에서는 <leader>gg/gl/gf
--                                                           (snacks lazygit 모듈: 컬러스킴에서 테마 생성,
--                                                           e 로 연 파일은 이 nvim 에 열림), nvim 밖에서는
--                                                           tmux prefix G 팝업
--   파일 비교                                              → gitsigns diffthis 가 여는 순정 diff 모드
-- diffview.nvim 은 2024-08 이후 커밋이 없어 넣지 않았다. fugitive 는 성숙하지만 크고 오래된
-- 쪽이라 보류. 둘이 하던 일은 위 셋으로 나뉜다.
--
-- 멘탈 모델: gitsigns 는 버퍼 내용과 git index(또는 지정한 리비전)를 비교해 hunk 목록을
-- 만들고, 그 결과를 (1) sign column 표시 (2) hunk 단위 조작 (3) 순정 diff 모드 호출로
-- 내보낸다. 순정 대응은 각각 :!git diff %, git add -p / git checkout -p,
-- :vnew | r !git show HEAD:./# | windo diffthis 이다.
if vim.g.vscode then
  return {}
end

return {
  {
    "lewis6991/gitsigns.nvim",
    -- 파일을 읽을 때 붙는다. git 저장소 밖 파일에는 조용히 붙지 않는다.
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      -- sign column 글자는 기본값(┃ _ ‾ ~ ┆)을 쓴다. signs_staged 로 스테이징된 hunk 는
      -- 다른 하이라이트로 구분된다.
      signcolumn = true,
      -- 줄 끝 blame 가상 텍스트. 항상 켜 두면 시끄러워서 꺼 두고 <leader>tb 로 토글한다.
      current_line_blame = false,
      current_line_blame_opts = { delay = 500 },
      -- 미추적 파일에는 붙지 않는다 (전부 "추가" 로 표시되어 의미가 없다).
      attach_to_untracked = false,
    },
    -- 키맵은 lua/config/keymaps.lua 의 git 절에 있다.
  },
}
