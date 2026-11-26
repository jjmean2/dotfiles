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

-- explorer 키. snacks 기본 키(o, l)와 LazyVim 키(<leader>e, <leader>E, <leader>fe, <leader>fE)를 바꾼다.
--   <leader>e  (전역) explorer 토글 (root dir). 열려 있으면 닫는다. LazyVim 기본 <leader>fe 의 동작이다.
--              LazyVim 의 <leader>e 는 <leader>fe 를 remap 으로 부르는 매핑이라, <leader>fe 를 바꾸면 같이
--              바뀌어 버린다. 그래서 토글을 직접 매핑한다.
--   <leader>E  (전역) explorer 토글 (cwd). LazyVim 기본 <leader>fE 의 동작이다.
--   <leader>fe (전역) explorer 로 "가기" (root dir). 닫혀 있으면 열고, 열려 있으면 현재 파일을 트리에서 찾아
--              그 위로 포커스를 옮긴다.
--   <leader>fE (전역) 같은 "가기" 를 cwd 기준으로.
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

-- git 로그 피커 (<leader>gl gL: git_log, <leader>gf: git_log_file, <leader>gb: git_log_line).
-- snacks 기본 confirm(Enter) 은 git_checkout 이다. git_log 는 커밋을 checkout 해 detached HEAD 가 되고,
-- git_log_file·git_log_line 은 `git checkout <커밋> -- <파일>` 이라 저장 안 한 수정·커밋 안 한 변경을
-- 경고 없이 덮어쓴다. 보기만 하도록 바꾸고 checkout 은 <a-CR> 로 옮긴 뒤 확인 팝업까지 거친다.
-- 규칙: 원래 Enter 가 위험한 동작이던 피커는 Alt+Enter 가 그 동작이다.
-- 확인 팝업은 snacks 의 Snacks.picker.util.confirm (No·Yes 선택창, No 가 먼저라 Enter 연타는 취소된다).
-- No 를 고르면 로그 피커로 돌아온다.
-- git_branches(브랜치 전환)·git_stash(apply) 의 Enter 는 그대로 둔다. 브랜치 전환은 로컬 변경이 덮어써질
-- 상황이면 git 이 거부하고, stash apply 는 stash 를 지우지 않고 덮어써질 파일이 있으면 거부한다.
--   git_log                      Enter  그 커밋을 gitsigns 리뷰 패널로 연다 (:Gitsigns diff --commit)
--   git_log_file, git_log_line   Enter  그 커밋이 이 파일에 한 변경만 리뷰 패널로 (부모 ↔ 그 커밋)
--                                <a-v>  지금 파일 vs 그 커밋의 파일 diff (:Gitsigns diffthis <커밋>). v 는 versus.
--                                <a-o>  그 커밋 시점의 파일을 읽기 전용 버퍼로 연다 (:Gitsigns show <커밋>:%)
--   셋 다                        <a-CR> 원래 동작 (checkout), 확인 팝업 뒤에
-- 다음 커밋을 보려면 <leader>sR (resume) 로 같은 목록을 다시 연다.
-- 한계: --follow 로 잡힌 "이름이 바뀌기 전" 커밋은 <a-v>·<a-o> 가 지금 경로로 찾으므로 파일이 없다고 나올
-- 수 있다. Enter 는 옛 이름까지 pathspec 으로 넘겨서 보인다.
-- 키는 snacks·LazyVim 이 피커에서 쓰지 않는 Alt 키만 쓴다 (기본 키를 덮어쓰지 않는다).
-- :Gitsigns diff (리뷰 패널) 는 gitsigns 최신(2026-11) 기능이다. 없으면 :Gitsigns show 로 대신한다.

-- 저장소 루트 기준 pathspec. item.files 의 첫째는 현재 파일 절대 경로, 나머지는 --follow 가 찾은 옛 이름
-- (루트 기준). :(top) 을 붙여 nvim 의 cwd 가 저장소 하위 디렉터리여도 루트에서 찾게 한다.
local function git_item_pathspecs(item)
  local specs = {}
  for _, f in ipairs(item.files or { item.file }) do
    if item.cwd and vim.startswith(f, item.cwd .. "/") then
      f = f:sub(#item.cwd + 2)
    end
    specs[#specs + 1] = ":(top)" .. f
  end
  return specs
end

-- 리뷰 패널로 커밋 보기. paths 가 있으면 그 파일들만.
local function git_review_commit(commit, paths)
  local gs = require("gitsigns")
  if gs.diff then
    gs.diff(commit, paths, { commit = true })
  else
    gs.show(commit)
  end
end

local git_log_actions = {
  git_review_commit = function(picker, item)
    picker:close()
    if item then
      git_review_commit(item.commit)
    end
  end,
  git_diffthis = function(picker, item)
    picker:close()
    if item then
      require("gitsigns").diffthis(item.commit)
    end
  end,
  git_review_file = function(picker, item)
    picker:close()
    if item then
      git_review_commit(item.commit, git_item_pathspecs(item))
    end
  end,
  git_show_rev = function(picker, item)
    picker:close()
    if item then
      require("gitsigns").show(item.commit .. ":%")
    end
  end,
  -- 확인 뒤 snacks 원래 git_checkout (피커를 닫고 checkout). 피커는 확인하는 동안 열어 둔다.
  git_checkout_confirm = function(picker, item)
    if not item then
      return
    end
    local prompt = item.file
        and ("%s 를 %s 시점으로 덮어쓸까요? (커밋 안 한 변경이 사라집니다)"):format(
          vim.fn.fnamemodify(item.file, ":t"),
          item.commit
        )
      or ("%s 를 checkout 할까요? (detached HEAD)"):format(item.commit)
    Snacks.picker.util.confirm(prompt, function()
      require("snacks.picker.actions").git_checkout(picker, item)
    end)
  end,
}

-- 목록 포커스로 여니 list 창에도 같은 키를 건다.
---@param keys table<string, string>
local function git_log_win(keys)
  local input, list = {}, {}
  for lhs, action in pairs(keys) do
    input[lhs] = { action, mode = { "n", "i" } }
    list[lhs] = action
  end
  return { input = { keys = input }, list = { keys = list } }
end

local git_log_file_source = {
  focus = "list",
  confirm = "git_review_file",
  actions = git_log_actions,
  win = git_log_win({ ["<a-v>"] = "git_diffthis", ["<a-o>"] = "git_show_rev", ["<a-CR>"] = "git_checkout_confirm" }),
}

return {
  "folke/snacks.nvim",
  keys = {
    -- stylua: ignore start
    { "<leader>e", function() Snacks.explorer({ cwd = LazyVim.root() }) end, desc = "Explorer Snacks (root dir)" },
    { "<leader>E", function() Snacks.explorer() end, desc = "Explorer Snacks (cwd)" },
    { "<leader>fe", function() focus_explorer(LazyVim.root()) end, desc = "Focus Explorer (root dir)" },
    { "<leader>fE", function() focus_explorer() end, desc = "Focus Explorer (cwd)" },
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
      notifier = { timeout = 5000 },
      picker = {
        -- 입력창에서 이전/다음 검색어(기록)로 이동. 기록은 피커 종류(source)마다 따로 남는다.
        -- 기본 <C-Up>/<C-Down> 은 macOS Mission Control 과 겹쳐서 nvim 까지 오지 않을 때가 있다.
        -- <C-p>/<C-n> 은 목록 위/아래(blink 메뉴와 같은 습관)라 남겨 두고, 비어 있는 Alt+k/j 를 쓴다.
        -- 왼쪽 Option 만 Alt 로 동작한다 (ghostty config 의 macos-option-as-alt = left).
        win = {
          input = {
            keys = {
              ["<M-k>"] = { "history_back", mode = { "i", "n" }, desc = "Previous search" },
              ["<M-j>"] = { "history_forward", mode = { "i", "n" }, desc = "Next search" },
            },
          },
        },
        sources = {
          -- 처음 열 때 목록에 포커스 (snacks 기본은 입력창, explorer 만 목록).
          -- 결과가 적거나 미리 정해져 있어서 검색보다 위아래로 훑어보는 일이 많은 피커들이다.
          -- 거르고 싶으면 / 나 i 로 입력창에 간다.
          -- LSP: gd gy gI gr gai gao. gd·gy 는 결과가 하나면 피커 없이 바로 점프한다.
          lsp_definitions = { focus = "list" },
          lsp_type_definitions = { focus = "list" },
          lsp_implementations = { focus = "list" },
          lsp_references = { focus = "list" },
          lsp_incoming_calls = { focus = "list" },
          lsp_outgoing_calls = { focus = "list" },
          -- 진단·목록: <leader>sD <leader>sq <leader>sl
          diagnostics_buffer = { focus = "list" },
          qflist = { focus = "list" },
          loclist = { focus = "list" },
          diagnostics = { focus = "list" }, -- <leader>sd
          todo_comments = { focus = "list" }, -- <leader>st <leader>sT
          -- Git: <leader>gs <leader>gd <leader>gD <leader>gS
          git_status = { focus = "list" },
          git_diff = { focus = "list" },
          git_stash = { focus = "list" },
          -- git 로그: <leader>gl <leader>gL <leader>gf <leader>gb. Enter 를 checkout 대신 보기로 (위 설명 참고).
          git_log = {
            focus = "list",
            confirm = "git_review_commit",
            actions = git_log_actions,
            win = git_log_win({ ["<a-CR>"] = "git_checkout_confirm" }),
          },
          git_log_file = git_log_file_source,
          git_log_line = git_log_file_source,
          git_branches = { focus = "list" }, -- LazyVim 키 없음 (:lua Snacks.picker.git_branches())
          -- GitHub: <leader>gi <leader>gI <leader>gp <leader>gP. Enter 는 동작 메뉴(gh_actions)다.
          gh_issue = { focus = "list" },
          gh_pr = { focus = "list" },
          -- 시간순 기록 (최근 것이 위): <leader>su <leader>sj <leader>n <leader>fr <leader>fR
          -- <leader>: <leader>sc <leader>s/
          undo = { focus = "list" },
          jumps = { focus = "list" },
          notifications = { focus = "list" },
          recent = { focus = "list" },
          command_history = { focus = "list" },
          search_history = { focus = "list" },
          -- 몇 개 안 되는 목록: <leader>, <leader>fb <leader>fB <leader>sm <leader>s" <leader>cl
          buffers = { focus = "list" },
          marks = { focus = "list" },
          registers = { focus = "list" },
          lsp_config = { focus = "list" },
          -- 미리보기를 보며 고른다: <leader>uC (목록을 움직이면 바로 적용해 본다)
          colorschemes = { focus = "list" },
          -- vim.ui.select (코드 액션 <leader>ca, 각종 선택창). 대부분 몇 개 안 되는 선택지다.
          select = { focus = "list" },
          -- 입력창 그대로 (검색어 입력이 주 기능): files git_files grep live_grep grep_word grep_buffers lines
          -- lsp_symbols lsp_workspace_symbols projects help keymaps commands highlights autocmds icons man lazy
          -- 와 <leader>fc(설정 파일), <leader>sF(filetype).
          projects = { dev = expand_project_parents(patterns) },
          explorer = {
            -- 필터 입력을 fuzzy 로 맞춘다. snacks 의 explorer 기본은 fuzzy = false (부분 문자열 일치)이고,
            -- 검색어 문법으로 fuzzy 를 켜는 방법은 없다 (', ^, $, ! 는 모두 fuzzy 를 끄는 쪽이다).
            -- 비교 대상은 cwd 기준 상대 경로 전체다. 정확히 찾고 싶으면 'foo 를 쓴다. sort_empty 등은 기본값이 병합돼 남는다.
            matcher = { fuzzy = true },
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
