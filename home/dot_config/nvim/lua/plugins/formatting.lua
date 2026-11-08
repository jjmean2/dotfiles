-- 포맷터 선택: "어떤 포맷터를 쓸지는 프로젝트가 정한다" (이전 설정 PR #37 의 규칙).
--
-- LazyVim 의 formatting.prettier 와 lang.typescript.oxc extra 는 둘 다 같은 파일 형식(js/ts/json …)의
-- conform 목록에 자기 포맷터를 덧붙인다. conform 은 목록의 포맷터를 "전부" 차례로 돌리므로, 둘을
-- 같이 켜면 prettier 로 포맷한 뒤 oxfmt 로 다시 포맷한다. 두 포맷터는 기본값이 달라서
-- (printWidth 80 vs 100) 신호 없이 고르면 파일 전체가 다시 포맷된다. 그래서 각 포맷터에 조건을
-- 달아 한 프로젝트에서는 하나만 돌게 한다. 목록 자체는 extras 가 만든 그대로 둔다.
--
--   oxfmt   : 프로젝트에 oxfmt 신호가 있을 때만
--   prettier: oxfmt 신호가 없을 때. 단 데이터·문서(json/yaml/markdown)는 프로젝트가 prettier 를
--             쓸 때만 (dotfiles README 같은 파일이 저장할 때마다 prettier 스타일로 바뀌지 않게)
--   둘 다 아니면 conform 포맷터가 없으므로 LazyVim 기본값대로 LSP 포맷으로 넘어간다.
-- 어떤 포맷터가 골라졌는지는 :ConformInfo. 저장 시 자동 포맷 끄기/켜기는 <leader>uf (LazyVim).

-- 파일 위치에서 위로 올라가며 rels(디렉터리 기준 상대 경로) 중 하나라도 있으면 true.
-- vim.fs.find 는 이름에 '/' 를 받지 않아 node_modules/.bin/x 같은 경로를 직접 확인한다.
local function found_upward(filename, rels)
  for dir in vim.fs.parents(filename) do
    for _, rel in ipairs(rels) do
      if vim.uv.fs_stat(vim.fs.joinpath(dir, rel)) then
        return true
      end
    end
  end
  return false
end

-- conform 의 oxfmt 정의는 vite.config.* 도 루트 표시로 보지만, 그것만으로는 oxfmt 를 쓴다고 할 수
-- 없어(대부분의 vite 프로젝트는 prettier) 신호에서 뺀다.
local oxfmt_signals = { ".oxfmtrc.json", ".oxfmtrc.jsonc", "oxfmt.config.ts", "node_modules/.bin/oxfmt" }

local prettier_signals = {
  ".prettierrc", ".prettierrc.json", ".prettierrc.json5", ".prettierrc.yaml", ".prettierrc.yml",
  ".prettierrc.toml", ".prettierrc.js", ".prettierrc.cjs", ".prettierrc.mjs",
  ".prettierrc.ts", ".prettierrc.cts", ".prettierrc.mts",
  "prettier.config.js", "prettier.config.cjs", "prettier.config.mjs",
  "prettier.config.ts", "prettier.config.cts", "prettier.config.mts",
  "node_modules/.bin/prettier",
}

-- 프로젝트가 prettier 를 쓸 때만 포맷하는 파일 형식
local data_filetypes = { json = true, jsonc = true, yaml = true, markdown = true, ["markdown.mdx"] = true }

return {
  {
    "stevearc/conform.nvim",
    -- extras 의 opts 가 먼저 돌고(목록과 prettier 의 기본 condition 을 만든다) 이 함수가 그 위에 덧씌운다.
    opts = function(_, opts)
      opts.formatters = opts.formatters or {}

      opts.formatters.oxfmt = vim.tbl_extend("force", opts.formatters.oxfmt or {}, {
        condition = function(_, ctx)
          return found_upward(ctx.filename, oxfmt_signals)
        end,
      })

      local prettier = opts.formatters.prettier or {}
      local base = prettier.condition -- formatting.prettier extra 의 condition (파서 추론 가능 여부)
      prettier.condition = function(self, ctx)
        if found_upward(ctx.filename, oxfmt_signals) then
          return false
        end
        if data_filetypes[vim.bo[ctx.buf].filetype] and not found_upward(ctx.filename, prettier_signals) then
          return false
        end
        return base == nil or base(self, ctx)
      end
      opts.formatters.prettier = prettier
    end,
  },
}
