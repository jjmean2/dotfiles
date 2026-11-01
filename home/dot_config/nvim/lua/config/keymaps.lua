-- ==================================================
-- ⌨️  키맵 (모든 사용자 키맵은 이 파일에 모은다)
-- ==================================================
--
-- 원칙
--   1. 순정 기본 키는 지우거나 다른 뜻으로 바꾸지 않는다. 순정 nvim 에서도 손이
--      그대로 움직여야 한다.  :help default-mappings, :help lsp-defaults
--   2. 추가하는 키는 모두 <leader>(스페이스) 아래 네임스페이스에 둔다.
--   3. 모든 키맵에 desc 를 단다. :map 출력과 (나중에 넣을) which-key 메뉴가
--      그대로 문서가 된다.
--   4. 플러그인 키맵도 여기 둔다. lazy.nvim 은 require("플러그인모듈") 시점에
--      해당 플러그인을 로드하므로, 함수 안에서 require 하면 지연 로드가 유지된다.
--
-- 네임스페이스 (예약 포함)
--   <leader>e / E   탐색기 (explorer)
--   <leader>c       코드 (code): 포맷 등. LSP 동작은 순정 gr* 키를 쓴다.
--   <leader>f       찾기 (find): 1단계 비교 기간에는 fzf-lua
--   <leader>p       피커 비교용 임시 (picker): snacks.picker. 결정 뒤 삭제 예정
--   <leader>g       git: 2단계 예정
--   <leader>t       토글 (toggle): 예정
--
-- 어떤 키가 어디서 정의됐는지 볼 때:  :verbose map <키>
--
-- 순정에서 이미 되는 것 (추가하지 않는다)
--   LSP   : K 호버, grn 이름변경, grr 참조, gri 구현, grt 타입정의, gra 코드액션,
--           gO 문서심볼, CTRL-] 정의로 이동(tagfunc) / CTRL-T 되돌아오기,
--           CTRL-X CTRL-O 완성(omnifunc), gq 포맷(formatexpr), i_CTRL-S 시그니처
--   진단  : ]d [d 이동, CTRL-W d 현재 줄 진단 플로팅
--   목록  : ]q [q quickfix, ]l [l location list, ]b [b 버퍼, ]a [a arglist
--   기타  : gcc / gc 주석 토글, 비주얼 * # 선택 영역 검색, CTRL-L 하이라이트 해제

local map = vim.keymap.set

-- --------------------------------------------------
-- 순정 보강: 화면 줄 단위 이동
-- --------------------------------------------------
-- 긴 줄이 wrap 됐을 때 j/k 가 논리 줄이 아니라 화면 줄로 움직이게 한다.
-- 기본 키의 뜻을 바꾸는 유일한 예외로, 숫자 접두사(5j)를 붙이면 논리 줄로 움직여
-- 순정과 같아진다.
if vim.g.vscode then
  -- VS Code 쪽이 gj/gk 를 자체 매핑하고 있어 remap = true 가 필요하다.
  map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, remap = true, desc = "화면 줄 위로" })
  map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, remap = true, desc = "화면 줄 아래로" })
else
  map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true, desc = "화면 줄 위로" })
  map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true, desc = "화면 줄 아래로" })
end

-- VS Code 안(vscode-neovim)에서는 아래 플러그인 키맵이 의미가 없다.
if vim.g.vscode then
  return
end

-- --------------------------------------------------
-- <leader>e  탐색기 (nvim-tree)
-- --------------------------------------------------
-- 순정 대응: :Explore (netrw), :find 파일명
map("n", "<leader>e", "<Cmd>NvimTreeToggle<CR>", { desc = "탐색기 토글" })
map("n", "<leader>E", "<Cmd>NvimTreeFindFile<CR>", { desc = "탐색기에서 현재 파일 위치" })

-- --------------------------------------------------
-- <leader>c  코드
-- --------------------------------------------------
-- 포맷. 순정 대응: gq (LSP formatexpr) 또는 :lua vim.lsp.buf.format()
-- conform 은 formatters_by_ft 에 포맷터가 있으면 그것을, 없으면 LSP 포맷으로 fallback.
map({ "n", "v" }, "<leader>cf", function()
  require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "포맷 (버퍼 또는 선택 영역)" })

-- --------------------------------------------------
-- 피커 (1단계 비교: <leader>f = fzf-lua, <leader>p = snacks.picker)
-- --------------------------------------------------
-- 두 네임스페이스의 둘째 글자는 같은 뜻이다. 결정 뒤 이긴 쪽이 <leader>f 를 가져간다.
--
--   둘째 글자 | 하는 일                    | 순정 대응
--   f         | 프로젝트 파일 (Cmd+P)       | :find **/이름
--   g         | 파일 내용 live grep         | :grep 패턴 → :copen
--   b         | 열린 버퍼                   | :ls → :b 번호
--   .         | 최근 연 파일                | :oldfiles → :e #<번호
--   r         | LSP 참조 (커서 심볼)        | grr
--   s         | 현재 파일 심볼 (Cmd+P @)    | gO
--   d         | 현재 파일 진단 (Problems)   | ]d, :lua vim.diagnostic.setloclist()
--   c         | 명령어 (Cmd+Shift+P)        | :  + Tab
--   h         | 도움말 태그                 | :h 이름
--   k         | 키맵 목록                   | :map
--   R         | 마지막 피커 다시 열기       | (없음)
--
-- 피커 안에서 (둘 다 거의 같다)
--   이동 Ctrl-j/k 또는 방향키 · Tab 여러 개 선택 · Enter 열기
--   Ctrl-v 세로 분할 · Ctrl-s 가로 분할 · Ctrl-t 탭 · Ctrl-q 전체를 quickfix 로
--   fzf-lua : alt-q 선택한 것만 quickfix, F4 미리보기 토글, Esc 닫기
--   snacks  : Esc 는 노멀 모드(j/k 로 이동, q 닫기), ? 도움말, alt-p 미리보기 토글

local fzf = function(fn, opts)
  return function() require("fzf-lua")[fn](opts) end
end
map("n", "<leader>ff", fzf("files"), { desc = "[fzf] 파일" })
map("n", "<leader>fg", fzf("live_grep"), { desc = "[fzf] live grep" })
map("n", "<leader>fb", fzf("buffers"), { desc = "[fzf] 버퍼" })
map("n", "<leader>f.", fzf("oldfiles"), { desc = "[fzf] 최근 파일" })
map("n", "<leader>fr", fzf("lsp_references"), { desc = "[fzf] LSP 참조" })
map("n", "<leader>fs", fzf("lsp_document_symbols"), { desc = "[fzf] 문서 심볼" })
map("n", "<leader>fd", fzf("diagnostics_document"), { desc = "[fzf] 진단 (현재 파일)" })
map("n", "<leader>fc", fzf("commands"), { desc = "[fzf] 명령어" })
map("n", "<leader>fh", fzf("helptags"), { desc = "[fzf] 도움말" })
map("n", "<leader>fk", fzf("keymaps"), { desc = "[fzf] 키맵" })
map("n", "<leader>fR", fzf("resume"), { desc = "[fzf] 마지막 피커 다시" })

local snacks = function(fn, opts)
  return function() Snacks.picker[fn](opts) end
end
map("n", "<leader>pf", snacks("files"), { desc = "[snacks] 파일" })
map("n", "<leader>pg", snacks("grep"), { desc = "[snacks] live grep" })
map("n", "<leader>pb", snacks("buffers"), { desc = "[snacks] 버퍼" })
map("n", "<leader>p.", snacks("recent"), { desc = "[snacks] 최근 파일" })
map("n", "<leader>pr", snacks("lsp_references"), { desc = "[snacks] LSP 참조" })
map("n", "<leader>ps", snacks("lsp_symbols"), { desc = "[snacks] 문서 심볼" })
map("n", "<leader>pd", snacks("diagnostics_buffer"), { desc = "[snacks] 진단 (현재 파일)" })
map("n", "<leader>pc", snacks("commands"), { desc = "[snacks] 명령어" })
map("n", "<leader>ph", snacks("help"), { desc = "[snacks] 도움말" })
map("n", "<leader>pk", snacks("keymaps"), { desc = "[snacks] 키맵" })
map("n", "<leader>pR", snacks("resume"), { desc = "[snacks] 마지막 피커 다시" })
