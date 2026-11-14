-- nvim-lite(플러그인 없음)와 nvim(LazyVim)이 함께 쓰는 키맵. 플러그인에 기대지 않는 것만 둔다.
-- nvim-lite 는 require("jw.keymaps") 로, LazyVim 은 lua/config/keymaps.lua 에서 dofile 로 읽는다.

-- --------------------------------------------------
-- <leader>y  경로 복사 (yank path)
-- --------------------------------------------------
-- VS Code 의 Copy Path / Copy Relative Path. 시스템 클립보드(+ 레지스터)에 넣는다.
-- Claude Code 에 "이 파일 42줄" 을 넘길 때 쓴다. LazyVim 은 <leader>y 를 쓰지 않는다.
--
--   키            | 결과 예                       | 순정 대응
--   <leader>yp    | lua/config/keymaps.lua        | :let @+ = expand('%:.')
--   <leader>yP    | /Users/.../keymaps.lua        | :let @+ = expand('%:p')
--   <leader>yn    | keymaps.lua                   | :let @+ = expand('%:t')
--   <leader>yl    | lua/config/keymaps.lua:42     | (없음)
--   <leader>yL    | /Users/.../keymaps.lua:42     | (없음)
--   비주얼 yl/yL  | lua/config/keymaps.lua:42-50  | (없음)  한 줄만 고르면 :42
--
-- 상대 경로의 기준은 cwd 다 (LazyVim 의 root 가 아니다). tmux 패널의 셸과 Claude Code 가 같은
-- cwd 에서 돌므로 그쪽에서 그대로 쓸 수 있다. cwd 밖 파일이면 %:. 이 절대 경로를 돌려준다(순정 동작).
-- LazyVim 의 탐색기(<leader>e) 안에서는 snacks 의 y 가 고른 파일의 절대 경로를 복사한다.

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
      if visual then
        a = vim.fn.line("v")
      end
      if a > b then
        a, b = b, a
      end
      s = s .. ":" .. a .. (a ~= b and ("-" .. b) or "")
    end
    vim.fn.setreg("+", s)
    if visual then
      vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "n", false)
    end
    vim.notify("복사: " .. s)
  end
end

local map = vim.keymap.set
map("n", "<leader>yp", yank_path("%:."), { desc = "Copy Relative Path" })
map("n", "<leader>yP", yank_path("%:p"), { desc = "Copy Absolute Path" })
map("n", "<leader>yn", yank_path("%:t"), { desc = "Copy File Name" })
map({ "n", "x" }, "<leader>yl", yank_path("%:.", true), { desc = "Copy Relative Path:Line" })
map({ "n", "x" }, "<leader>yL", yank_path("%:p", true), { desc = "Copy Absolute Path:Line" })
