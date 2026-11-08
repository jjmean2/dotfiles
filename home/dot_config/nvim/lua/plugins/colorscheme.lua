-- 컬러스킴: VS Code 기본 다크(Dark Modern 계열) 느낌의 vscode.nvim
-- 플러그인은 lazy.nvim 이 GitHub(Mofiqul/vscode.nvim) 에서 받는다.
-- 적용은 LazyVim 의 opts.colorscheme 이 맡는다 (시작할 때 :colorscheme vscode 실행).
-- 다른 테마를 미리 보려면 <leader>uC (저장 안 됨).
return {
  {
    "Mofiqul/vscode.nvim",
    lazy = false,
    priority = 1000,
    opts = { style = "dark" },
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "vscode" },
  },
}
