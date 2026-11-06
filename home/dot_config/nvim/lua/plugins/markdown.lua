-- 마크다운 보기: 두 층으로 나눈다. 키맵은 lua/config/keymaps.lua 의 "마크다운" 절에 있다.
--
--   1. 버퍼 안 렌더링 (render-markdown.nvim) — 평소 읽고 쓰는 용도
--   2. 브라우저 라이브 프리뷰 (live-preview.nvim) — Mermaid, 수식, 최종 모양 확인용
--
-- 터미널은 고정폭 문자 격자라 글자 크기(큰 헤딩)나 비례 폰트는 원리상 안 된다. 색, 배경,
-- 테두리 문자, 아이콘, 기호 숨기기로 할 수 있는 만큼은 1 이 하고, 나머지는 2 가 맡는다.
if vim.g.vscode then
  return {}
end

return {
  -- ---------------------------------------------------------------------------
  -- render-markdown.nvim
  -- ---------------------------------------------------------------------------
  -- 멘탈 모델
  --   파일 텍스트는 한 글자도 바꾸지 않는다. treesitter(markdown, markdown_inline 파서)로
  --   구조를 읽고 extmark(가상 텍스트, 하이라이트, conceal)로 겉모습만 덧칠한다.
  --   그래서 저장되는 내용, 검색, 이동, 텍스트 객체는 순정과 같다.
  --   - 헤딩: # 대신 아이콘 + 줄 배경       - 표: 테두리 선과 정렬
  --   - 코드블록: 배경 + 언어 아이콘        - 목록·체크박스·인용: 기호를 아이콘으로
  -- anti-conceal (기본 켜짐): 커서가 있는 줄은 덧칠이 사라지고 원문이 보인다. 그 줄을 고칠 때
  --   보이는 그대로 편집하기 위해서다.
  -- render_modes (기본 n, c, t): 노멀·명령줄 모드에서만 렌더하고, insert 모드에서는 버퍼 전체가
  --   원문으로 돌아온다.
  -- 끄고 켜기: :RenderMarkdown toggle (<leader>mr). 버퍼 단위.
  -- 파서 설치는 lua/plugins/treesitter.lua 가 한다 (markdown, markdown_inline, 프론트매터용 yaml).
  -- 아이콘은 nvim-tree 때문에 이미 있는 nvim-web-devicons 를 쓴다 (mini.icons 대신).
  -- ft 로 지연 로드한다. 플러그인이 lazy.nvim 의 ft 를 읽어 file_types 로 쓴다 (문서 권장 방식).
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {},
  },

  -- ---------------------------------------------------------------------------
  -- live-preview.nvim
  -- ---------------------------------------------------------------------------
  -- 멘탈 모델
  --   nvim 안에서 순수 Lua 로 작은 HTTP 서버(127.0.0.1:5500)를 띄우고, 기본 브라우저가 그
  --   페이지를 연다. 마크다운은 저장하지 않아도 타이핑하는 대로 갱신되고, 스크롤도 따라온다
  --   (sync_scroll). HTML 은 저장할 때만 갱신된다. Mermaid, KaTeX, 코드 하이라이트 지원.
  --   node/deno 같은 외부 런타임과 빌드 단계가 없다 (markdown-preview.nvim 과의 차이).
  -- 명령: :LivePreview start [경로] / close / pick / help.  상태 확인: :checkhealth livepreview
  -- 서버 루트는 cwd(워크스페이스)다 (dynamic_root = false). 상대 경로 이미지도 그 기준으로 보인다.
  -- 브라우저 캐시: 플러그인을 업데이트한 뒤 이상하면 브라우저 캐시를 비운다 (README 안내).
  -- cmd 로 지연 로드한다. :LivePreview 를 처음 부를 때 로드된다.
  {
    "brianhuster/live-preview.nvim",
    cmd = "LivePreview",
    dependencies = { "folke/snacks.nvim" },
    config = function()
      -- setup() 이 아니라 livepreview.config.set() 이 설정 진입점이다. 기본값과 다른 것만 적는다.
      require("livepreview.config").set({
        -- :LivePreview pick 이 쓸 피커. 비우면 처음 찾은 것을 쓰므로 명시한다.
        picker = "snacks.picker",
      })
    end,
  },
}
