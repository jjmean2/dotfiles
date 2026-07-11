-- ==================================================
-- ✨ 플러그인 options & keymaps
-- ==================================================

-- Nvim-Tree 단축키 지정 (플러그인 전용 UX)
vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { silent = true })
vim.keymap.set('n', '<leader>f', ':NvimTreeFindFile<CR>', { silent = true })

-- 내장 LSP 가동 및 진단 디자인
vim.diagnostic.config {
  virtual_text = true,
  signs = true
}

-- LSP가 특정 버퍼에 붙을 때(Attach) 동적으로 단축키를 주입하는 이벤트 리스너
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local opts = { buffer = args.buf }
    -- gd를 누르면 정의 이동 함수 호출
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    -- K를 누르면 호버(문서 팝업) 함수 호출
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    -- <leader>rn을 누르면 심볼 이름 변경
    vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
  end,
})

-- tsserver 활성화
vim.lsp.enable('tsserver')
