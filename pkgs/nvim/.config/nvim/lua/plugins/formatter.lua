if vim.g.vscode then
    return {}
end

return {
    {
        "stevearc/conform.nvim",
        -- 파일 저장 직전에 실행되도록 트리거
        event = { "BufWritePre" },
        cmd = { "ConformInfo" },
        keys = {
            {
                "<leader>f",
                function()
                    require("conform").format({ async = true, lsp_format = "fallback" })
                end,
                mode = { "n", "v" }, -- 노멀 모드와 비주얼(블록 선택) 모드 모두 지원
                desc = "[F]ormat buffer or selection",
            },
        },
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
