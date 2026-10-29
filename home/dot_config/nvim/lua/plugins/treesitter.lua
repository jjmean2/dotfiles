-- ~/.config/nvim/lua/plugins/treesitter.lua
if vim.g.vscode then
    return {}
end

-- Neovim에서 treesitter 관련 API를 내장하면서, nvim-treesitter plugin의 기능이 많이 축소되었다.
-- 기존에는 syntax highlighting, indent 등을 직접 수행했지만, 현재는 Neovim 내장 API를 통해 수행하고,
-- nvim-treesitter는 필요한 treesitter를 설치하고 관리하는 역할을 주로 수행한다.
return {
    {
        "nvim-treesitter/nvim-treesitter",
        lazy = false,
        -- 코드가 완전히 다운로드된 후 빌드(파서 컴파일) 프로세스 실행
        build = ":TSUpdate",
        config = function()
            -- vim이 인식하는 filetype 이름 목록
            local filetypes = {
                "lua",
                "javascript",
                "typescript",
                "typescriptreact",
                "vim",
            }
            -- vim filetype 과 대응되는 treesitter parser 목록
            local parsers = vim.tbl_map(function(ft)
                return vim.treesitter.language.get_lang(ft) or ft
            end, filetypes)

            require("nvim-treesitter").install(parsers)

            vim.api.nvim_create_autocmd("FileType", {
                group = JwVim.augroup("UserTreesitterConfig"),
                -- 문법 강조를 적용할 언어들을 나열 (컴퓨터에 파서가 설치되어 있어야 함)
                pattern = filetypes,
                callback = function()
                    -- folds
                    vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
                    vim.wo[0][0].foldmethod = 'expr'
                    -- 시작시 폴드 레벨: 숫자가 작을수록 많이 접힘 (0이면 전부 접힘)
                    vim.wo[0][0].foldlevel = 99
                    -- 왼쪽 사이드바에 폴드 상태 표시
                    vim.wo[0].foldcolumn = '2'

                    -- indent
                    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

                    -- syntax highlight 활성화 (Neovim 코어 내장 함수)
                    -- syntax 옵션을 비우고, treesitter를 통해 문법 강조를 적용한다. (set syntax? 가 비어 있다.)
                    vim.treesitter.start()
                end,
            })
        end,
    },
}
