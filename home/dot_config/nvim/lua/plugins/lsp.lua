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

            -- 4. 키맵은 따로 두지 않는다.
            -- nvim 0.11+ 은 LSP 가 붙으면 순정 기본 키와 옵션을 스스로 설정한다 (:help lsp-defaults).
            --   K 호버 / grn 이름변경 / grr 참조 / gri 구현 / grt 타입정의 / gra 코드액션 / gO 문서심볼
            --   CTRL-]  정의로 이동 (tagfunc 가 LSP 로 설정됨), CTRL-T 로 되돌아옴
            --   CTRL-X CTRL-O  LSP 완성 (omnifunc),  gq  LSP 포맷 (formatexpr),  i_CTRL-S  시그니처
            -- 추가 키가 필요해지면 lua/config/keymaps.lua 에 둔다.
        end,
    },
}
