-- 컬러스킴: VS Code 기본 다크(Dark Modern 계열) 느낌의 vscode.nvim
-- 플러그인은 lazy.nvim 이 GitHub(Mofiqul/vscode.nvim) 에서 받는다.
-- 적용은 LazyVim 의 opts.colorscheme 이 맡는다 (시작할 때 :colorscheme vscode 실행).
-- 다른 테마를 미리 보려면 <leader>uC (저장 안 됨).
--
-- 다크/라이트는 vscode.nvim 의 style 이 아니라 'background' 로 고른다.
-- style = "dark" 를 주면 vscode.load() 가 불릴 때마다 background 를 dark 로 되돌린다.
-- 그러면 <leader>uB 로 light 로 바꿀 때 Neovim 이 테마를 다시 읽다가 "테마가 background 를 되돌렸다" 고 보고
-- g:colors_name 을 지우고 기본 색으로 돌아간다 (Neovim 의 'background' 처리 동작).
-- style 을 비워 두면 vscode.nvim 이 지금 background 에 맞는 색(다크/라이트)을 고른다.
return {
  {
    "Mofiqul/vscode.nvim",
    lazy = false,
    priority = 1000,
    -- 시작은 다크로 고정한다. 직접 설정해 두면 Neovim 이 터미널 배경을 물어 background 를 바꾸지 않는다.
    init = function()
      vim.o.background = "dark"
    end,
    opts = {},
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "vscode" },
  },
}
