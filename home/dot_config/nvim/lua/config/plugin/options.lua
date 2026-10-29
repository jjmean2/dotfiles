-- ==================================================
-- ✨ 플러그인 options & keymaps
-- ==================================================
-- colorscheme 설정 (colorscheme을 플러그인으로 설치하므로, 플러그인 초기화 후에 적용해야 함)
-- vim.cmd.colorscheme("jellybeans-nvim")
vim.cmd.colorscheme("tokyonight")

-- Nvim-Tree 단축키 지정 (플러그인 전용 UX)
vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { silent = true })
vim.keymap.set('n', '<leader>f', ':NvimTreeFindFile<CR>', { silent = true })

-- 내장 LSP 가동 및 진단 디자인
vim.diagnostic.config {
  virtual_text = true,
  signs = true
}
