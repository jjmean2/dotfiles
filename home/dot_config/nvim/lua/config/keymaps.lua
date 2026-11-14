-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- 플러그인에 기대지 않는 키맵(<leader>y 경로 복사)은 nvim-lite 와 함께 쓴다.
-- 원본은 ~/.config/nvim-lite/lua/jw/keymaps.lua (options.lua 의 dofile 과 같은 방식).
dofile(vim.fs.joinpath(vim.fs.dirname(vim.fn.stdpath("config")), "nvim-lite", "lua", "jw", "keymaps.lua"))

-- which-key 메뉴의 그룹 이름 (<leader> 누르고 멈추면 보인다)
require("which-key").add({ { "<leader>y", group = "yank path", mode = { "n", "x" } } })

-- --------------------------------------------------
-- <leader>ub  줄 blame 토글 / <leader>uB  다크 배경 토글
-- --------------------------------------------------
-- LazyVim 은 <leader>ub 가 Dark Background 토글이다. 배경 토글은 거의 안 쓰므로 <leader>uB (LazyVim 코어·extras
-- 가 안 쓰는 키) 로 옮기고, <leader>ub 에는 gitsigns 의 current line blame 토글을 둔다 (기본 켜짐:
-- lua/plugins/git-blame.lua). 이 파일은 LazyVim 키맵 다음에 읽히므로 같은 키를 다시 매핑하면 덮어쓴다.
-- gitsigns 쪽 opts 함수에서 매핑하지 않는 이유: gitsigns 는 LazyFile 에 로드되어 VeryLazy 보다 먼저일 수
-- 있고, 그러면 LazyVim 의 <leader>ub 가 나중에 덮어쓴다.
Snacks.toggle.option("background", { off = "light", on = "dark", name = "Dark Background" }):map("<leader>uB")
Snacks.toggle({
  name = "Git Line Blame",
  get = function()
    return require("gitsigns.config").config.current_line_blame
  end,
  set = function(state)
    require("gitsigns").toggle_current_line_blame(state)
  end,
}):map("<leader>ub")
