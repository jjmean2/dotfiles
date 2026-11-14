-- nvim-lite(플러그인 없음)와 nvim(LazyVim)이 함께 쓰는 옵션. 플러그인에 기대지 않는 것만 둔다.
-- nvim-lite 는 require("jw.options") 로, LazyVim 은 lua/config/options.lua 에서 dofile 로 읽는다.

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
    dot_bashrc = bash,
    dot_bash_profile = bash,
  },
})

-- 셸 스크립트는 탭으로 들여쓴다 (VS Code 의 [shellscript] 설정, shfmt 기본값과 맞춘다).
-- 전역으로는 expandtab 을 켜므로(LazyVim 기본값, nvim-lite 도 같게) 이 파일 형식들에서만 끈다.
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("shell_tabs", { clear = true }),
  pattern = { "sh", "bash", "zsh" },
  callback = function()
    vim.opt_local.expandtab = false
  end,
})
