-- <leader>fp (snacks 의 projects 피커) 가 찾는 프로젝트 위치.
--
-- snacks 기본값은 dev = { "~/dev", "~/projects" }, max_depth = 2 다. projects 피커는 dev 의 각 디렉터리
-- 아래를 fd 로 max_depth 단계까지 뒤져 .git·package.json 등이 있는 디렉터리를 프로젝트로 잡는다.
-- 여기 저장소는 ~/dev/<분류>/<저장소> (깊이 3) 나 ~/dev/<분류>/<묶음>/<저장소> (깊이 4) 에 있어서
-- 기본값으로는 하나도 안 잡히고, 최근 연 파일의 git 루트만 목록에 나온다.
--
-- max_depth 는 dev 전체에 하나만 줄 수 있으므로, 깊이를 늘리는 대신 "프로젝트들의 부모 디렉터리"를
-- dev 에 나열하고 깊이는 기본값 2 를 둔다 (부모/<프로젝트>/.git 이 깊이 2). 깊이를 늘리면 저장소 안의
-- 하위 패키지(package.json 이 있는 디렉터리)까지 프로젝트로 잡힌다.
--
-- 아래 패턴의 마지막 * 가 프로젝트 자리다. 그 앞부분을 glob 으로 펼쳐 dev 에 넣는다.
-- glob 은 nvim 시작 때 한 번 펼치므로, 새 묶음 디렉터리를 만들면 nvim 을 다시 켜야 잡힌다.
-- 없는 경로는 빼야 한다: fd 는 검색 경로 하나라도 없으면 통째로 실패한다.
--
-- 주의: lazy.nvim·snacks 의 opts 병합은 리스트를 통째로 바꾼다. 아래 목록이 기본값을 대체한다.
--
-- 머신마다 다른 위치: 없는 경로는 자동으로 빠지므로 여러 머신의 경로를 여기 함께 적어도 된다.
-- 한 머신에만 있거나 공개 저장소에 올리기 싫은 경로는 그 머신의 관리 밖 파일에 둔다
-- (docs/tool-scope.md 의 예 C-3):
--   -- ~/.config/nvim/lua/plugins/local-projects.lua
--   vim.g.local_project_patterns = { "~/work/*" }
--   return {}
-- local-*.lua 는 이름순으로 이 파일보다 먼저 읽혀서, 거기서 snacks 의 dev 를 직접 정하면 이 파일이 덮어쓴다.
-- 그래서 값은 vim.g 로 받고, 펼치기는 아래 opts 함수에서 한다. opts 함수는 모든 spec 파일을 읽은 뒤
-- snacks 를 불러올 때 실행되므로 파일 순서와 상관없다.
local project_patterns = {
  "~/dev/jwlee/*",
  "~/dev/opensources/*",
  "~/dev/opensources/@forked/*",
  "~/dev/playground/*/*",
  "~/dev/workspaces/*/*",
}

-- 패턴들의 마지막 * 앞부분을 glob 으로 펼쳐, 실제로 있는 디렉터리만 중복 없이 돌려준다.
local function expand_project_parents(patterns)
  local dirs, seen = {}, {}
  for _, pattern in ipairs(patterns) do
    local parent = pattern:gsub("/%*$", "")
    for _, dir in ipairs(vim.fn.glob(parent, false, true)) do
      if vim.fn.isdirectory(dir) == 1 and not seen[dir] then
        seen[dir] = true
        dirs[#dirs + 1] = dir
      end
    end
  end
  return dirs
end

-- explorer 키. snacks 기본 키(o, l)와 LazyVim 키(<leader>e, <leader>E)를 바꾼다.
--   <leader>e  (전역) explorer 로 "가기" (root dir). 닫혀 있으면 열고, 열려 있으면 현재 파일을 트리에서 찾아
--              그 위로 포커스를 옮긴다. LazyVim 기본은 <leader>fe 로 넘겨 토글(열려 있으면 닫기)하는데,
--              그러면 포커스 이동에 못 써서 덮어쓴다. LazyVim 의 <leader>e 는 <leader>fe 를 remap 으로 부르는
--              별도 매핑이라, 이것만 바꿔도 <leader>fe 는 토글로 남는다.
--   <leader>E  (전역) 같은 "가기" 를 cwd 기준으로. <leader>fE 는 cwd 토글로 남는다.
--              이미 열려 있으면 기준 디렉터리와 상관없이 그 explorer 로 간다.
--   l          (explorer 목록) 열되 포커스는 explorer 에 남긴다. snacks 기본은 열고 편집 창으로 간다.
--   o          (explorer 목록) 열고 편집 창으로 간다 (snacks 기본 l).
--   O          (explorer 목록) 시스템 앱으로 열기 (snacks 기본 o).
--   <C-r>      (explorer 목록) Finder 에서 그 파일을 선택해 보여 준다. snacks 의 <c-r> 은 git·projects 피커와
--              입력창 insert 모드(<c-r>% 등)에만 있어서 explorer 목록에서는 겹치지 않는다.

-- 편집 창에서 explorer 로 포커스를 옮기고 현재 파일을 트리에서 보여 준다.
---@param cwd? string 새로 열 때의 기준 디렉터리. nil 이면 nvim 의 cwd.
local function focus_explorer(cwd)
  local explorer = Snacks.picker.get({ source = "explorer" })[1]
  if not explorer then
    -- 새로 열 때는 follow_file 이 현재 파일 위치를 펼쳐 주고, 포커스도 목록에 간다.
    Snacks.explorer({ cwd = cwd })
    return
  end
  -- explorer 안이나 터미널처럼 파일이 아닌 버퍼에서 부르면 보여 줄 파일이 없으니 포커스만 옮긴다.
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= "" then
    Snacks.explorer.reveal({ buf = buf })
  end
  explorer:focus("list")
end

-- <leader>sF: filetype 을 골라 현재 버퍼에 적용한다 (하이라이팅·Treesitter·LSP 가 그 언어로 다시 붙는다).
-- snacks 에는 Telescope·fzf-lua 의 filetypes 같은 소스가 없어서 직접 만든다. :set ft=<Tab> 과 같은 목록이다.
-- 키는 s(피커 모음: sk 키맵, sC 명령, sH 하이라이트 그룹) 그룹에 F(iletype). LazyVim 코어·모든 extras·snacks 가
-- 안 쓰는 키다 (<leader>uF 는 버퍼 단위 자동 포맷 토글이라 쓸 수 없다).
local function pick_filetype()
  local items = vim.tbl_map(function(ft)
    return { text = ft }
  end, vim.fn.getcompletion("", "filetype"))
  Snacks.picker({
    title = "Filetypes",
    items = items,
    format = "text",
    layout = { preset = "select" },
    confirm = function(picker, item)
      picker:close()
      if item then
        vim.bo.filetype = item.text
      end
    end,
  })
end

return {
  "folke/snacks.nvim",
  keys = {
    -- stylua: ignore start
    { "<leader>e", function() focus_explorer(LazyVim.root()) end, desc = "Focus Explorer (root dir)" },
    { "<leader>E", function() focus_explorer() end, desc = "Focus Explorer (cwd)" },
    -- stylua: ignore end
    { "<leader>sF", pick_filetype, desc = "Filetype (set for buffer)" },
  },
  -- 함수로 둔 이유는 위 "머신마다 다른 위치" 참고. lazy 의 merge 는 spec 병합과 같은 규칙(리스트는 교체)이다.
  opts = function(_, opts)
    local local_patterns = vim.g.local_project_patterns or {}
    if type(local_patterns) == "string" then
      local_patterns = { local_patterns }
    end
    local patterns = vim.list_extend(vim.deepcopy(project_patterns), local_patterns)
    return require("lazy.core.util").merge(opts, {
      -- 알림(vim.notify → snacks.notifier)이 떠 있는 시간(ms). 기본 3000 은 읽기 전에 사라진다.
      -- 0 이면 시간이 지나도 닫히지 않고 <leader>un(Dismiss All Notifications)으로 닫을 때까지 남는다.
      -- 이미 사라진 알림은 <leader>n(Notification History)에서 다시 볼 수 있다.
      notifier = { timeout = 10000 },
      picker = {
        sources = {
          projects = { dev = expand_project_parents(patterns) },
          explorer = {
            actions = {
              reveal_in_finder = function(_, item)
                if item then
                  vim.system({ "open", "-R", item.file })
                end
              end,
            },
            win = {
              list = {
                keys = {
                  -- confirm 이 편집 창으로 포커스를 옮겨 파일을 연 뒤, focus_list 가 explorer 로 되돌린다.
                  ["l"] = { { "confirm", "focus_list" }, desc = "Open (keep focus)" },
                  ["o"] = { "confirm", desc = "Open" },
                  ["O"] = { "explorer_open", desc = "Open with System App" },
                  ["<C-r>"] = { "reveal_in_finder", desc = "Reveal in Finder" },
                },
              },
            },
          },
        },
      },
    })
  end,
}
