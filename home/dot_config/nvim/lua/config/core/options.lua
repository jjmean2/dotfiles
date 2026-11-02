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
-- 줄:열 표시는 statusline 이 맡는다 (core/statusline.lua). ruler 는 statusline 이 비었을 때만 쓰인다.

-- 플로팅 창 테두리 (0.11+). hover(K), signature, 진단 팝업, gitsigns blame 처럼 자기
-- 테두리를 지정하지 않는 플로팅 창이 모두 이 값을 따른다. 기본값 "" 는 테두리 없음이고,
-- tokyonight 의 float 배경은 본문과 명도 차가 작아서 어디까지 팝업인지 보이지 않았다.
-- 다른 모양과 비교하려면 :set winborder=single 처럼 바로 바꿔 볼 수 있다.
-- 자기 틀을 직접 그리는 플러그인에서 테두리가 이중으로 보이면 그쪽 옵션에서 border = "none".
vim.opt.winborder = "rounded"

-- 자동완성 (nvim 0.12 순정, 플러그인 없음). :h ins-autocompletion
-- 타이핑하면 'complete' 에 적힌 소스에서 후보를 모아 팝업 메뉴를 띄운다. 소스 순서가 우선순위다.
--   o    omnifunc. LSP 가 붙으면 omnifunc 가 vim.lsp.omnifunc 로 설정되므로 이게 곧 LSP 완성
--   .^5  현재 버퍼의 단어 (최대 5개)      w^5  다른 창의 버퍼      b^5  열린 버퍼들
-- 메뉴 조작은 순정 키 그대로: Ctrl-N / Ctrl-P 이동, Ctrl-Y 확정, Ctrl-E 닫기.
-- noselect 라 항목이 미리 선택되지 않아 Enter 는 평소처럼 줄바꿈이고, 원하면 Ctrl-Y 로 고른다.
-- Ctrl-X Ctrl-O 같은 수동 완성은 그대로 쓸 수 있다 (Ctrl-X 를 누르면 자동완성이 잠시 멈춘다).
vim.o.autocomplete = true
vim.opt.complete = { "o", ".^5", "w^5", "b^5" }
vim.opt.completeopt = { "menu", "menuone", "noselect", "popup", "fuzzy" }
-- 글자마다 메뉴가 깜빡이지 않도록 타이핑 속도보다 약간 긴 지연 (ms)
vim.o.autocompletedelay = 100

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
