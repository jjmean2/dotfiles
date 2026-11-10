-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- 셸 스크립트는 탭으로 들여쓴다 (VS Code 의 [shellscript] 설정, shfmt 기본값과 맞춘다).
-- LazyVim 은 전역으로 expandtab=true 를 켜므로 이 파일 형식들에서만 끈다.
-- 탭 너비와 들여쓰기 폭은 LazyVim 기본값(tabstop=2, shiftwidth=2)을 그대로 쓴다.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("shell_tabs", { clear = true }),
  pattern = { "sh", "bash", "zsh" },
  callback = function()
    vim.opt_local.expandtab = false
  end,
})
