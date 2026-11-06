-- 아웃라인 사이드바 (VS Code 의 OUTLINE 패널): aerial.nvim. 키맵은 lua/config/keymaps.lua 의
-- "<leader>o" 절에 있다.
--
-- 순정 대안과의 차이
--   gO (+ :vert lopen) 도 심볼 목록을 준다. 다만 평평한 location list 라 계층이 없고, 커서를
--   따라가지 않으며, 파일을 바꾸면 다시 눌러야 한다. 그 세 가지가 필요할 때 이 사이드바를 쓴다.
--   snacks 의 lsp_symbols 피커(<leader>fs)는 "골라서 뛰기" 용, 이것은 "옆에 띄워 두기" 용이다.
if vim.g.vscode then
  return {}
end

return {
  -- 멘탈 모델
  --   현재 창의 버퍼에서 심볼 트리를 뽑아 옆 창(일반 버퍼, filetype=aerial)에 그린다.
  --   심볼 출처(backends)는 앞에서부터 쓸 수 있는 것을 고른다 (기본값):
  --     treesitter → lsp → markdown → asciidoc → man
  --   treesitter 가 먼저라 LSP 가 없거나 늦게 붙어도 바로 나오고, 마크다운은 제목 트리가 된다.
  --   어느 출처를 쓰는지는 :AerialInfo 로 본다.
  -- 커서 따라가기: 소스 창의 커서가 있는 심볼(없으면 가장 가까운 것)이 사이드바에서 강조된다.
  -- 사이드바 안 키(버퍼 로컬, 순정 키를 덮지 않는다): <CR> 뛰기, p 미리 스크롤, { } 이전/다음,
  --   h/l 접기/펼치기, zR/zM 전부 펼치기/접기, q 닫기, ? 도움말.
  -- 보이는 심볼 종류는 filter_kind 기본값(Class, Function, Method, Interface 등)이다. 변수·상수는
  --   빠진다. 필요해지면 filter_kind 에 추가하거나 false 로 전부 보이게 한다.
  -- cmd 로 지연 로드한다. :AerialToggle 을 처음 부를 때 로드된다.
  {
    "stevearc/aerial.nvim",
    cmd = { "AerialToggle", "AerialOpen", "AerialNavToggle", "AerialInfo" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts = {
      layout = {
        -- 왼쪽은 nvim-tree 자리다. 아웃라인은 화면 맨 오른쪽 가장자리에 붙인다
        -- (기본 placement = "window" 는 현재 창 바로 옆이라 분할 사이에 끼어든다).
        default_direction = "right",
        placement = "edge",
      },
      -- 기본 "window" 는 사이드바를 연 창의 버퍼에 고정된다. "global" 은 지금 포커스된 창을
      -- 따라간다 (VS Code 아웃라인처럼 편집 중인 파일이 바뀌면 같이 바뀐다).
      attach_mode = "global",
      -- 트리 줄(├─ │)을 그린다. 깊은 중첩에서 부모를 읽기 쉽다.
      show_guides = true,
    },
  },
}
