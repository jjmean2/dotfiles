-- SVG 를 XML 로 편집하면서 그림으로도 볼 수 있게 한다. 그리는 일은 snacks.image 가 한다
-- (kitty 그래픽 프로토콜: Ghostty 지원, tmux 안에서는 snacks 가 allow-passthrough 를 켠다.
-- SVG → PNG 변환에 ImageMagick 의 magick 이 필요하다. :checkhealth snacks 로 확인).
--
-- 모델은 VS Code 의 "Open Preview" 와 같다: 원본(XML) 탭과 프리뷰(그림) 탭이 따로 있고 둘 다 bufferline 에 보인다.
-- 프리뷰는 원본 버퍼마다 하나씩 있는 listed scratch 버퍼다. 원본은 건드리지 않아서 다른 창에서 계속 편집할 수 있고,
-- 프리뷰 버퍼는 수정 불가라 그림 위에서 x·dd 를 눌러도 아무것도 바뀌지 않는다.
--
--   <leader>cp   (svg 버퍼) 프리뷰 탭으로. 없으면 만들고, 있으면 그 탭으로 간다 (버퍼 번호순이라 bufferline 맨 끝).
--                (프리뷰 버퍼) 원본 탭으로.
--   H / L        bufferline 의 보통 탭이라 평소처럼 오간다. 프리뷰 탭은 떠나도 남는다 (bufhidden=hide).
--   프리뷰 버퍼에서
--     + / -      확대 / 축소 (1.25배씩). 창보다 크게는 안 키운다 (그림을 옮겨 보는 기능이 없어서).
--     0          SVG 자체 크기(100%). 창보다 크면 창에 맞춰 줄어든다.
--     =          창에 꽉 차게.
--     i a I A o O  원본 탭으로 가서 그 키대로 insert 에 들어간다. insert 를 나오면 프리뷰 탭으로 돌아온다.
--     q          프리뷰 탭 닫기 (원본 탭으로 간다). <leader>bd 나 bufferline 의 닫기로 닫아도 된다.
--     :w         원본을 저장한다.
--   P / <a-p>    (explorer 목록, snacks 기본 키) 미리보기를 켜면 .svg 위에서 그림이 나온다.
--                explorer 는 sidebar 레이아웃이라 미리보기가 편집 창을 잠시 빌려 쓴다. 디스크 내용이 보인다.
--
-- 원본이 바뀌면(저장 안 해도) 프리뷰를 다시 그린다. 프리뷰 탭이 숨어 있는 동안은 표시만 해 두고 다시 보일 때 그린다.
--
-- 키: <leader>cp 는 LazyVim 의 markdown·typst extra 가 그 filetype 에서 "미리보기" 로 쓰는 키라 같은 뜻으로 맞췄다.
-- 버퍼 로컬로만 걸어서 다른 filetype 의 <leader>cp 와 겹치지 않는다. svg 에는 LazyVim 코어·extras 가 거는 키가 없다.
--
-- 프리뷰 버퍼의 모양: 창 옵션(줄번호·signcolumn 등 끔)은 snacks 가 이미지 버퍼(filetype=image)를 띄운 창에 알아서
-- 적용한다(snacks.image.config.wo). nvim 은 창 옵션을 (창, 버퍼) 쌍으로 기억하므로 원본 탭으로 돌아가면 원본 옵션이
-- 돌아온다. 커서는 프리뷰 버퍼에 있는 동안 'guicursor' 의 normal·visual 모드를 blend=100 하이라이트로 바꿔 숨긴다.
--
-- bufferline 표시: 이름은 svg-preview://<원본 경로> 라서 꼬리(파일 이름)와 아이콘이 원본과 같다. 꼬리가 같은 탭이
-- 둘이면 bufferline 이 둘 다에 디렉터리를 붙여 구분하므로, name_formatter 로 프리뷰 이름 뒤에 󰋩 를 붙여 구분한다.
--
-- 세션: LazyVim 의 sessionoptions 에 buffers 가 있어서 listed 버퍼가 세션에 들어간다. 프리뷰가 세션에 들어가면 복원 때
-- 빈 버퍼가 생기므로, persistence.nvim 이 저장하는 동안(PersistenceSavePre~Post) 프리뷰를 unlisted 로 돌려 둔다.
--
-- 확대/축소: 복사본의 루트 <svg> 의 width·height 를 배율만큼 바꿔(viewBox 가 없으면 원래 크기로 넣어) 다시 그린다.
--   PNG 를 늘리는 게 아니라 SVG 를 다시 그리므로 키워도 흐려지지 않는다. snacks 는 그림을 원래 크기보다 키우지 않고
--   창보다 크면 줄이므로, 이렇게 SVG 자체 크기를 바꾸는 것이 확대하는 유일한 길이다.
--   width·height 가 %·em 처럼 절대 길이가 아니고 viewBox 도 없으면 크기를 몰라서 확대/축소를 못 한다.
--
-- snacks.image 의 opts.formats 에 svg 를 넣지 않는 이유: formats 의 확장자는 BufReadCmd 가 가로채
-- 항상 수정 불가 이미지 버퍼로 열어서, XML 을 편집할 수 없게 된다.
--
-- 복사본을 그리는 이유: snacks 는 변환한 PNG 를 원본 경로의 해시로만 캐시하고 수정 시각을 보지 않아서,
-- 원본을 그대로 넘기면 수정 전 그림이 나온다. 그래서 내용이 바뀔 때마다 이름이 다른 복사본을 만들어 넘긴다.
--   이름   <원본 경로 해시 8자>-<종류><버전>.svg
--          (b = 버퍼 내용, 버전은 changedtick 과 배율 / f = 디스크 파일, 버전은 mtime)
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
---@param version string|integer 파일 이름에 들어가므로 점(.)이 없어야 한다
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

-- 변환하는 동안 snacks 가 띄운 "convert loading …" 표시를 지운다. snacks 의 progress() 는 이 extmark 를
-- placement 가 관리하는 목록(eids)에 넣지 않고, 변환이 끝나면 타이머만 멈춰서 글자가 그림 옆에 계속 남는다.
-- 같은 namespace 에서 placement 가 관리하지 않는 extmark 를 지운다.
---@param p snacks.image.Placement
local function clear_progress(p)
  if not vim.api.nvim_buf_is_valid(p.buf) then
    return
  end
  local ns = vim.api.nvim_create_namespace("snacks.image") -- 이미 있으면 같은 id 를 돌려준다
  local own = {} ---@type table<integer, true>
  for _, id in ipairs(p.eids or {}) do
    own[id] = true
  end
  for _, m in ipairs(vim.api.nvim_buf_get_extmarks(p.buf, ns, 0, -1, {})) do
    if not own[m[1]] then
      vim.api.nvim_buf_del_extmark(p.buf, ns, m[1])
    end
  end
end

-- buf 에 src(SVG) 그림을 붙인다. Snacks.image.buf.attach 와 같은 일을 하되 형식 검사를 건너뛴다.
-- attach 는 opts.formats 에 확장자가 없으면 그리지 않고 "unsupported image format" 안내를 띄우는데,
-- svg 는 위에 적은 이유로 formats 에 넣지 않았다. 변환(magick)은 placement 가 확장자와 상관없이 해 준다.
-- 터미널이 그림을 못 그리면 attach 에 넘겨 그 안내를 그대로 보여 준다.
---@param buf integer
---@param src string
---@param opts? snacks.image.Opts
local function attach(buf, src, opts)
  if Snacks.image.config.enabled == false then
    return
  end
  require("snacks.image.terminal").detect(function()
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    if not Snacks.image.supports_terminal() then
      return Snacks.image.buf.attach(buf, { src = src })
    end
    Snacks.image.placement.clean(buf)
    Snacks.util.bo(buf, { filetype = "image", modifiable = false, modified = false, swapfile = false })
    opts = opts or {}
    local on_update = opts.on_update
    local p = Snacks.image.placement.new(
      buf,
      src,
      vim.tbl_extend("force", opts, {
        conceal = true,
        auto_resize = true,
        on_update = function(pl)
          clear_progress(pl)
          if on_update then
            on_update(pl)
          end
        end,
      })
    )
    -- snacks 는 창에서 사라질 때 hide() 로 hidden 을 켜지만 다시 보일 때 show() 를 부르지 않는다
    -- (placement.lua 의 update). hidden 인 채로는 그림 칸을 빈 문자열로 그려서, 탭을 갔다 오면 그림이 사라진다.
    -- 버퍼가 창에 다시 올라오면 show() 로 풀어 준다. augroup 은 placement 가 닫힐 때 함께 지워진다.
    vim.api.nvim_create_autocmd("BufWinEnter", {
      group = p.augroup,
      buffer = buf,
      callback = function()
        vim.schedule(function()
          if not p.closed then
            p:show()
          end
        end)
      end,
    })
  end)
end

-- 루트 <svg> 크기 ---------------------------------------------------------------------------------------------

local px_per = { [""] = 1, px = 1, pt = 4 / 3, pc = 16, mm = 96 / 25.4, cm = 96 / 2.54, ["in"] = 96 }

---@param v? string
---@return number? px
local function length(v)
  local n, unit = (v or ""):match("^%s*([%d%.]+)%s*(%a*)%s*$")
  local k = unit and px_per[unit]
  return n and k and tonumber(n) and tonumber(n) * k or nil
end

---@class svg_preview.Root
---@field s integer 루트 태그 시작 위치
---@field e integer 루트 태그 끝(>) 위치
---@field tag string
---@field w number 기본 크기(px)
---@field h number
---@field viewbox boolean

---@param text string
---@return svg_preview.Root?
local function parse_root(text)
  local s = text:find("<svg[%s/>]")
  local e = s and text:find(">", s, true)
  if not e then
    return
  end
  local tag = text:sub(s, e)
  local function attr(name)
    return tag:match("%s" .. name .. '%s*=%s*"([^"]*)"') or tag:match("%s" .. name .. "%s*=%s*'([^']*)'")
  end
  local w, h = length(attr("width")), length(attr("height"))
  local vb = {} ---@type number[]
  for n in (attr("viewBox") or ""):gmatch("[^%s,]+") do
    vb[#vb + 1] = tonumber(n)
  end
  local vw, vh = vb[3], vb[4]
  local has_vb = vw and vh and vw > 0 and vh > 0 or false
  if not (w and h) then
    if not has_vb then
      return
    end
    if w then
      h = w * vh / vw
    elseif h then
      w = h * vw / vh
    else
      w, h = vw, vh
    end
  end
  if w <= 0 or h <= 0 then
    return
  end
  return { s = s, e = e, tag = tag, w = w, h = h, viewbox = has_vb }
end

-- 루트 <svg> 의 width·height 를 zoom 배로 바꾼 텍스트를 돌려준다.
---@param text string
---@param root svg_preview.Root
---@param zoom number
local function scale_svg(text, root, zoom)
  local tag = root.tag
  for _, name in ipairs({ "width", "height" }) do
    tag = tag:gsub("%s+" .. name .. "%s*=%s*([\"']).-%1", "", 1)
  end
  local extra = (' width="%.3f" height="%.3f"'):format(root.w * zoom, root.h * zoom)
  if not root.viewbox then
    -- viewBox 가 없으면 사용자 단위가 px 라서, 원래 크기를 viewBox 로 넣어야 내용도 함께 커진다.
    extra = extra .. (' viewBox="0 0 %.3f %.3f"'):format(root.w, root.h)
  end
  tag = tag:gsub("^<svg", "<svg" .. extra, 1)
  return text:sub(1, root.s - 1) .. tag .. text:sub(root.e + 1)
end

-- 프리뷰 버퍼 ---------------------------------------------------------------------------------------------------

---@class svg_preview.Preview
---@field buf integer 프리뷰 버퍼
---@field src integer 원본 버퍼
---@field zoom number SVG 자체 크기 대비 배율
---@field root? svg_preview.Root 마지막으로 읽은 루트 <svg> (없으면 확대/축소 불가)
---@field natural? { width: integer, height: integer, zoom: number } 그 배율에서 snacks 가 창에 맞춰 줄이기 전 크기(칸)
---@field file? string 마지막으로 그린 복사본
---@field dirty? boolean 숨어 있는 동안 원본이 바뀌었다
---@field timer? uv.uv_timer_t 다시 그리기 debounce
---@field return_after_insert? boolean i·a·o 로 원본에 갔으니 insert 를 나오면 돌아온다

local by_src = {} ---@type table<integer, svg_preview.Preview>
local by_buf = {} ---@type table<integer, svg_preview.Preview>

---@param pv svg_preview.Preview
local function visible(pv)
  return #vim.fn.win_findbuf(pv.buf) > 0
end

-- 지금 원본 내용과 배율로 그림을 그린다.
---@param pv svg_preview.Preview
local function render(pv)
  if not (vim.api.nvim_buf_is_valid(pv.buf) and vim.api.nvim_buf_is_valid(pv.src)) then
    return
  end
  pv.dirty = false
  local path = vim.api.nvim_buf_get_name(pv.src)
  if path == "" then
    path = "[No Name " .. pv.src .. "]" -- 해시 재료로만 쓴다
  end
  local text = table.concat(vim.api.nvim_buf_get_lines(pv.src, 0, -1, false), "\n")
  pv.root = parse_root(text)
  local zoom = pv.root and pv.zoom or 1
  local version = vim.api.nvim_buf_get_changedtick(pv.src) .. "z" .. math.floor(zoom * 1000 + 0.5)
  local file = snapshot(path, "b", version, function(dst)
    vim.fn.writefile(vim.split(zoom == 1 and text or scale_svg(text, pv.root, zoom), "\n"), dst)
  end)
  if file == pv.file then
    return
  end
  pv.file = file
  -- attach 는 이전 그림을 닫고 새로 그린다 (변환하는 동안 스피너가 잠깐 보인다).
  attach(pv.buf, file, {
    on_update = function(p)
      if by_buf[pv.buf] ~= pv or p.img.src ~= file or not p.img.info then
        return
      end
      -- 창에 맞추느라 줄기 전 크기. 확대 한도(창에 꽉 찬 배율)를 계산할 때 쓴다.
      local nat = Snacks.image.util.fit(p.img.file, { width = 100000, height = 100000 }, { info = p.img.info })
      pv.natural = { width = nat.width, height = nat.height, zoom = zoom }
    end,
  })
end

---@param pv svg_preview.Preview
local function render_later(pv)
  pv.timer = pv.timer or assert(vim.uv.new_timer())
  pv.timer:stop()
  pv.timer:start(
    150,
    0,
    vim.schedule_wrap(function()
      if by_buf[pv.buf] == pv then
        render(pv)
      end
    end)
  )
end

-- 원본이 바뀌었다. 보이면 곧 다시 그리고, 숨어 있으면 다시 보일 때 그린다.
---@param pv svg_preview.Preview
local function invalidate(pv)
  if visible(pv) then
    render_later(pv)
  else
    pv.dirty = true
  end
end

-- 창에 꽉 차는 배율. 아직 한 번도 그리지 못했으면 nil.
---@param pv svg_preview.Preview
local function fit_zoom(pv)
  local nat = pv.natural
  if not nat then
    return
  end
  local w, h = math.huge, math.huge
  for _, win in ipairs(vim.fn.win_findbuf(pv.buf)) do
    w = math.min(w, vim.api.nvim_win_get_width(win))
    h = math.min(h, vim.api.nvim_win_get_height(win))
  end
  if w == math.huge then
    return
  end
  return nat.zoom * math.min(w / nat.width, h / nat.height)
end

---@param pv svg_preview.Preview
---@param how "in"|"out"|"reset"|"fit"
local function zoom(pv, how)
  if not pv.root then
    vim.notify("루트 <svg> 의 크기(width·height 또는 viewBox)를 읽지 못해 확대/축소를 못 한다", vim.log.levels.WARN)
    return
  end
  local fit = fit_zoom(pv) or math.huge
  local cur = math.min(pv.zoom, fit)
  local z = how == "in" and cur * 1.25 or how == "out" and cur / 1.25 or how == "reset" and 1 or fit
  if z == math.huge then
    return -- 아직 그리는 중
  end
  -- 창보다 크게는 안 키우고, 너무 크거나 작은 PNG 는 만들지 않는다.
  z = math.min(z, fit, 4096 / math.max(pv.root.w, pv.root.h))
  z = math.max(z, 0.05, 8 / math.max(pv.root.w, pv.root.h))
  local shown = math.floor(math.min(z, fit) * 100 + 0.5)
  vim.api.nvim_echo({ { ("SVG %d%%"):format(shown) .. (z >= fit and " (창에 꽉 참)" or "") } }, false, {})
  if math.abs(z - pv.zoom) > 1e-6 then
    pv.zoom = z
    render(pv)
  end
end

-- 커서 숨기기 (guicursor 는 전역이라 프리뷰 버퍼를 드나들 때 켜고 끈다) --
local saved_guicursor ---@type string? 숨기는 동안 원래 값

local function update_cursor()
  local want = by_buf[vim.api.nvim_get_current_buf()] ~= nil
  if want and not saved_guicursor then
    vim.api.nvim_set_hl(0, "SvgPreviewHiddenCursor", { blend = 100, nocombine = true })
    saved_guicursor = vim.go.guicursor
    vim.go.guicursor = saved_guicursor .. (saved_guicursor == "" and "" or ",") .. "n-v-sm:SvgPreviewHiddenCursor"
  elseif not want and saved_guicursor then
    vim.go.guicursor = saved_guicursor
    saved_guicursor = nil
  end
end

-- 현재 창을 원본 탭으로 바꾼다. 원본이 이미 없으면 false.
---@param pv svg_preview.Preview
---@param quiet? boolean
local function goto_src(pv, quiet)
  if not vim.api.nvim_buf_is_valid(pv.src) then
    if not quiet then
      vim.notify("SVG 원본 버퍼가 이미 닫혔다", vim.log.levels.WARN)
    end
    return false
  end
  vim.api.nvim_win_set_buf(0, pv.src)
  return true
end

---@param pv svg_preview.Preview
local function close(pv)
  if vim.api.nvim_get_current_buf() == pv.buf then
    goto_src(pv, true)
  end
  if vim.api.nvim_buf_is_valid(pv.buf) then
    vim.api.nvim_buf_delete(pv.buf, { force = true })
  end
end

---@param pv svg_preview.Preview
local function set_keys(pv)
  local function map(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { buffer = pv.buf, nowait = true, desc = desc })
  end
  for lhs, how in pairs({ ["+"] = "in", ["-"] = "out", ["0"] = "reset", ["="] = "fit" }) do
    map(lhs, function()
      zoom(pv, how)
    end, "SVG: zoom " .. how)
  end
  map("q", function()
    close(pv)
  end, "SVG: close preview")
  map("<leader>cp", function()
    goto_src(pv)
  end, "SVG Source")
  for _, key in ipairs({ "i", "a", "I", "A", "o", "O" }) do
    map(key, function()
      if goto_src(pv) then
        pv.return_after_insert = true
        vim.api.nvim_feedkeys(key, "n", false)
      end
    end, "SVG: edit (" .. key .. ")")
  end
end

---@param src integer
local function create(src)
  local path = vim.api.nvim_buf_get_name(src)
  local buf = vim.api.nvim_create_buf(true, true) -- listed scratch: bufferline 에 탭으로 보인다
  local name = "svg-preview://" .. (path ~= "" and path or "[No Name " .. src .. "]")
  if not pcall(vim.api.nvim_buf_set_name, buf, name) then
    vim.api.nvim_buf_set_name(buf, name .. " (" .. buf .. ")") -- 같은 이름의 버퍼가 남아 있다 (E95)
  end
  vim.bo[buf].buftype = "acwrite" -- :w 를 BufWriteCmd 로 받아 원본을 저장한다
  vim.b[buf].svg_preview_of = src

  ---@type svg_preview.Preview
  local pv = { buf = buf, src = src, zoom = 1 }
  by_src[src], by_buf[buf] = pv, pv
  set_keys(pv)

  local group = vim.api.nvim_create_augroup("svg_preview_" .. buf, { clear = true })
  local function on(events, fn, opts)
    vim.api.nvim_create_autocmd(events, vim.tbl_extend("force", { group = group, callback = fn }, opts or {}))
  end
  on("BufWriteCmd", function()
    vim.api.nvim_buf_call(src, function()
      vim.cmd("write")
    end)
    vim.bo[buf].modified = false
  end, { buffer = buf })
  on("BufWinEnter", function()
    if pv.dirty then
      render(pv)
    end
  end, { buffer = buf })
  on({ "TextChanged", "TextChangedI", "TextChangedP" }, function()
    invalidate(pv)
  end, { buffer = src })
  -- i·a·o 로 원본에 갔다가 insert 를 나오면 돌아온다. 원본 탭에서 보통으로 편집하는 insert 에는 반응하지 않는다.
  on("InsertLeave", function()
    if pv.return_after_insert then
      pv.return_after_insert = false
      if vim.api.nvim_get_current_buf() == src and vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_win_set_buf(0, buf)
      end
    end
  end, { buffer = src })
  on("BufLeave", function()
    pv.return_after_insert = false
  end, { buffer = src })
  -- 원본이 닫히면 프리뷰도 닫는다 (BufWipeout 안에서 다른 버퍼를 지우면 안 되어 schedule).
  on("BufWipeout", function()
    vim.schedule(function()
      if by_buf[buf] == pv then
        close(pv)
      end
    end)
  end, { buffer = src })
  on("BufWipeout", function()
    by_buf[buf] = nil
    if by_src[src] == pv then
      by_src[src] = nil
    end
    if pv.timer then
      pv.timer:close()
    end
    pcall(vim.api.nvim_del_augroup_by_id, group)
    vim.schedule(update_cursor)
  end, { buffer = buf })

  render(pv)
  return pv
end

-- <leader>cp: 원본에서는 프리뷰 탭으로, 프리뷰에서는 원본 탭으로.
function M.toggle()
  local cur = vim.api.nvim_get_current_buf()
  local pv = by_buf[cur]
  if pv then
    goto_src(pv)
    return
  end
  pv = by_src[cur]
  if not (pv and vim.api.nvim_buf_is_valid(pv.buf)) then
    pv = create(cur)
  end
  vim.api.nvim_win_set_buf(0, pv.buf)
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
  attach(buf, src)
end

local group = vim.api.nvim_create_augroup("svg_preview", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "svg",
  callback = function(e)
    vim.keymap.set("n", "<leader>cp", M.toggle, { buffer = e.buf, desc = "SVG Preview" })
  end,
})

vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
  group = group,
  callback = function()
    vim.schedule(update_cursor)
  end,
})

-- 세션에 프리뷰 버퍼가 들어가지 않게, persistence 가 저장하는 동안만 unlisted 로.
vim.api.nvim_create_autocmd("User", {
  group = group,
  pattern = { "PersistenceSavePre", "PersistenceSavePost" },
  callback = function(e)
    for buf in pairs(by_buf) do
      if vim.api.nvim_buf_is_valid(buf) then
        vim.bo[buf].buflisted = e.match == "PersistenceSavePost"
      end
    end
  end,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  group = group,
  callback = function()
    if saved_guicursor then
      vim.go.guicursor = saved_guicursor
    end
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
  {
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
  },
  {
    "akinsho/bufferline.nvim",
    optional = true,
    opts = function(_, opts)
      opts.options = opts.options or {}
      local inner = opts.options.name_formatter
      -- 프리뷰 탭 이름 뒤에 󰋩 를 붙인다. 원본 탭과 꼬리가 달라져 bufferline 이 디렉터리를 덧붙이지 않는다.
      opts.options.name_formatter = function(b)
        local name = inner and inner(b) or b.name
        return vim.b[b.bufnr].svg_preview_of and name .. " 󰋩" or name
      end
    end,
  },
}
