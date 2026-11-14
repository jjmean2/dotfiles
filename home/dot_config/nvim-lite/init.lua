-- 플러그인 없는 nvim. 서버·임시 머신처럼 플러그인을 내려받고 싶지 않은 곳에서 쓴다.
-- 실행: NVIM_APPNAME=nvim-lite nvim (셸의 nvim-lite alias). features.ide 를 끈 머신에서는
-- ~/.config/nvim 이 없어서 셸(shell/profile.sh)이 NVIM_APPNAME=nvim-lite 를 기본으로 정한다.
-- 설정·데이터도 ~/.config/nvim-lite, ~/.local/share/nvim-lite 처럼 이름별로 따로 쌓인다 (:h NVIM_APPNAME).
--
-- 손에 익은 LazyVim 기본값 중 플러그인 없이 되는 것만 흉내 낸다. 공유하는 설정은 lua/jw/ 에 있고
-- LazyVim 쪽(~/.config/nvim/lua/config/)도 같은 파일을 읽는다.

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- LazyVim 기본 옵션 중 플러그인과 상관없는 것 (lazyvim/config/options.lua)
local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.mouse = "a"
-- SSH 로 접속했을 때는 시스템 클립보드와 묶지 않는다 (LazyVim 과 같은 규칙). 원격에서의 "+ 복사는
-- nvim 이 터미널의 OSC 52 로 처리한다.
opt.clipboard = vim.env.SSH_CONNECTION and "" or "unnamedplus"
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.shiftround = true
opt.smartindent = true
opt.ignorecase = true
opt.smartcase = true
opt.splitright = true
opt.splitbelow = true
opt.scrolloff = 4
opt.undofile = true
opt.termguicolors = true
opt.confirm = true
opt.list = true
opt.wrap = false

-- 기본 내장 색상표 중 LazyVim 의 대체 색상표와 같은 것
vim.cmd.colorscheme("habamax")

require("jw.options")

-- LazyVim 기본 키맵 중 플러그인 없이 되는 것 (lazyvim/config/keymaps.lua)
local map = vim.keymap.set
map("n", "<C-h>", "<C-w>h", { desc = "Go to Left Window" })
map("n", "<C-j>", "<C-w>j", { desc = "Go to Lower Window" })
map("n", "<C-k>", "<C-w>k", { desc = "Go to Upper Window" })
map("n", "<C-l>", "<C-w>l", { desc = "Go to Right Window" })
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })
map({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and Clear hlsearch" })
map("n", "<leader>qq", "<cmd>qa<cr>", { desc = "Quit All" })
-- 탐색기: LazyVim 의 snacks explorer 대신 내장 netrw
map("n", "<leader>e", "<cmd>Explore<cr>", { desc = "Explorer (netrw)" })

require("jw.keymaps")
