-- 현재 줄 끝에 git blame (작성자, 날짜, 커밋 메시지) 을 흐리게 보여 준다. gitsigns 의 기능이다.
-- LazyVim 은 기본으로 꺼 두고 토글 키도 없어서, 여기서 켜고 토글은 keymaps.lua 의 <leader>ub 에 둔다.
-- 표시 시점·형식은 :h gitsigns-config-current_line_blame_opts 참고 (delay 기본 1000ms).
return {
  "lewis6991/gitsigns.nvim",
  opts = {
    current_line_blame = true,
    current_line_blame_opts = { delay = 300 },
  },
}
