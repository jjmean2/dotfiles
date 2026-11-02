-- ==================================================
-- ✨ 플러그인 로딩 후 options
-- ==================================================
-- 키맵은 여기 두지 않는다. lua/config/keymaps.lua 참고.

-- colorscheme 은 플러그인으로 설치되므로 플러그인 초기화 뒤에 적용해야 한다.
-- vim.cmd.colorscheme("jellybeans-nvim")
vim.cmd.colorscheme("tokyonight")

-- 진단 표시: 줄 끝 가상 텍스트 + 사인 컬럼 아이콘
vim.diagnostic.config {
  virtual_text = true,
  signs = true,
  severity_sort = true, -- 같은 줄에 여럿이면 에러가 경고보다 앞에
}
