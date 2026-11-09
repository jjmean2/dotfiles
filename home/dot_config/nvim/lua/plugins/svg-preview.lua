-- SVG 를 XML 로 편집하면서 같은 버퍼 위에 그림으로도 볼 수 있게 한다. 그리는 일은 snacks.image 가 한다
-- (kitty 그래픽 프로토콜의 유니코드 placeholder: Ghostty 지원, tmux 안에서는 snacks 가 allow-passthrough 를 켠다.
-- SVG → PNG 변환에 ImageMagick 의 magick 이 필요하다. :checkhealth snacks 로 확인).
--
--   <leader>cp  (svg 버퍼) 그림 보기 켜기/끄기. 켜면 XML 글자를 숨기고(conceal) 그 자리에 그림을 덮어 그린다.
--               render-markdown 처럼 원본 버퍼를 꾸미기만 해서 별도 버퍼가 없다. 저장 안 한 수정도 보인다.
--               켠 동안 insert 모드에 들어가면 그림이 걷혀 XML 이 보이고, 나오면 바뀐 내용으로 다시 그린다.
--               normal 모드 수정(u, dd, p, :s 등)도 잠시 뒤 다시 그린다.
--   P / <a-p>   (explorer 목록, snacks 기본 키) 미리보기를 켜면 .svg 위에서 그림이 나온다.
--               explorer 는 sidebar 레이아웃이라 미리보기가 편집 창을 잠시 빌려 쓴다. 디스크 내용이 보인다.
--
-- 키: <leader>cp 는 LazyVim 의 markdown·typst extra 가 그 filetype 에서 "미리보기" 로 쓰는 키라 같은 뜻으로 맞췄다.
-- 버퍼 로컬로만 걸어서 다른 filetype 의 <leader>cp 와 겹치지 않는다. svg 에는 LazyVim 코어·extras 가 거는 키가 없다.
--
-- 그리는 방식: Snacks.image.placement 의 inline 모드(snacks 가 markdown 문서 안 이미지를 그릴 때 쓰는 것).
--   range 를 버퍼 전체로 주고 conceal 을 켜면, 범위의 글자를 conceal 하고 첫 줄부터 그림을 overlay 로 덮는다.
--   그림보다 XML 이 길면 남는 줄을 conceal_lines 로 숨기고(nvim 0.11.4+), 짧으면 그림 아래쪽을 가상 줄로 붙인다.
--   - conceallevel 이 2 이상이어야 글자가 사라진다 (LazyVim 기본값 2).
--   - 커서 줄은 concealcursor 가 비어 있으면 글자가 다시 드러나서, 켠 동안 그 창·버퍼에 concealcursor=n 을
--     setlocal 한다 (창 옵션의 setlocal 은 그 창에 이 버퍼가 떠 있을 때만 적용된다). 끌 때 전역값으로 되돌린다.
--   - wrap 이 켜져 있고 창보다 긴 줄이 있으면 snacks 가 덮어 그리지 않고 그림을 XML 아래 가상 줄로 붙인다
--     (LazyVim 기본은 wrap=false).
--   다시 그릴 때 새 그림이 준비되면(on_update) 이전 그림을 닫아서, 변환하는 동안 화면이 깜박이지 않는다.
--
-- snacks.image 의 opts.formats 에 svg 를 넣지 않는 이유: formats 의 확장자는 BufReadCmd 가 가로채
-- 항상 수정 불가 이미지 버퍼로 열어서, XML 을 편집할 수 없게 된다.
--
-- 복사본을 그리는 이유: snacks 는 변환한 PNG 를 원본 경로의 해시로만 캐시하고 수정 시각을 보지 않아서,
-- 원본을 그대로 넘기면 수정 전 그림이 나온다. 그래서 내용이 바뀔 때마다 이름이 다른 복사본을 만들어 넘긴다.
--   이름   <원본 경로 해시 8자>-<종류><버전>.svg  (b = 버퍼 내용·changedtick, f = 디스크 파일·mtime)
--   위치   nvim 인스턴스 전용 임시 디렉터리(tempname() 의 부모). nvim 이 종료할 때 디렉터리째 지운다.
--          인스턴스마다 경로가 달라서 PNG 도 인스턴스끼리 공유하지 않는다.
--   정리   복사본은 변환에만 쓰이므로, 같은 원본·같은 종류의 새 복사본을 만들 때 이전 것을 지운다.
--          PNG(snacks 캐시, ~/.cache/nvim/snacks/image)는 snacks 가 그 nvim 이 켜져 있는 동안 다시 보낼 때
--          쓰므로 종료할 때(VimLeavePre) 이 인스턴스가 만든 것만 지운다.
--          snacks 의 PNG 이름은 <src 해시 8자>-<src 파일 이름(확장자 뺌)>.png 다 (snacks/image/convert.lua).

local M = {}

local made = {} ---@type table<string, true> 이 인스턴스가 만든 복사본 이름(확장자 뺌)

local function copy_dir()
  return vim.fn.fnamemodify(vim.fn.tempname(), ":h") .. "/svg-preview"
end

-- 원본 path 의 복사본 경로를 돌려준다. 같은 (원본, 종류, 버전) 이면 같은 경로라서 다시 만들지 않는다.
---@param path string 원본 SVG 경로
---@param kind "b"|"f"
---@param version integer
---@param write fun(dst: string)
local function snapshot(path, kind, version, write)
  local dir = copy_dir()
  vim.fn.mkdir(dir, "p")
  local prefix = vim.fn.sha256(vim.fs.normalize(path)):sub(1, 8) .. "-" .. kind
  local name = prefix .. version
  local dst = dir .. "/" .. name .. ".svg"
  if not vim.uv.fs_stat(dst) then
    for _, old in ipairs(vim.fn.glob(dir .. "/" .. prefix .. "*.svg", false, true)) do
      vim.uv.fs_unlink(old)
    end
    write(dst)
    made[name] = true
  end
  return dst
end

---@class svg_preview.State
---@field placements snacks.image.Placement[] 그려져 있거나 준비 중인 그림. 마지막이 최신
---@field timer? uv.uv_timer_t 다시 그리기 debounce

local states = {} ---@type table<integer, svg_preview.State> 그림 보기가 켜진 버퍼

---@param buf integer
---@param on boolean
local function set_concealcursor(buf, on)
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    vim.api.nvim_win_call(win, function()
      if on then
        vim.opt_local.concealcursor = "n"
      else
        vim.cmd("setlocal concealcursor<")
      end
    end)
  end
end

---@param state svg_preview.State
---@param keep? snacks.image.Placement 남길 그림
local function close_placements(state, keep)
  local rest = {} ---@type snacks.image.Placement[]
  for _, p in ipairs(state.placements) do
    if p == keep then
      rest[#rest + 1] = p
    else
      p:close()
    end
  end
  state.placements = rest
end

-- 지금 버퍼 내용으로 그림을 새로 만든다. 새 그림이 그려지면 이전 그림들을 닫는다.
---@param buf integer
local function render(buf)
  local state = states[buf]
  if not (state and vim.api.nvim_buf_is_valid(buf)) then
    return
  end
  local path = vim.api.nvim_buf_get_name(buf)
  if path == "" then
    path = "[No Name " .. buf .. "]" -- 해시 재료로만 쓴다
  end
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local src = snapshot(path, "b", vim.api.nvim_buf_get_changedtick(buf), function(dst)
    vim.fn.writefile(lines, dst)
  end)

  local p ---@type snacks.image.Placement
  p = Snacks.image.placement.new(buf, src, {
    inline = true,
    conceal = true,
    pos = { 1, 0 },
    range = { 1, 0, #lines, #lines[#lines] },
    auto_resize = true, -- 창 크기가 바뀌면 다시 맞춘다
    on_update = function()
      if states[buf] == state then
        close_placements(state, p)
      end
    end,
  })
  state.placements[#state.placements + 1] = p
  set_concealcursor(buf, true)
end

---@param buf integer
local function render_later(buf)
  local state = states[buf]
  if not state then
    return
  end
  state.timer = state.timer or assert(vim.uv.new_timer())
  state.timer:stop()
  state.timer:start(
    150,
    0,
    vim.schedule_wrap(function()
      render(buf)
    end)
  )
end

---@param buf integer
local function disable(buf)
  local state = states[buf]
  if not state then
    return
  end
  states[buf] = nil
  if state.timer then
    state.timer:stop()
    state.timer:close()
  end
  close_placements(state)
  pcall(vim.api.nvim_del_augroup_by_name, "svg_preview_" .. buf)
  if vim.api.nvim_buf_is_valid(buf) then
    set_concealcursor(buf, false)
  end
end

---@param buf integer
local function enable(buf)
  states[buf] = { placements = {} }
  local group = vim.api.nvim_create_augroup("svg_preview_" .. buf, { clear = true })
  -- insert 모드에서는 XML 을 보여 준다. 그림을 걷기만 하고 켜진 상태는 유지한다.
  vim.api.nvim_create_autocmd("InsertEnter", {
    group = group,
    buffer = buf,
    callback = function()
      local state = states[buf]
      if state then
        if state.timer then
          state.timer:stop()
        end
        close_placements(state)
        set_concealcursor(buf, false)
      end
    end,
  })
  -- insert 를 나올 때와 normal 모드에서 고쳤을 때 다시 그린다. 둘이 잇따라 와도 debounce 로 한 번만 그린다.
  vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged" }, {
    group = group,
    buffer = buf,
    callback = function()
      render_later(buf)
    end,
  })
  vim.api.nvim_create_autocmd({ "BufUnload", "BufWipeout" }, {
    group = group,
    buffer = buf,
    callback = function()
      disable(buf)
    end,
  })
  render(buf)
end

function M.toggle()
  local buf = vim.api.nvim_get_current_buf()
  if states[buf] then
    disable(buf)
  else
    enable(buf)
  end
end

-- explorer 미리보기: .svg 만 그림으로, 나머지는 snacks 기본(file) 미리보기에 넘긴다.
---@param ctx snacks.picker.preview.ctx
function M.explorer_preview(ctx)
  local path = Snacks.picker.util.path(ctx.item)
  local stat = path and path:lower():match("%.svg$") and vim.uv.fs_stat(path)
  if not (stat and stat.type == "file") then
    return Snacks.picker.preview.file(ctx)
  end
  local src = snapshot(path, "f", stat.mtime.sec * 1000 + math.floor(stat.mtime.nsec / 1e6), function(dst)
    vim.uv.fs_copyfile(path, dst)
  end)
  local buf = ctx.preview:scratch()
  ctx.preview:set_title(vim.fn.fnamemodify(path, ":t"))
  Snacks.image.buf.attach(buf, { src = src })
end

local group = vim.api.nvim_create_augroup("svg_preview", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "svg",
  callback = function(e)
    vim.keymap.set("n", "<leader>cp", M.toggle, { buffer = e.buf, desc = "SVG Preview" })
  end,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = group,
  callback = function()
    local cache = Snacks and Snacks.image and Snacks.image.config.cache
    if not cache then
      return
    end
    for name in pairs(made) do
      for _, file in ipairs(vim.fn.glob(cache .. "/*-" .. name .. ".*", false, true)) do
        vim.uv.fs_unlink(file)
      end
    end
  end,
})

return {
  "folke/snacks.nvim",
  opts = {
    image = {
      enabled = true,
      -- 이미지 모듈을 켜면 기본으로 markdown 등 문서 안의 이미지·수식도 그리기 시작한다.
      -- 여기서는 SVG 미리보기와 이미지 파일 열기만 원해서 끈다. 원하면 true 로.
      doc = { enabled = false },
    },
    picker = {
      sources = {
        explorer = { preview = M.explorer_preview },
      },
    },
  },
}
