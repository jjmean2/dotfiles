-- 셸 스크립트 포맷: shfmt 가 다룰 수 있는 셸(sh/bash/mksh/bats/zsh)은 모두 shfmt 로 포맷한다.
--
-- nvim 의 파일 형식으로는 sh(bash·ksh·bats 포함)와 zsh 두 가지다. LazyVim 은 sh 에만 shfmt 를
-- 걸어 두므로 zsh 를 더한다. 들여쓰기는 conform 의 shfmt 정의가 정한다: expandtab 이 꺼져 있으면
-- (config/autocmds.lua 의 셸 탭 설정) -i 를 넘기지 않아 shfmt 기본값인 탭으로 포맷한다.
-- .editorconfig 가 있으면 인자 없이 돌려 그 설정을 따른다.
--
-- 방언(-ln): shfmt 의 auto 는 확장자와 shebang 만 본다. .zsh 나 zsh shebang 이 없는 zsh 파일
-- (chezmoi 소스 dot_zshrc, autoload 함수 파일)은 bash 로 읽어 ${(j:,:)x} 같은 zsh 문법에서
-- 실패한다. 그래서 nvim 이 zsh 로 판정했는데 shfmt 가 스스로 알아보지 못하는 버퍼에만 -ln zsh 를
-- 붙인다. -ln 같은 파서·프린터 플래그를 하나라도 주면 shfmt 는 EditorConfig 를 통째로 무시하므로
-- 꼭 필요할 때로 좁힌다.
--   - .zsh 확장자나 zsh shebang 이 있으면 shfmt 의 auto 에 맡긴다.
--   - .editorconfig 가 있으면 붙이지 않는다. 그런 파일은 .editorconfig 에 파일 이름으로 섹션을 두고
--     language_dialect = zsh 를 적는다 (예: [dot_zshrc]). shfmt 의 [[zsh]] 섹션은 확장자·shebang
--     으로 판정하므로 이런 파일에는 걸리지 않는다.
-- 어떤 포맷터가 골라졌는지는 :ConformInfo.

-- 남이 배포하는 셸 스크립트: 포맷하면 업데이트 diff 가 커지므로 건드리지 않는다.
local vendored = {
  "/shell/iterm2/iterm2_shell_integration%.", -- iTerm2 셸 통합 (iterm2.com 배포본 그대로)
}

local function is_vendored(filename)
  for _, pat in ipairs(vendored) do
    if filename:find(pat) then
      return true
    end
  end
  return false
end

-- shfmt 가 zsh 로 알아보는 shebang: ^#![ \t]*/(usr/)?bin/(env[ \t]+)?zsh(\s|$) (mvdan/sh fileutil).
-- #!/usr/local/bin/zsh 같은 건 shfmt 가 못 알아보므로 여기서도 false 여야 한다.
local function has_zsh_shebang(line)
  local rest = line:match("^#![ \t]*/(.*)$")
  if not rest then
    return false
  end
  rest = rest:gsub("^usr/", "", 1)
  rest = rest:match("^bin/(.*)$")
  if not rest then
    return false
  end
  rest = rest:gsub("^env[ \t]+", "", 1)
  return rest:match("^zsh%s") ~= nil or rest == "zsh"
end

return {
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.sh = opts.formatters_by_ft.sh or { "shfmt" }
      opts.formatters_by_ft.zsh = { "shfmt" }

      opts.formatters = opts.formatters or {}
      opts.formatters.shfmt = vim.tbl_extend("force", opts.formatters.shfmt or {}, {
        condition = function(_, ctx)
          return not is_vendored(ctx.filename)
        end,
        prepend_args = function(_, ctx)
          if vim.bo[ctx.buf].filetype ~= "zsh" then
            return {}
          end
          if ctx.filename:match("%.zsh$") then
            return {}
          end
          if has_zsh_shebang(vim.api.nvim_buf_get_lines(ctx.buf, 0, 1, false)[1] or "") then
            return {}
          end
          if vim.fs.find(".editorconfig", { path = ctx.dirname, upward = true })[1] then
            return {}
          end
          return { "-ln", "zsh" }
        end,
      })
    end,
  },
}
