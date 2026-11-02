-- 피커(fuzzy finder): snacks.picker.
-- 1단계에서 fzf-lua 와 나란히 써 본 뒤 snacks 를 골랐다 (피커 안에서 vim 키로 움직이는
-- 노멀 모드가 결정적이었다). 키맵은 lua/config/keymaps.lua 의 "피커" 절에 있다.
--
-- 멘탈 모델
--   source  : 후보를 만드는 쪽. 파일 목록(fd), grep 결과(rg), 버퍼, LSP 심볼, 명령어, 도움말
--   picker  : 플로팅 창에 프롬프트 + 목록 + 미리보기를 띄우고 fuzzy 로 좁힌다 (순수 Lua 매처)
--   action  : 고른 항목에 할 일. 열기 / 분할로 열기 / 탭으로 열기 / 여러 개를 quickfix 로
-- 순정 대응: :find, :grep + :copen, :ls + :b, :h, :map, grr, gO. 피커는 이 목록들로
-- 들어가는 입구이고, 결과를 쌓아 돌아다니는 건 여전히 quickfix 다.
--
-- snacks.nvim 은 모듈 묶음이다. 여기서는 picker 만 켠다. 명시하지 않은 모듈은 꺼져 있고,
-- 켜고 끄는 것은 enabled 스위치 하나라 되돌리기 쉽다. priority/lazy=false 는 snacks 가
-- 권장하는 로드 방식이다.
if vim.g.vscode then
  return {}
end

return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      picker = {
        enabled = true,
        -- 열릴 때 포커스. 기본은 목록("list"): 노멀 모드라 j/k/gg/G 로 돌아다니고 Enter 로
        -- 열며, i 또는 / 로 입력창에 가서 타이핑으로 좁힌다. snacks 기본값 "input" 은 열리자마자
        -- insert 모드라 j 가 검색어로 들어간다.
        -- 소스 성격에 따라 나눈다: "목록을 돌아다니며 고르는 것" 은 list, "검색어를 치는 것" 은
        -- input. 아래 sources 에 없는 소스는 전부 list 다.
        focus = "list",
        sources = {
          -- 타이핑이 먼저인 소스: 열리자마자 입력창(insert)
          files = { focus = "input" },        -- <leader>ff, <leader><leader>
          grep = { focus = "input" },         -- <leader>fg
          help = { focus = "input" },         -- <leader>fh
          commands = { focus = "input" },     -- <leader>fc
          keymaps = { focus = "input" },      -- <leader>fk
          lsp_symbols = { focus = "input" },  -- <leader>fs: 심볼 이름을 치는 게 보통
          -- 목록을 돌아다니는 소스(list 유지): buffers, recent, projects, lsp_references,
          -- diagnostics_buffer, git_diff, git_status, qflist, resume
        },
        -- true 로 하면 vim.ui.select (gra 코드 액션 메뉴, 순정 선택 프롬프트) 가 snacks
        -- 피커로 바뀐다. 순정 UI 를 먼저 익힌 뒤 켤지 정하기로 하고 지금은 끈다.
        ui_select = false,
      },
    },
  },
}
