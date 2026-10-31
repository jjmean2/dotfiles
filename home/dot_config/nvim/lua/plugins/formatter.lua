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
            -- 언어별로 사용할 포맷터 지정
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
