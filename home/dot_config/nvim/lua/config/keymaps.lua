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
--   <leader>g       git 목록·도구 (snacks 피커, lazygit). hunk 조작은 <leader>gh 아래 (LazyVim 배치)
--   <leader>m       마크다운 (markdown): 버퍼 렌더 토글, 브라우저 프리뷰 (HTML 도)
--   <leader>t       토글 (toggle)
--   <leader>y       경로 복사 (yank path): 상대/절대/이름/경로:줄
--   <leader>?       개인 치트시트 (:h jw, doc/jw.txt)
--
-- 어떤 키가 어디서 정의됐는지 볼 때:  :verbose map <키>
--
-- 순정에서 이미 되는 것 (추가하지 않는다)
--   LSP   : K 호버, grn 이름변경, grr 참조, gri 구현, grt 타입정의, gra 코드액션,
--           gO 문서심볼, CTRL-] 정의로 이동(tagfunc) / CTRL-T 되돌아오기,
--           CTRL-X CTRL-O 완성(omnifunc), gq 포맷(formatexpr), i_CTRL-S 시그니처
--   완성  : 'autocomplete' 로 타이핑 중 자동 팝업. Ctrl-N/P 이동, Ctrl-Y 확정, Ctrl-E 닫기,
--           Tab 스니펫 다음 자리
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
--   <leader>fP   | 현재 파일의 프로젝트로 전환 | :cd %:h (git root 우선)
--   <leader>fR   | 마지막 피커 다시 열기       | (없음)
--
-- 피커 안에서
--   시작 포커스는 소스에 따라 다르다 (picker.lua 의 sources 참고):
--     입력창(insert)에서 시작: 파일(ff, <leader><leader>), grep, 도움말, 명령어, 키맵, 심볼
--     목록(노멀 모드)에서 시작: 버퍼, 최근, 프로젝트, 참조, 진단, git diff/status, resume
--   목록 창: j/k/gg/G 이동 · Enter 열기 · i 또는 / 로 입력창 이동 · q 닫기
--   입력창: 타이핑으로 좁히기 · Ctrl-j/k 이동 · Tab 여러 개 선택 · Esc 로 노멀 모드(j/k 가 목록 이동)
--   Ctrl-v 세로 분할 · Ctrl-s 가로 분할 · Ctrl-t 탭 · Ctrl-q 전체(또는 선택)를 quickfix 로
--   alt-p 미리보기 토글 · alt-h 숨김 파일 · alt-i .gitignore 무시 토글 · ? 키 도움말
--   alt-g 커서 항목 절대경로를 메시지 줄에 · alt-m 피커 최대화 (긴 경로가 잘릴 때)
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

-- 현재 파일의 프로젝트로 전환 (VS Code 의 "Open Folder" 를 파일 기준으로).
-- 파일을 여는 것만으로는 cwd 가 바뀌지 않으므로(:h jw-cwd), W 밖 파일을 보다가 그
-- 프로젝트에서 일하고 싶을 때 이 키로 명시적으로 옮긴다. 루트 = .git 이 있는 상위, 없으면
-- 파일 디렉토리. 트리가 열려 있으면 루트가 따라오고 그 파일을 펼쳐 보여준다.
map("n", "<leader>fP", function()
  local buf = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(buf)
  if vim.bo[buf].buftype ~= "" or file == "" then
    vim.notify("파일 버퍼가 아니다", vim.log.levels.WARN)
    return
  end
  local root = JwVim.project_root(file)
  vim.cmd("cd " .. vim.fn.fnameescape(root))
  vim.notify("cwd: " .. vim.fn.fnamemodify(root, ":~"))
  require("nvim-tree.api").tree.find_file({ buf = buf })
end, { desc = "현재 파일의 프로젝트로 전환 (cwd 변경)" })

-- --------------------------------------------------
-- <leader>g  git  (배치는 LazyVim 과 같다)
-- --------------------------------------------------
-- 세 층으로 나뉜다.
--   <leader>gh*  hunk 조작 (gitsigns): "커서가 있는 hunk 에 무엇을 한다". 기준은 index
--   <leader>g*   목록·도구: snacks 피커(diff, status)와 lazygit(로그, 파일 히스토리, 전체 UI)
--   prefix G     tmux 팝업 lazygit: nvim 밖(Claude 패널, 셸)에서 부를 때
-- hunk = 연속된 변경 묶음. gitsigns 는 버퍼와 index 를 비교한 hunk 목록을 들고 있다.
--
--   키             | 하는 일                            | 순정/CLI 대응
--   ]h  [h         | 다음/이전 hunk (diff 모드에서는 순정 ]c) | diff 모드의 ]c [c
--   ]H  [H         | 마지막/첫 hunk                     |
--   <leader>ghs    | hunk 스테이징 (비주얼: 선택 줄만)   | git add -p
--   <leader>ghr    | hunk 되돌리기 (비주얼: 선택 줄만)   | git checkout -p
--   <leader>ghu    | hunk 스테이징 취소                  | git reset -p
--   <leader>ghS    | 버퍼 전체 스테이징                  | git add %
--   <leader>ghR    | 버퍼 전체 되돌리기                  | git checkout %
--   <leader>ghp    | hunk 미리보기 (인라인)              | :!git diff %
--   <leader>ghP    | hunk 미리보기 (플로팅)              |
--   <leader>ghb    | 현재 줄 blame 자세히                | :!git blame -L n,n %
--   <leader>ghB    | 버퍼 전체 blame 창                  | :!git blame %
--   <leader>ghd    | index 와 diff (순정 diff 모드)      | :vnew | r !git show :./# | windo diffthis
--   <leader>ghD    | HEAD 와 diff                        | 위에서 :./# 대신 HEAD:./#
--   <leader>ghq    | 이 버퍼의 hunk 를 quickfix 로       |
--   <leader>ghQ    | 모든 버퍼의 hunk 를 quickfix 로     |
--   ih             | hunk 텍스트 객체 (vih, dih 등)       |
--   <leader>gd     | 저장소 전체 hunk 피커 (기준 HEAD). Tab 스테이징, Ctrl-r 되돌리기 |
--   <leader>gs     | git status 피커                     | git status
--   <leader>gl     | 커밋 로그 (lazygit)                 | git log
--   <leader>gf     | 현재 파일 히스토리 (lazygit)        | git log -- %
--   <leader>gg     | lazygit (nvim 안 플로팅 터미널)      |
--   <leader>gb     | 현재 줄 blame (ghb 와 같음, LazyVim 호환) |
--   <leader>tb     | 줄 끝 blame 토글                    |
--
-- 기준 차이: gitsigns(sign, ghd, gh*)는 index 기준이라 스테이징한 hunk 는 사라지고,
-- <leader>gd 피커는 HEAD 기준이라 남는다.
-- nvim 안 lazygit 에서 e 로 파일을 열면 이 nvim 의 새 탭에 열린다 (nvim-remote 프리셋).
-- diff 모드 안에서는 순정 키가 그대로다: ]c [c 이동, do 가져오기, dp 보내기, :diffoff! 종료.

local gs = function(fn, ...)
  local args = { ... }
  return function() require("gitsigns")[fn](unpack(args)) end
end

-- ]h / [h: 순정에 없는 키. diff 모드면 순정 ]c 로 넘기고, 아니면 hunk 이동.
map("n", "]h", function()
  if vim.wo.diff then vim.cmd.normal({ "]c", bang = true }) else require("gitsigns").nav_hunk("next") end
end, { desc = "다음 hunk" })
map("n", "[h", function()
  if vim.wo.diff then vim.cmd.normal({ "[c", bang = true }) else require("gitsigns").nav_hunk("prev") end
end, { desc = "이전 hunk" })
map("n", "]H", gs("nav_hunk", "last"), { desc = "마지막 hunk" })
map("n", "[H", gs("nav_hunk", "first"), { desc = "첫 hunk" })

map("n", "<leader>ghs", gs("stage_hunk"), { desc = "hunk 스테이징" })
map("n", "<leader>ghr", gs("reset_hunk"), { desc = "hunk 되돌리기" })
map("x", "<leader>ghs", function() require("gitsigns").stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, { desc = "선택 줄 스테이징" })
map("x", "<leader>ghr", function() require("gitsigns").reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, { desc = "선택 줄 되돌리기" })
map("n", "<leader>ghu", gs("undo_stage_hunk"), { desc = "hunk 스테이징 취소" })
map("n", "<leader>ghS", gs("stage_buffer"), { desc = "버퍼 전체 스테이징" })
map("n", "<leader>ghR", gs("reset_buffer"), { desc = "버퍼 전체 되돌리기" })
map("n", "<leader>ghp", gs("preview_hunk_inline"), { desc = "hunk 미리보기 (인라인)" })
map("n", "<leader>ghP", gs("preview_hunk"), { desc = "hunk 미리보기 (플로팅)" })
map("n", "<leader>ghb", function() require("gitsigns").blame_line({ full = true }) end, { desc = "현재 줄 blame" })
map("n", "<leader>ghB", gs("blame"), { desc = "버퍼 blame" })
map("n", "<leader>ghd", gs("diffthis"), { desc = "index 와 diff" })
map("n", "<leader>ghD", gs("diffthis", "~"), { desc = "HEAD 와 diff" })
map("n", "<leader>ghq", gs("setqflist"), { desc = "이 버퍼 hunk → quickfix" })
map("n", "<leader>ghQ", gs("setqflist", "all"), { desc = "모든 hunk → quickfix" })
map({ "o", "x" }, "ih", gs("select_hunk"), { desc = "hunk 텍스트 객체" })

map("n", "<leader>gd", function() Snacks.picker.git_diff() end, { desc = "git diff (hunks)" })
map("n", "<leader>gs", function() Snacks.picker.git_status() end, { desc = "git status" })
map("n", "<leader>gl", function() Snacks.lazygit.log() end, { desc = "git log (lazygit)" })
map("n", "<leader>gf", function() Snacks.lazygit.log_file() end, { desc = "현재 파일 히스토리 (lazygit)" })
map("n", "<leader>gg", function() Snacks.lazygit() end, { desc = "lazygit" })
map("n", "<leader>gb", function() require("gitsigns").blame_line({ full = true }) end, { desc = "현재 줄 blame" })

-- --------------------------------------------------
-- <leader>m  마크다운 (lua/plugins/markdown.lua)
-- --------------------------------------------------
--   키           | 하는 일                                  | 순정/CLI 대응
--   <leader>mr   | 버퍼 안 렌더링 토글 (render-markdown)     | :RenderMarkdown toggle
--   <leader>mp   | 현재 파일을 브라우저 프리뷰 (live-preview) | :LivePreview start
--   <leader>mP   | 브라우저 프리뷰 서버 끄기                 | :LivePreview close
-- render-markdown 은 markdown 버퍼를 열 때 로드되므로, mr 은 마크다운 버퍼에서만 의미가 있다.
-- 프리뷰할 다른 파일을 고르려면 :LivePreview pick.
-- mp/mP 는 마크다운 전용이 아니다. HTML(+CSS/JS), SVG, AsciiDoc 버퍼에서도 그대로 쓴다
-- (VS Code Live Preview 대응. 서버 루트 = cwd, HTML 은 저장할 때 갱신).
map("n", "<leader>mr", function() require("render-markdown").toggle() end, { desc = "마크다운 렌더 토글" })
map("n", "<leader>mp", "<Cmd>LivePreview start<CR>", { desc = "브라우저 프리뷰" })
map("n", "<leader>mP", "<Cmd>LivePreview close<CR>", { desc = "브라우저 프리뷰 끄기" })

-- --------------------------------------------------
-- <leader>y  경로 복사 (yank path)
-- --------------------------------------------------
-- VS Code 의 Copy Path / Copy Relative Path. 시스템 클립보드(+ 레지스터)에 넣는다.
-- 상대 경로의 기준은 cwd = 워크스페이스 루트다 (:h jw-cwd). cwd 밖 파일이면 %:. 이
-- 절대 경로를 돌려준다(순정 동작).
--
--   키            | 결과 예                       | 순정 대응
--   <leader>yp    | lua/config/keymaps.lua        | :let @+ = expand('%:.')
--   <leader>yP    | /Users/.../keymaps.lua        | :let @+ = expand('%:p')
--   <leader>yn    | keymaps.lua                   | :let @+ = expand('%:t')
--   <leader>yl    | lua/config/keymaps.lua:42     | (없음)
--   <leader>yL    | /Users/.../keymaps.lua:42     | (없음)
--   비주얼 yl/yL  | lua/config/keymaps.lua:42-50  | (없음)  한 줄만 고르면 :42
-- nvim-tree 안에서는 트리 기본 키 y(이름) Y(상대) gy(절대)를 쓴다.

-- mod: filename-modifiers (:h filename-modifiers). with_line: 줄 번호(비주얼이면 범위)를 붙인다.
local function yank_path(mod, with_line)
  return function()
    local buf = vim.api.nvim_get_current_buf()
    if vim.bo[buf].buftype ~= "" or vim.api.nvim_buf_get_name(buf) == "" then
      vim.notify("파일 버퍼가 아니다", vim.log.levels.WARN)
      return
    end
    local visual = vim.fn.mode():find("^[vV\22]") ~= nil -- v, V, Ctrl-V
    local s = vim.fn.expand(mod)
    if with_line then
      local a, b = vim.fn.line("."), vim.fn.line(".")
      if visual then a = vim.fn.line("v") end
      if a > b then a, b = b, a end
      s = s .. ":" .. a .. (a ~= b and ("-" .. b) or "")
    end
    vim.fn.setreg("+", s)
    if visual then
      vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "n", false)
    end
    vim.notify("복사: " .. s)
  end
end
map("n", "<leader>yp", yank_path("%:."), { desc = "상대 경로 복사 (워크스페이스 기준)" })
map("n", "<leader>yP", yank_path("%:p"), { desc = "절대 경로 복사" })
map("n", "<leader>yn", yank_path("%:t"), { desc = "파일 이름 복사" })
map({ "n", "x" }, "<leader>yl", yank_path("%:.", true), { desc = "상대 경로:줄 복사 (비주얼: 범위)" })
map({ "n", "x" }, "<leader>yL", yank_path("%:p", true), { desc = "절대 경로:줄 복사 (비주얼: 범위)" })

-- --------------------------------------------------
-- <leader>t  토글
-- --------------------------------------------------
map("n", "<leader>tb", gs("toggle_current_line_blame"), { desc = "줄 끝 blame 토글" })
-- inlay hint: 타입/매개변수 이름을 코드 사이에 가상 텍스트로 보여주는 LSP 기능. 시끄러워 꺼 두고 토글.
map("n", "<leader>th", function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, { desc = "inlay hint 토글" })

-- --------------------------------------------------
-- <leader>?  개인 치트시트
-- --------------------------------------------------
-- doc/jw.txt 를 순정 help 로 새 탭에 연다 (:h write-local-help). 닫기는 :q.
-- 전수 목록은 which-key(<leader> 누르고 멈춤)와 <leader>fk, 선별 목록은 여기.
map("n", "<leader>?", "<Cmd>tab help jw-learning<CR>", { desc = "치트시트 (:h jw)" })
