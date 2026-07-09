require("config.lazy")
  
-- Search down into subfolders
-- Provides tab-completion for all file-related tasks
vim.opt.path:append('**')

-- Display all matching files when we tab complete
vim.opt.wildmenu = true

-- NOW WE CAN
-- - Hit tab to :find by partial match
-- - Use * to make it fuzzy

if not vim.g.vscode then
  -- vim.cmd.colorscheme("tokyonight")
  -- vim.cmd.colorscheme("jellybeans-nvim")
  vim.cmd.colorscheme("tokyonight")
end


vim.opt.backspace:append({ "indent", "eol", "start" })
vim.opt.number = true

-- vim.opt.autoindent = true
-- vim.opt.cindent = true
vim.opt.smartindent = true



vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2

vim.opt.expandtab = true

vim.opt.showmatch = true
vim.opt.matchtime = 2

vim.opt.hlsearch = true
vim.opt.incsearch = true

vim.opt.ignorecase = true

vim.opt.laststatus = 2

vim.opt.ruler = true
vim.opt.rulerformat = '%15(%c%V %p%%%)'

vim.opt.visualbell = true

vim.opt.fileencodings:remove("latin1")
-- vim.opt.fileencodings:append({"korea", "latin1"})
vim.opt.fileencodings:append({"cp949", "latin1"})

vim.g.mapleader = " "

-- nvim-tree
vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { silent = true })
vim.keymap.set('n', '<leader>f', ':NvimTreeFindFile<CR>', { silent = true })

-- 일단 vscode에서만 시범적으로 매핑
if vim.g.vscode then
  -- 숫자 없이 j, k 입력 시 gj, gk로 작동, vs code에서는 gj가 커스텀 키매핑으로 지정되어 있으므로 remap = true 지정 필요
  vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, remap = true })
  vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, remap = true })
else
  vim.keymap.set('n', 'k', 'gk')
  vim.keymap.set('n', 'j', 'gj')

  vim.opt.listchars = {
      tab = '▸ ',
      lead = '·',
      trail = '·',
      extends ='»',
      precedes = '«',
      nbsp = '␣',
      eol = '↲'
  }
  vim.opt.list = true
end

vim.diagnostic.config {
  virtual_text = true,
  signs = true
}

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


vim.lsp.enable('tsserver')

-- === OS 전용 설정과 로컬 오버라이드 로드 ===
-- init.darwin.lua / init.linux.lua (OS 에 맞는 것 하나) 와 init.local.lua 가 있으면 순서대로 불러온다.
local function source_if_exists(name)
  local path = vim.fn.stdpath("config") .. "/" .. name
  if vim.fn.filereadable(path) == 1 then
    dofile(path)
  end
end

local os_name = (vim.uv or vim.loop).os_uname().sysname
if os_name == "Darwin" then
  source_if_exists("init.darwin.lua")
elseif os_name == "Linux" then
  source_if_exists("init.linux.lua")
end

source_if_exists("init.local.lua")

