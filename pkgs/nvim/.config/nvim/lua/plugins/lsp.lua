-- ~/.config/nvim/lua/plugins/lsp.lua
-- VS Code에서는 Neovim 백엔드에서 활성화한 LSP 서버를 사용하지 않고, 자체 익스텐션을 통한 LSP 서버를 사용하므로, VS Code 환경에서는 이 파일을 로드하지 않는다.
if vim.g.vscode then
    return {}
end

return {
    -- 1. Neovim 설정용 'vim' 객체 타입 힌트 (최신 스펙)
    {
        "folke/lazydev.nvim",
        ft = "lua",
        opts = {
            library = {
                { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            },
        },
    },
    -- 2. 최신 내장 LSP + Mason 설정
    -- nvim-lspconfig 는 Neovim 내장 LSP를 위한 설정 프리셋을 제공
    -- $runtimepath/lsp/<language-server>.lua 파일들을 제공
    --
    -- mason.nvim은 외부 도구를 설치하고 관리하는 플러그인으로 ~/.local/share/nvim/mason/
    -- 경로에 설치하고 Neovim 내에서 사용하는 PATH를 설정해줌
    -- LSP 서버를 설치하는 데 사용
    --
    -- mason-lspconfig.nvim은 mason.nvim과 nvim-lspconfig를 연결해주는 플러그인으로,
    -- nvim-lspconfig의 preset config 이름과 LSP 서버 명령 이름을 매핑하고, 활성화한
    -- preset config에 해당하는 LSP 서버를 자동으로 설치하도록 함
    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "mason-org/mason.nvim",
            "mason-org/mason-lspconfig.nvim",
        },
        config = function()
            -- 1. Mason 초기화
            require("mason").setup()

            -- 2. Mason-Lspconfig 초기화 (원하는 서버 목록 자동 설치)
            local servers = { "lua_ls", "vtsls" }
            require("mason-lspconfig").setup({
                ensure_installed = servers,
                automatic_installation = true,
            })

            -- 3. [핵심] Neovim 내장 API로 서버 일괄 활성화
            -- nvim-lspconfig가 runtimepath에 제공하는 프리셋을 Neovim 코어가 직접 읽어서 켭니다.
            vim.lsp.enable(servers)

            -- 4. [핵심] 단축키 바인딩은 이제 전역 Autocmd (LspAttach)로 처리하는 것이 모범 사례입니다.
            vim.api.nvim_create_autocmd("LspAttach", {
                group = JwVim.augroup("UserLspConfig"),
                callback = function(ev)
                    local opts = { buffer = ev.buf, silent = true }

                    -- 내장 LSP 단축키 바인딩
                    -- gd를 누르면 정의 이동 함수 호출
                    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
                    -- K를 누르면 호버(문서 팝업) 함수 호출
                    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
                    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
                    -- <leader>rn을 누르면 심볼 이름 변경
                    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
                end,
            })
        end,
    },
}
