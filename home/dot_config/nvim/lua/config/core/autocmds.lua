-- ==================================================
-- 🛠️ 자동 명령 (플러그인과 무관한 순정 autocmd)
-- ==================================================

-- 개인 도움말(doc/*.txt, :h write-local-help)의 태그 색인을 유지한다.
-- 순정 help 는 doc/tags 색인이 있어야 :h jw 처럼 태그로 열 수 있는데, 플러그인 매니저는
-- 플러그인의 doc/ 만 색인하므로 설정 디렉토리의 doc/ 는 직접 돌려야 한다.
local doc = vim.fn.stdpath("config") .. "/doc"

local function helptags()
  vim.cmd("silent! helptags " .. vim.fn.fnameescape(doc))
end

-- 1) 그 파일을 저장할 때
vim.api.nvim_create_autocmd("BufWritePost", {
  group = JwVim.augroup("HelpTags"),
  pattern = doc .. "/*.txt",
  callback = helptags,
})

-- 2) 시작할 때 색인이 없거나(새 머신, chezmoi 가 txt 만 깔아 준 직후) txt 가 색인보다
--    새로우면(chezmoi apply 로 바뀐 경우) 한 번 다시 만든다.
local tags = vim.uv.fs_stat(doc .. "/tags")
if vim.uv.fs_stat(doc) then
  local stale = not tags
  if tags then
    for _, f in ipairs(vim.fn.glob(doc .. "/*.txt", false, true)) do
      local st = vim.uv.fs_stat(f)
      if st and st.mtime.sec > tags.mtime.sec then stale = true break end
    end
  end
  if stale then helptags() end
end

-- 피커 입력창(snacks_picker_input)에서는 순정 'autocomplete' 를 끈다.
-- 팝업 메뉴가 떠 있는 동안에는 TextChangedI 가 발생하지 않고 TextChangedP 가 대신 발생하는데
-- (:h TextChangedI), snacks 입력창은 TextChangedI 만 들어서 팝업이 뜬 순간부터 live grep 갱신이
-- 멈춘다. 'autocomplete' 는 global-local 이라 이 버퍼에서만 끌 수 있다 (core/options.lua 의
-- 전역 설정은 그대로). 검색어 입력창에 자동완성은 어차피 쓸모가 없다.
vim.api.nvim_create_autocmd("FileType", {
  group = JwVim.augroup("PickerNoAutocomplete"),
  pattern = "snacks_picker_input",
  callback = function(ev)
    vim.bo[ev.buf].autocomplete = false
  end,
})

-- --------------------------------------------------
-- 워크스페이스(W = 전역 cwd) 규칙. 전체 모델은 plugins/spec.lua 의 nvim-tree 주석, :h jw-cwd
-- --------------------------------------------------

--- path 가 속한 프로젝트 루트. .git 이 있는 가장 가까운 상위 디렉토리(worktree 포함),
--- 없으면 path 의 디렉토리.
---@param path string 파일 경로
---@return string
function JwVim.project_root(path)
  path = vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
  return vim.fs.root(path, ".git") or vim.fs.dirname(path)
end

--- 시작할 때 한 번만 W 를 정한다 (VS Code 에는 없는, 터미널 에디터만의 예외).
---   nvim / nvim .        → 셸 cwd 그대로
---   nvim dir             → nvim-tree 가 dir 로 :cd (hijack_directories)
---   nvim file (cwd 안)   → 셸 cwd 그대로. 셸에서 서 있던 곳이 의도다.
---   nvim file (cwd 밖)   → 그 파일의 프로젝트 루트로 :cd. 셸이 ~ 일 때
---                          `nvim ~/proj/a.ts` 로 피커가 홈 전체를 훑는 일을 막는다.
--- 시작 이후에는 파일을 연다고 W 가 바뀌지 않는다.
if not vim.g.vscode then
  vim.api.nvim_create_autocmd("VimEnter", {
    group = JwVim.augroup("StartupWorkspace"),
    once = true,
    callback = function()
      if vim.fn.argc() == 0 then return end
      local arg = vim.fn.argv(0) --[[@as string]]
      if arg:match("^%a[%w+.-]*://") then return end -- scp://, oil:// 같은 URL
      local file = vim.fs.normalize(vim.fn.fnamemodify(arg, ":p"))
      if vim.fn.isdirectory(file) == 1 then return end

      local real = function(p) return vim.uv.fs_realpath(p) or p end
      local cwd = real(vim.fn.getcwd(-1, -1))
      -- 새 파일이면 realpath 가 없으니 디렉토리 기준으로 판정한다.
      if vim.fs.relpath(cwd, real(vim.fs.dirname(file))) then return end

      local root = JwVim.project_root(file)
      if vim.fn.isdirectory(root) == 1 then
        vim.cmd("cd " .. vim.fn.fnameescape(root))
      end
    end,
  })
end
