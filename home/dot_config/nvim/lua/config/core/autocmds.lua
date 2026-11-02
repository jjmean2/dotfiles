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
