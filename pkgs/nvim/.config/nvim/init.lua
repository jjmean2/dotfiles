--[[
# 섹션 분류 방식
1. 기본 설정
  - 전역/핵심 변수 설정
  - 네이티브 UX 설정 (options, keymaps)
2. 플러그인 초기화 (lazy.nvim)
3. 플러그인 튜닝
  - LSP / Tree-sitter / 자동 완성 설정 (IDE 인프라)
  - UI 테마 및 사용자 편의 플러그인 튜닝

NeoVim에서는 기본 설정을 한 후에 플러그인을 구동시키면,
플러그인에서 기본 설정을 고려하여 동작을 결정하는 경우가 많다고 한다.
따라서 기본 옵션 및 키맵 설정을 하고 나서 플러그인 초기화를 진행하고,
그 이후 플러그인 추가 튜닝을 진행한다.
--]]

-- 전역 namespace를 생성하고, 유틸리티 함수 정의
_G.JwVim = _G.JwVim or {}

--- 중복 등록을 방지하는 안전한 전역 자동 명령(Autocmd) 그룹을 생성/청소합니다.
---
--- @example
---   vim.api.nvim_create_autocmd("BufWritePost", {
---     group = JwVim.augroup("js_format"),
---     pattern = "*.js",
---     callback = function() print("저장됨") end,
---   })
---
--- @param name string 그룹 식별자 (접두사 'JwVim' 뒤에 결합됨)
--- @return number group_id Neovim 내부에서 인식하는 그룹 고유 ID
function JwVim.augroup(name)
  -- autocmd를 반복 정의하더라도 중첩으로 등록되지 않도록 clear = true 설정으로 그룹 생성
  -- autocmd 등록할 때 동일 이름의 그룹을 지정하는 식으로 사용
  return vim.api.nvim_create_augroup("JwVim" .. name, { clear = true })
end

local sysname = (vim.uv or vim.loop).os_uname().sysname
local os_name = sysname and string.lower(sysname)

---@param config_module string @module
local function require_config_with_variants(config_module)
  pcall(require, config_module)
  if os_name then
    pcall(require, config_module .. "_" .. os_name)
  end
  pcall(require, config_module .. "_local")
end

-- ==================================================
-- 🛠️ 전역/핵심 변수 설정
-- ==================================================
vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- ==================================================
-- 🛠️ 에디터 options & keymaps
-- ==================================================
require_config_with_variants("config.core.options")

-- ==================================================
-- 🔌 플러그인 매니저 초기화
-- ==================================================
require("config.lazy")

-- ==================================================
-- ✨ 플러그인 로딩 후 최종 options & keymaps
-- ==================================================
require_config_with_variants("config.plugin.options")
