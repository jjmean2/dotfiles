-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- 인코딩: 한글 레거시 파일(cp949 / EUC-KR)을 latin1 보다 먼저 시도한다.
-- 'fileencodings' 는 파일을 읽을 때 앞에서부터 시도해 오류 없이 읽히는 첫 인코딩을 쓴다.
-- 기본값은 "ucs-bom,utf-8,default,latin1" 이라 UTF-8 이 아닌 한글 파일이 latin1 로 읽혀 깨져
-- 보인다. latin1 은 어떤 바이트열이든 읽히므로 맨 뒤에 두어야 한다. LazyVim 은 이 옵션을 건드리지 않는다.
-- 읽힌 인코딩은 :set fenc? 로 확인한다. 저장도 그 인코딩으로 하므로 원본 인코딩이 유지된다.
vim.opt.fileencodings:remove("latin1")
vim.opt.fileencodings:append({ "cp949", "latin1" })

-- 철자 검사: 한글(과 한자·가나)은 검사하지 않는다.
-- 'spelllang' 의 특수 값 "cjk" 는 동아시아 문자를 철자 검사 대상에서 빼고, 영어 단어 검사는 그대로 둔다.
-- 이게 없으면 LazyVim 이 markdown·gitcommit 등에서 켜는 spell 이 한글 단어마다 빨간 밑줄을 긋는다.
-- 일시적으로 한글도 검사하려면 :setlocal spelllang-=cjk
vim.opt.spelllang = { "en", "cjk" }

-- chezmoi 소스의 셸 설정 파일: 대상 이름(.zshrc 등)이 아니라 dot_ 접두사 이름이라 nvim 이 셸로
-- 알아보지 못한다(dot_zshrc 는 conf 로 잡힌다). 파일 형식을 직접 정해 하이라이트·포맷(shfmt)이
-- 붙게 한다. .vscode/settings.json 의 files.associations 와 같은 목록이다.
-- .tmpl 은 Go 템플릿 문법이 섞여 셸로 포맷하면 깨지므로 넣지 않는다.
local function bash(_, bufnr)
  return "sh", function(b)
    vim.b[b or bufnr].is_bash = 1
  end
end
vim.filetype.add({
  filename = {
    dot_zshrc = "zsh",
    dot_zshenv = "zsh",
    dot_zprofile = "zsh",
    source_zsh_variants = "zsh", -- zsh autoload 함수 (shebang 없음)
    dot_bashrc = bash,
    dot_bash_profile = bash,
  },
})

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
