-- 피커(fuzzy finder). 1단계 비교 기간 동안 fzf-lua 와 snacks.picker 를 함께 설치한다.
-- 키맵은 lua/config/keymaps.lua 의 "피커" 절에 있다. 결정 뒤 한쪽을 지운다.
--
-- 멘탈 모델 (둘 다 같다)
--   source  : 후보를 만드는 쪽. 파일 목록(fd), grep 결과(rg), 버퍼, LSP 심볼, 명령어, 도움말
--   picker  : 플로팅 창에 프롬프트 + 목록 + 미리보기를 띄우고 fuzzy 로 좁힌다
--   action  : 고른 항목에 할 일. 열기 / 분할로 열기 / 탭으로 열기 / 여러 개를 quickfix 로
-- 순정 대응: :find, :grep + :copen, :ls + :b, :h, :map, grr, gO. 피커는 이 목록들로
-- 들어가는 입구이고, 결과를 쌓아 돌아다니는 건 여전히 quickfix 다.
if vim.g.vscode then
  return {}
end

return {
  -- ------------------------------------------------------------------
  -- fzf-lua: nvim 이 플로팅 창 안에 터미널 버퍼를 열어 외부 fzf 프로세스를 띄우고,
  -- 후보를 표준 입력으로 넣은 뒤 선택 결과를 표준 출력으로 받는다 (Unix 파이프 모델).
  -- 매칭과 정렬은 전부 fzf 바이너리가 한다. fzf 는 brew 로 설치돼 있다 (packages.yaml).
  -- ------------------------------------------------------------------
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = "FzfLua", -- :FzfLua <picker> 로도 쓸 수 있다. 키맵의 require 시점에도 로드된다.
    opts = {
      keymap = {
        fzf = {
          true, -- 기본 fzf 키 바인딩을 상속한 뒤 아래만 덮어쓴다
          -- 전체 결과를 quickfix 로. snacks 의 <C-q> 와 맞춘다 (기본은 alt-q = 선택한 것만).
          ["ctrl-q"] = "select-all+accept",
        },
      },
    },
  },

  -- ------------------------------------------------------------------
  -- snacks.nvim: 모듈 묶음. 여기서는 picker 만 켠다. 나머지 모듈은 명시하지 않으면 꺼져 있다.
  -- 순수 Lua 매처. priority/lazy=false 는 snacks 가 권장하는 로드 방식이다.
  -- ------------------------------------------------------------------
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      picker = {
        enabled = true,
        -- 기본값 true 는 vim.ui.select (gra 코드 액션 메뉴 등 순정 선택 UI) 를 snacks 로
        -- 바꿔 버린다. 비교 기간에는 순정 UI 를 그대로 두고, 결정 뒤 켤지 정한다.
        ui_select = false,
      },
    },
  },
}
