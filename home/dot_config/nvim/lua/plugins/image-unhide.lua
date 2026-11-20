-- snacks.image 버그 우회: 이미지 버퍼를 떠났다 돌아오면 그림이 사라진다.
--
-- 원인 (snacks/image/placement.lua):
--   update() 는 지금 탭페이지에서 그 버퍼를 띄운 창이 없으면 hide() 로 hidden 을 켠다. 그런데 창이 다시 생겨도
--   show() 를 부르는 곳이 없다. hidden 인 채로는 _render() 가 그림 칸(virt_lines)을 빈 문자열로 그려서,
--   다른 버퍼·탭페이지·tmux 윈도우에 갔다 오면 그림이 나오지 않는다.
--   formats 의 모든 형식(png·jpg·gif·webp·pdf·mp4 …)이 같은 길(BufReadCmd → Snacks.image.buf.attach →
--   placement.new)로 열리므로 형식과 상관없이 생긴다. svg-preview.lua 의 SVG 프리뷰도 같은 placement 를 쓴다.
--
-- 우회: Placement 클래스의 update 를 감싸서, 부를 때마다 먼저 "창이 있는데 hidden 이면 hidden 을 끈다".
--   show() 는 update() 를 다시 부르므로 쓰지 않고 값만 바꾼다. 바뀐 hidden 이 state() 에 들어가 이번 update 가 다시 그린다.
--   클래스 메서드를 바꾸므로 이미 만들어진 placement(시작할 때 인자로 연 파일)에도 적용된다.
--
-- 문서에 있는 on_update_pre 를 쓰지 않는 이유: placement.new 는 넘겨받은 opts 만 쓰고 전역 Snacks.image.config 와
--   합치지 않는다. BufReadCmd 는 opts 없이 attach 하므로 전역 설정으로는 일반 이미지 파일에 끼워 넣을 길이 없다.
--
-- 시점: placement 모듈은 맨 위에서 Snacks.image.terminal 을 읽으므로 snacks 설정이 끝난 뒤에 불러야 한다.
--   VeryLazy 면 충분하다. 버그는 처음 그린 뒤 버퍼를 오갈 때 생기고, 그 전에 패치가 들어간다.
--
-- snacks 가 고치면(창이 있을 때 hidden 을 끄면) 여기서 할 일이 없어져 아무것도 하지 않는다. 그때 이 파일을 지운다.
-- update 가 없어지는 등 내부가 바뀌면 패치를 건너뛴다.

local function patch()
  local ok, P = pcall(function()
    return Snacks.image.placement
  end)
  if not ok or type(P) ~= "table" or type(P.update) ~= "function" or P._jw_unhide then
    return
  end
  P._jw_unhide = true
  local update = P.update
  ---@param self snacks.image.Placement
  P.update = function(self, ...)
    if self.hidden and vim.api.nvim_buf_is_valid(self.buf) then
      for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.api.nvim_win_get_buf(win) == self.buf then
          self.hidden = false
          break
        end
      end
    end
    return update(self, ...)
  end
end

return {
  {
    "folke/snacks.nvim",
    init = function()
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        once = true,
        callback = patch,
      })
    end,
  },
}
