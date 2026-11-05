if vim.g.vscode then
    return {}
end

return {
    {
        "stevearc/conform.nvim",
        -- 파일 저장 직전에 실행되도록 트리거
        event = { "BufWritePre" },
        cmd = { "ConformInfo" },
        -- 키맵(<leader>cf)은 lua/config/keymaps.lua 에 있다.
        -- lazy.nvim 은 require("conform") 시점에 이 플러그인을 로드하므로 keys 트리거가 없어도 된다.
        opts = {
            -- 언어별로 사용할 포맷터 지정. 실행 파일은 nvim 의 PATH 에서 찾으며, 전역 설치는 Mason 이
            -- 한다 (lua/plugins/lsp.lua 의 tools). prettier 는 프로젝트의 node_modules/.bin 이 있으면
            -- 그것을 우선한다. :ConformInfo 로 찾았는지 확인.
            formatters_by_ft = {
                lua = { "stylua" },
                javascript = { "prettier" },
                typescript = { "prettier" },
            },
            -- 저장 시 자동 포맷팅 설정
            format_on_save = {
                timeout_ms = 500,
                lsp_format = "fallback", -- 포맷터가 없으면 LSP 내장 포맷 기능 사용
            },
        },
    },
}
