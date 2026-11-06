-- which-key: <leader> 같은 접두사를 누르고 멈추면 뒤에 올 수 있는 키를 팝업으로 보여준다.
-- 키를 바꾸지 않는다. 내용은 각 키맵의 desc 에서 자동으로 가져오므로 keymaps.lua 에
-- desc 를 달아 두는 것이 곧 이 팝업의 문서다. 여기서는 그룹 이름만 붙인다.
-- 선별된 치트시트는 :h jw (<leader>?) 가 따로 맡는다.
--
-- 활동 상태: 2025-10 이후 push 없음 (안정 상태). folke 작. 문제가 생기면 이 파일만 지우면 된다.
if vim.g.vscode then
  return {}
end

return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      spec = {
        { "<leader>f", group = "find" },
        { "<leader>g", group = "git" },
        { "<leader>gh", group = "hunks" },
        { "<leader>c", group = "code" },
        { "<leader>m", group = "markdown" },
        { "<leader>t", group = "toggle" },
        { "<leader>y", group = "yank path", mode = { "n", "x" } },
        { "]", group = "next" },
        { "[", group = "prev" },
      },
    },
  },
}
