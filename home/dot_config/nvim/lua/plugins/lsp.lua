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
            -- 이름은 nvim-lspconfig 의 설정 이름(lsp/<이름>.lua)이고, mason-lspconfig 가 mason 패키지로
            -- 바꿔 설치한다. 처음 nvim 을 띄울 때 네트워크로 받으며, 런타임은 mise 의 것을 쓴다
            -- (node: vtsls/bashls/jsonls/yamlls, go: gopls, python: basedpyright).
            -- 서버가 없는 파일 형식에서는 자동완성이 버퍼 단어만으로 돌아간다.
            local servers = {
                "lua_ls",        -- lua (nvim 설정)
                "vtsls",         -- typescript / javascript
                "bashls",        -- sh / bash / zsh (shellcheck 이 PATH 에 있으면 진단도)
                "jsonls",        -- json
                "yamlls",        -- yaml
                "taplo",         -- toml (mise, chezmoi 설정)
                "gopls",         -- go
                "basedpyright",  -- python
            }
            require("mason-lspconfig").setup({
                ensure_installed = servers,
                automatic_installation = true,
            })

            -- 3. [핵심] Neovim 내장 API로 서버 일괄 활성화
            -- nvim-lspconfig가 runtimepath에 제공하는 프리셋을 Neovim 코어가 직접 읽어서 켭니다.
            vim.lsp.enable(servers)

            -- 4. 서버가 붙을 때 한 번: 완성 항목 확정 시 부수효과 활성화.
            -- 자동완성 자체는 순정 'autocomplete' 옵션이 omnifunc 를 통해 띄운다 (core/options.lua).
            -- 여기서 completion.enable 을 호출해 두면 Ctrl-Y 로 항목을 고를 때 LSP 가 보낸
            -- 스니펫 확장, import 문 삽입, 추가 텍스트 편집이 적용된다. autotrigger 는 'autocomplete'
            -- 와 겹치므로 끈다 (기본값 false).
            vim.api.nvim_create_autocmd("LspAttach", {
                group = JwVim.augroup("LspCompletion"),
                callback = function(ev)
                    local client = vim.lsp.get_client_by_id(ev.data.client_id)
                    if client and client:supports_method("textDocument/completion") then
                        vim.lsp.completion.enable(true, client.id, ev.buf)
                    end
                end,
            })

            -- 5. 키맵은 따로 두지 않는다.
            -- nvim 0.11+ 은 LSP 가 붙으면 순정 기본 키와 옵션을 스스로 설정한다 (:help lsp-defaults).
            --   K 호버 / grn 이름변경 / grr 참조 / gri 구현 / grt 타입정의 / gra 코드액션 / gO 문서심볼
            --   CTRL-]  정의로 이동 (tagfunc 가 LSP 로 설정됨), CTRL-T 로 되돌아옴
            --   CTRL-X CTRL-O  LSP 완성 (omnifunc),  gq  LSP 포맷 (formatexpr),  i_CTRL-S  시그니처
            --   Tab  스니펫 안에서 다음 자리로 (vim.snippet 기본 매핑)
            -- 추가 키(inlay hint 토글 등)는 lua/config/keymaps.lua 에 둔다.
        end,
    },
}
