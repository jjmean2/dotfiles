-- ==================================================
-- 🛠️ 에디터 options
-- ==================================================
-- 키맵은 여기 두지 않는다. lua/config/keymaps.lua 참고.

-- 파일 찾기: :find 가 하위 디렉터리까지 뒤지게 한다 (:find **/foo<Tab>)
vim.opt.path:append('**')

-- 텍스트 편집 및 들여쓰기 규칙
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
vim.opt.rulerformat = '%15(%c%V %p%%%)'

-- 검색: 대소문자 무시 (smartcase 는 켜지 않음, 대문자를 섞어도 무시)
vim.opt.ignorecase = true

-- 인코딩: 한글 레거시 파일(cp949)을 latin1 보다 먼저 시도
vim.opt.fileencodings:remove("latin1")
vim.opt.fileencodings:append({ "cp949", "latin1" })

-- ==================================================
-- 🛠️ 환경별 options
-- ==================================================
-- VS Code 안(vscode-neovim)에서는 화면 표시 옵션이 의미가 없으므로 터미널에서만 적용
if not vim.g.vscode then
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
end
