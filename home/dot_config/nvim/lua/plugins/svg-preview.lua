-- SVG 를 XML 로 편집하면서 그림으로도 볼 수 있게 한다. 그리는 일은 snacks.image 가 한다
-- (kitty 그래픽 프로토콜: Ghostty 지원, tmux 안에서는 snacks 가 allow-passthrough 를 켠다.
-- SVG → PNG 변환에 ImageMagick 의 magick 이 필요하다. :checkhealth snacks 로 확인).
--
--   <localleader>p  (svg 버퍼) 같은 창에서 XML ↔ 그림을 바꿔 끼운다. 저장 안 한 수정도 보인다.
--                   그림은 켠 순간의 스냅샷이고, 다시 토글하면 새로 그린다.
--   P / <a-p>       (explorer 목록, snacks 기본 키) 미리보기를 켜면 .svg 위에서 그림이 나온다.
--                   explorer 는 sidebar 레이아웃이라 미리보기가 편집 창을 잠시 빌려 쓴다. 디스크 내용이 보인다.
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
--
-- 키: LazyVim 의 localleader 는 \ 다. svg filetype 에는 LazyVim 코어·extras 가 거는 키가 없다.

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

function M.toggle()
  local buf = vim.api.nvim_get_current_buf()

  -- 그림 버퍼에서 누르면 XML 버퍼로 돌아간다. 그림 버퍼는 bufhidden=wipe 라 저절로 지워진다.
  local src_buf = vim.b[buf].svg_preview_of
  if src_buf then
    if vim.api.nvim_buf_is_valid(src_buf) then
      vim.api.nvim_win_set_buf(0, src_buf)
    else
      vim.notify("SVG 원본 버퍼가 이미 닫혔다", vim.log.levels.WARN)
    end
    return
  end

  local path = vim.api.nvim_buf_get_name(buf)
  if path == "" then
    path = "[No Name " .. buf .. "]" -- 해시 재료로만 쓴다
  end
  local src = snapshot(path, "b", vim.api.nvim_buf_get_changedtick(buf), function(dst)
    vim.fn.writefile(vim.api.nvim_buf_get_lines(buf, 0, -1, false), dst)
  end)

  local pbuf = vim.api.nvim_create_buf(false, true) -- unlisted: bufferline·버퍼 피커에 안 나온다
  vim.bo[pbuf].bufhidden = "wipe"
  vim.b[pbuf].svg_preview_of = buf
  vim.keymap.set("n", "<localleader>p", M.toggle, { buffer = pbuf, desc = "SVG: back to XML" })
  vim.api.nvim_win_set_buf(0, pbuf)
  Snacks.image.buf.attach(pbuf, { src = src })
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
    vim.keymap.set("n", "<localleader>p", M.toggle, { buffer = e.buf, desc = "SVG: toggle preview" })
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
