if vim.g.vscode then
    return {}
end

-- 파일 위치에서 위로 올라가며 rels(디렉터리 기준 상대 경로) 중 하나라도 있으면 true.
-- vim.fs.find 는 이름에 '/' 를 받지 않아 node_modules/.bin/x 같은 경로를 직접 확인한다.
local function found_upward(ctx, rels)
    for dir in vim.fs.parents(ctx.filename) do
        for _, rel in ipairs(rels) do
            if vim.uv.fs_stat(vim.fs.joinpath(dir, rel)) then
                return true
            end
        end
    end
    return false
end

-- 프로젝트가 oxfmt 를 쓴다는 신호: oxfmt 설정 파일 또는 로컬에 설치된 oxfmt.
-- conform 의 oxfmt 정의는 vite.config.* 도 루트 표시로 보지만, 그것만으로는 oxfmt 를 쓴다고 할 수
-- 없어(대부분의 vite 프로젝트는 prettier) 여기서는 뺀다.
local oxfmt_signals = { ".oxfmtrc.json", ".oxfmtrc.jsonc", "oxfmt.config.ts", "node_modules/.bin/oxfmt" }

-- 프로젝트가 prettier 를 쓴다는 신호: prettier 설정 파일 또는 로컬에 설치된 prettier.
local prettier_signals = {
    ".prettierrc", ".prettierrc.json", ".prettierrc.json5", ".prettierrc.yaml", ".prettierrc.yml",
    ".prettierrc.toml", ".prettierrc.js", ".prettierrc.cjs", ".prettierrc.mjs",
    ".prettierrc.ts", ".prettierrc.cts", ".prettierrc.mts",
    "prettier.config.js", "prettier.config.cjs", "prettier.config.mjs",
    "prettier.config.ts", "prettier.config.cts", "prettier.config.mts",
    "node_modules/.bin/prettier",
}

-- 포맷터 선택 규칙 ("어떤 도구를 쓸지는 프로젝트가 정한다")
--   코드(js/ts/css/html…): oxfmt 신호가 있으면 oxfmt, 아니면 prettier.
--     프로젝트 밖 파일도 전역 prettier(Mason)로 포맷한다.
--   데이터·문서(json/yaml/markdown): 프로젝트가 oxfmt 나 prettier 를 쓸 때만 그것으로 포맷하고,
--     아니면 포맷터 없음 → lsp_format = "fallback" 으로 jsonls/yamlls 포맷 (예전과 같은 동작).
--     dotfiles 같은 저장소의 README, 설정 파일이 저장할 때마다 prettier 스타일로 바뀌지 않게.
-- oxfmt 와 prettier 는 기본값이 다르다 (printWidth 100 vs 80). 신호 없이 고르면 파일 전체가
-- 다시 포맷되므로 반드시 프로젝트의 신호로 고른다.
local code = { "oxfmt", "prettier", stop_after_first = true }
local data = { "oxfmt", "prettier_project", stop_after_first = true }

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
            -- 한다 (lua/plugins/lsp.lua 의 tools). prettier, oxfmt 는 프로젝트의 node_modules/.bin 이
            -- 있으면 그것을 우선한다. :ConformInfo 로 어떤 포맷터가 골라졌는지 확인.
            formatters_by_ft = {
                lua = { "stylua" },
                javascript = code,
                javascriptreact = code,
                typescript = code,
                typescriptreact = code,
                vue = code,
                css = code,
                scss = code,
                less = code,
                html = code,
                graphql = code,
                json = data,
                jsonc = data,
                yaml = data,
                markdown = data,
            },
            formatters = {
                -- 기본 정의에 condition 만 덧붙인다 (inherit 기본값 true).
                oxfmt = {
                    condition = function(_, ctx)
                        return found_upward(ctx, oxfmt_signals)
                    end,
                },
                -- prettier 와 같고, 프로젝트가 prettier 를 쓸 때만 동작하는 변형.
                prettier_project = {
                    inherit = "prettier",
                    condition = function(_, ctx)
                        return found_upward(ctx, prettier_signals)
                    end,
                },
            },
            -- 프로젝트 밖 markdown 처럼 일부러 포맷하지 않는 경우에 "Formatters unavailable" 경고를
            -- 띄우지 않는다. 포맷터를 못 찾은 이유는 :ConformInfo 와 그 로그에서 본다.
            notify_no_formatters = false,
            -- 저장 시 자동 포맷팅 설정
            format_on_save = {
                -- prettier 는 node 기동 비용이 있어 500ms 는 큰 파일에서 빠듯하다.
                timeout_ms = 1000,
                lsp_format = "fallback", -- 포맷터가 없으면 LSP 내장 포맷 기능 사용
            },
        },
    },
}
