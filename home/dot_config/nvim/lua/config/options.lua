-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- 플러그인에 기대지 않는 옵션(한글 인코딩, 철자 검사, chezmoi 소스 파일 형식, 셸 탭)은 nvim-lite 와
-- 함께 쓴다. 원본은 ~/.config/nvim-lite/lua/jw/options.lua. 형제 디렉터리를 stdpath 로 찾으므로
-- XDG_CONFIG_HOME 을 바꿔도 따라간다. nvim-lite 는 모든 머신에 배포되는 필수 설정이다.
dofile(vim.fs.joinpath(vim.fs.dirname(vim.fn.stdpath("config")), "nvim-lite", "lua", "jw", "options.lua"))

-- LSP 색상 표시: 색상값 앞에 색상 박스를 붙인다 (VS Code Tailwind IntelliSense 처럼).
-- Neovim 0.12 부터 LSP documentColor 가 기본으로 켜져 있고, tailwindcss LSP 는 className 의
-- bg-red-500 같은 색상 클래스(테마에 정의한 색 포함)의 색을 알려준다. 기본 스타일 "background" 는
-- 글자 배경을 그 색으로 칠할 뿐이라 "virtual"(텍스트 앞에 Nerd Font 박스 글리프를 인라인으로)로 바꾼다.
-- style 은 버퍼별이 아닌 전역 설정이라 한 번만 부르면 되고, 이미 붙은 LSP 에도 바로 다시 적용된다.
--   다른 스타일: "foreground"(글자색), "● " 같은 문자열(그 문자를 박스 대신), "background"(기본값)
--   일시적으로 끄기/켜기: :lua vim.lsp.document_color.enable(not vim.lsp.document_color.is_enabled())
if vim.lsp.document_color then -- 0.11 이하에는 없는 API
  vim.lsp.document_color.enable(true, nil, { style = "virtual" })
end
