-- 셸 스크립트 포맷: shfmt 가 다룰 수 있는 셸(sh/bash/mksh/bats/zsh)은 모두 shfmt 로 포맷한다.
--
-- nvim 의 파일 형식으로는 sh(bash·ksh·bats 포함)와 zsh 두 가지다. LazyVim 은 sh 에만 shfmt 를
-- 걸어 두므로 zsh 를 더한다. 들여쓰기는 conform 의 shfmt 정의가 정한다: expandtab 이 꺼져 있으면
-- (config/autocmds.lua 의 셸 탭 설정) -i 를 넘기지 않아 shfmt 기본값인 탭으로 포맷한다.
-- .editorconfig 가 있으면 인자 없이 돌려 그 설정을 따른다.
--
-- 방언(-ln): shfmt 의 auto 는 확장자와 shebang 만 본다. .zsh 나 zsh shebang 이 없는 zsh 파일
-- (chezmoi 소스 dot_zshrc, autoload 함수 파일)은 bash 로 읽어 ${(j:,:)x} 같은 zsh 문법에서
-- 실패한다. 그래서 nvim 이 zsh 로 판정한 버퍼는 -ln zsh 를 명시한다.
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
          if vim.bo[ctx.buf].filetype == "zsh" then
            return { "-ln", "zsh" }
          end
          return {}
        end,
      })
    end,
  },
}
