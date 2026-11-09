-- 플로팅 창(K 호버 문서, <leader>cd 진단 메시지)에 테두리를 그려 본문과 구분되게 한다.
--
-- vscode.nvim 은 NormalFloat 배경을 본문보다 아주 조금만 밝게 칠해서, 테두리 없는 플로팅 창은
-- 경계가 거의 안 보인다. 배경색을 바꾸는 대신 테두리를 켠다 (LazyVim 이 안내하는 방식).
--
-- 두 창은 그리는 쪽이 달라서 따로 켠다.
--   K          LazyVim 기본 noice.nvim 이 vim.lsp.buf.hover 를 가로채 그린다. 그래서 Neovim 쪽
--              설정(vim.o.winborder 등)이 아니라 noice 의 lsp_doc_border 프리셋으로 켠다.
--              시그니처 도움말(insert 모드 <C-k>)에도 같이 적용된다.
--   <leader>cd vim.diagnostic.open_float. LazyVim 은 nvim-lspconfig 의 opts.diagnostics 를
--              vim.diagnostic.config 로 넘기므로 거기 float.border 를 준다.
--
-- vim.o.winborder = "rounded" (Neovim 0.11+) 로 한 번에 켜는 방법도 있지만, border 를 직접 정하지
-- 않는 모든 플러그인 창에 적용돼 이미 테두리를 그리는 플러그인과 겹칠 수 있어서 쓰지 않는다.
return {
  {
    "folke/noice.nvim",
    opts = {
      presets = { lsp_doc_border = true },
    },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        float = { border = "rounded" },
      },
    },
  },
}
