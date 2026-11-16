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

-- --------------------------------------------------
-- <C-M-/>  cwd 기준 플로팅 터미널 토글
-- --------------------------------------------------
-- LazyVim 의 <C-/> 는 Root Dir(LazyVim.root()) 기준 터미널이다. 같은 꼴로 수식키 하나를 더한 키에 cwd 기준
-- 터미널을 둔다. Ctrl+Alt+/ 는 LazyVim·설치된 플러그인·tmux·Ghostty 어디에도 묶여 있지 않다(2026-11-16 확인).
-- Snacks.terminal.focus 는 그 터미널이 이미 포커스돼 있으면 숨기므로, n·t 두 모드에 걸면 같은 키로 열고 닫는다.
-- 터미널은 cmd·cwd·env·count 로 구분되므로 cwd 와 root 가 같으면 <C-/> 와 같은 터미널이 열린다.
-- <C-M-_> 는 확장 키(Kitty protocol / tmux extended-keys csi-u)가 안 통하는 경로에서 Ctrl+/ 가 <C-_> 로
-- 오는 것과 같은 이유로 함께 건다 (LazyVim 이 <c-/> 와 <c-_> 를 같이 거는 것과 같은 방식).
local function terminal_cwd()
  Snacks.terminal.focus(nil, { cwd = vim.fn.getcwd() })
end
vim.keymap.set({ "n", "t" }, "<C-M-/>", terminal_cwd, { desc = "Terminal (cwd)" })
vim.keymap.set({ "n", "t" }, "<C-M-_>", terminal_cwd, { desc = "which_key_ignore" })
