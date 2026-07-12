-- ==================================================
-- 🛠️ 에디터 options & keymaps
-- ==================================================

-- 파일 검색 및 탭 완성 (Built-in Fuzzy Search)
-- Search down into subfolders
-- Provides tab-completion for all file-related tasks
vim.opt.path:append('**')
-- Display all matching files when we tab complete
vim.opt.wildmenu = true
-- NOW WE CAN
-- - Hit tab to :find by partial match
-- - Use * to make it fuzzy

-- 텍스트 편집 및 들여쓰기 규칙
vim.opt.backspace:append({ "indent", "eol", "start" })
-- vim.opt.autoindent = true
-- vim.opt.cindent = true
vim.opt.smartindent = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

-- UI 및 시각적 피드백
vim.opt.number = true
vim.opt.showmatch = true
vim.opt.matchtime = 2
vim.opt.visualbell = true
vim.opt.laststatus = 2
vim.opt.ruler = true
vim.opt.rulerformat = '%15(%c%V %p%%%)'

-- 검색 행동 양식
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.ignorecase = true

-- 인코딩 및 다국어 지원
vim.opt.fileencodings:remove("latin1")
-- vim.opt.fileencodings:append({"korea", "latin1"})
vim.opt.fileencodings:append({ "cp949", "latin1" })

-- ==================================================
-- 🛠️ 에디터 환경별 options & keymaps
-- ==================================================

-- VS Code와 일반 터미널 환경에 따른 네이티브 설정 분기
if vim.g.vscode then
  -- [VS Code] 전용 설정

  -- 숫자 없이 j, k 입력 시 gj, gk로 작동, vs code에서는 gj가 커스텀 키매핑으로 지정되어 있으므로 remap = true 지정 필요
  vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, remap = true })
  vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, remap = true })
else
  -- [일반 터미널] 전용 설정


  vim.opt.listchars = {
    tab = '▸ ',
    lead = '·',
    trail = '·',
    extends = '»',
    precedes = '«',
    nbsp = '␣',
    eol = '↲'
  }
  vim.opt.list = true

  vim.keymap.set('n', 'k', 'gk')
  vim.keymap.set('n', 'j', 'gj')
end
