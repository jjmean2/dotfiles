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
vim.g.maplocalleader = " "

-- ==================================================
-- 🛠️ 에디터 options & keymaps
-- ==================================================
require_config_with_variants("config.core.options")

-- ==================================================
-- 🔌 플러그인 매니저 초기화
-- ==================================================
require("config.lazy")

-- ==================================================
-- ✨ 플러그인 options & keymaps
-- ==================================================
require_config_with_variants("config.plugin.options")
