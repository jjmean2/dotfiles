-- ~/.config/nvim/lua/plugins/treesitter.lua
if vim.g.vscode then
    return {}
end

return {
    {
        "nvim-treesitter/nvim-treesitter",
        lazy = false,
        -- 코드가 완전히 다운로드된 후 빌드(파서 컴파일) 프로세스 실행
        build = ":TSUpdate",
        config = function()
            local treesitter = require("nvim-treesitter")

            local languages = { "lua", "javascript", "typescript", "vim" }

            treesitter.install(languages)

            vim.api.nvim_create_autocmd("FileType", {
                group = JwVim.augroup("UserTreesitterConfig"),
                -- 문법 강조를 적용할 언어들을 나열 (컴퓨터에 파서가 설치되어 있어야 함)
                pattern = { "lua", 'javascript', 'typescript', 'typescriptreact', 'vim' },
                callback = function()
                    -- syntax highlight 활성화 (Neovim 코어 내장 함수)
                    vim.treesitter.start()

                    -- folds
                    vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
                    vim.wo[0][0].foldmethod = 'expr'

                    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
                end,
            })
        end,
    },
}
