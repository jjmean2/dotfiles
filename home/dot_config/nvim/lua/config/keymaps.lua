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
--   <leader>f       찾기 (find): snacks.picker
--   <leader><leader> 파일 찾기 별칭 (VS Code 의 Cmd+P 자리)
--   <leader>g       git (gitsigns). 저장소 단위 작업은 tmux prefix G 의 lazygit
--   <leader>t       토글 (toggle)
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
-- <leader>f  피커 (snacks.picker)
-- --------------------------------------------------
-- 둘째 글자가 source 다. 전역 키는 플러그인이 기본값을 주지 않으므로 여기서 붙인다
-- (LazyVim/AstroNvim 의 권장 매핑과 같은 체계).
--
--   키           | 하는 일                    | 순정 대응
--   <leader>ff   | 프로젝트 파일 (Cmd+P)       | :find **/이름
--   <leader><leader> | 위와 같음 (가장 자주 쓰는 것의 한 동작 별칭)
--   <leader>fg   | 파일 내용 live grep         | :grep 패턴 → :copen
--   <leader>fb   | 열린 버퍼                   | :ls → :b 번호
--   <leader>f.   | 최근 연 파일                | :oldfiles → :e #<번호
--   <leader>fr   | LSP 참조 (커서 심볼)        | grr
--   <leader>fs   | 현재 파일 심볼 (Cmd+P @)    | gO
--   <leader>fd   | 현재 파일 진단 (Problems)   | ]d, :lua vim.diagnostic.setloclist()
--   <leader>fc   | 명령어 (Cmd+Shift+P)        | :  + Tab
--   <leader>fh   | 도움말 태그                 | :h 이름
--   <leader>fk   | 키맵 목록                   | :map
--   <leader>fp   | 프로젝트 전환 (cwd 변경)    | :cd 경로
--   <leader>fR   | 마지막 피커 다시 열기       | (없음)
--
-- 피커 안에서
--   열리면 목록(노멀 모드)에 포커스: j/k/gg/G 이동 · Enter 열기 · i 또는 / 로 입력창 이동
--   입력창(insert 모드): 타이핑으로 좁히기 · Ctrl-j/k 이동 · Tab 여러 개 선택 · Esc 로 노멀 모드 · q 닫기
--   Ctrl-v 세로 분할 · Ctrl-s 가로 분할 · Ctrl-t 탭 · Ctrl-q 전체(또는 선택)를 quickfix 로
--   alt-p 미리보기 토글 · alt-h 숨김 파일 · alt-i .gitignore 무시 토글 · ? 키 도움말
-- 피커는 nvim 의 cwd 를 프로젝트 루트로 본다. :pwd 로 확인, :cd 로 변경.

local pick = function(fn, opts)
  return function() Snacks.picker[fn](opts) end
end
map("n", "<leader>ff", pick("files"), { desc = "파일" })
map("n", "<leader><leader>", pick("files"), { desc = "파일" })
map("n", "<leader>fg", pick("grep"), { desc = "live grep" })
map("n", "<leader>fb", pick("buffers"), { desc = "버퍼" })
map("n", "<leader>f.", pick("recent"), { desc = "최근 파일" })
map("n", "<leader>fr", pick("lsp_references"), { desc = "LSP 참조" })
map("n", "<leader>fs", pick("lsp_symbols"), { desc = "문서 심볼" })
map("n", "<leader>fd", pick("diagnostics_buffer"), { desc = "진단 (현재 파일)" })
map("n", "<leader>fc", pick("commands"), { desc = "명령어" })
map("n", "<leader>fh", pick("help"), { desc = "도움말" })
map("n", "<leader>fk", pick("keymaps"), { desc = "키맵" })
map("n", "<leader>fp", pick("projects"), { desc = "프로젝트 전환 (cwd 변경)" })
map("n", "<leader>fR", pick("resume"), { desc = "마지막 피커 다시" })

-- --------------------------------------------------
-- <leader>g  git (gitsigns)
-- --------------------------------------------------
-- hunk = 연속된 변경 묶음. gitsigns 는 버퍼와 index 를 비교해 hunk 목록을 들고 있고,
-- 아래 키는 전부 "커서가 있는 hunk" 또는 "이 버퍼의 hunk 전부" 에 대한 조작이다.
--
--   키           | 하는 일                          | 순정/CLI 대응
--   ]c  [c       | 다음/이전 hunk (diff 모드에서는 순정 ]c) | diff 모드의 ]c [c
--   <leader>gp   | hunk 미리보기 (플로팅)            | :!git diff %
--   <leader>gi   | hunk 미리보기 (인라인)            |
--   <leader>gs   | hunk 스테이징 (비주얼: 선택 줄만) | git add -p
--   <leader>gr   | hunk 되돌리기 (비주얼: 선택 줄만) | git checkout -p
--   <leader>gu   | hunk 스테이징 취소                | git reset -p
--   <leader>gS   | 버퍼 전체 스테이징                | git add %
--   <leader>gR   | 버퍼 전체 되돌리기                | git checkout %
--   <leader>gd   | index 와 diff (순정 diff 모드)    | :vnew | r !git show :./# | windo diffthis
--   <leader>gD   | HEAD 와 diff                      | 위에서 :./# 대신 HEAD:./#
--   <leader>gb   | 현재 줄 blame 자세히              | :!git blame -L <줄>,<줄> %
--   <leader>gq   | 이 버퍼의 hunk 를 quickfix 로     | (없음)
--   <leader>gQ   | 모든 버퍼의 hunk 를 quickfix 로   |
--   ih           | hunk 텍스트 객체 (vih, dih 등)     |
--   <leader>tb   | 줄 끝 blame 토글                  |
--
-- diff 모드 안에서는 순정 키가 그대로다: ]c [c 이동, do 가져오기, dp 보내기, :diffoff! 종료.
-- <leader>gd 로 열리는 창이 바로 그 diff 모드다.

local gs = function(fn, ...)
  local args = { ... }
  return function() require("gitsigns")[fn](unpack(args)) end
end

-- ]c / [c: 순정은 diff 모드에서만 뜻이 있고 그 밖에서는 아무 매핑이 없다.
-- diff 모드면 순정 그대로, 아니면 hunk 이동으로 "빈 자리를 채우는" 확장이다 (gitsigns 권장 방식).
map("n", "]c", function()
  if vim.wo.diff then vim.cmd.normal({ "]c", bang = true }) else require("gitsigns").nav_hunk("next") end
end, { desc = "다음 hunk / diff 변경" })
map("n", "[c", function()
  if vim.wo.diff then vim.cmd.normal({ "[c", bang = true }) else require("gitsigns").nav_hunk("prev") end
end, { desc = "이전 hunk / diff 변경" })

map("n", "<leader>gp", gs("preview_hunk"), { desc = "hunk 미리보기" })
map("n", "<leader>gi", gs("preview_hunk_inline"), { desc = "hunk 미리보기 (인라인)" })
map("n", "<leader>gs", gs("stage_hunk"), { desc = "hunk 스테이징" })
map("n", "<leader>gr", gs("reset_hunk"), { desc = "hunk 되돌리기" })
map("v", "<leader>gs", function() require("gitsigns").stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, { desc = "선택 줄 스테이징" })
map("v", "<leader>gr", function() require("gitsigns").reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, { desc = "선택 줄 되돌리기" })
map("n", "<leader>gu", gs("undo_stage_hunk"), { desc = "hunk 스테이징 취소" })
map("n", "<leader>gS", gs("stage_buffer"), { desc = "버퍼 전체 스테이징" })
map("n", "<leader>gR", gs("reset_buffer"), { desc = "버퍼 전체 되돌리기" })
map("n", "<leader>gd", gs("diffthis"), { desc = "index 와 diff" })
map("n", "<leader>gD", gs("diffthis", "~"), { desc = "HEAD 와 diff" })
map("n", "<leader>gb", function() require("gitsigns").blame_line({ full = true }) end, { desc = "현재 줄 blame" })
map("n", "<leader>gq", gs("setqflist"), { desc = "이 버퍼 hunk → quickfix" })
map("n", "<leader>gQ", gs("setqflist", "all"), { desc = "모든 hunk → quickfix" })
map({ "o", "x" }, "ih", gs("select_hunk"), { desc = "hunk 텍스트 객체" })

-- --------------------------------------------------
-- <leader>t  토글
-- --------------------------------------------------
map("n", "<leader>tb", gs("toggle_current_line_blame"), { desc = "줄 끝 blame 토글" })
