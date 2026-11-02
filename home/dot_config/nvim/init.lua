--[[
# 섹션 분류 방식
1. 기본 설정
  - 전역/핵심 변수 설정
  - 네이티브 options (config/core/options.lua)
2. 플러그인 초기화 (lazy.nvim, lua/plugins/*.lua 스펙)
3. 플러그인 로딩 후 설정
  - colorscheme, 진단 표시 (config/plugin/options.lua)
  - 모든 키맵 (config/keymaps.lua) — 플러그인 명령을 참조할 수 있도록 마지막에 로드

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

--- 설정 모듈을 로드한다. 실패를 조용히 넘기지 않는다.
---
--- pcall 로 감싸는 이유는 한 모듈의 오류가 init.lua 의 나머지 로드를 막지 않게 하기
--- 위해서이고, 오류를 버리기 위해서가 아니다. 모듈이 "없는" 경우만 선택적(optional)
--- 모듈에 한해 조용히 넘기고, 모듈 안에서 난 오류(문법 오류, 잘못된 keymap 옵션 등)는
--- 항상 vim.notify 로 알린다. 그렇지 않으면 keymaps.lua 의 오타 하나로 모든 키맵이
--- 아무 메시지 없이 사라진다.
---
---@param config_module string 모듈 이름
---@param optional boolean 모듈이 없어도 되는지 (_darwin, _local 같은 변형 파일)
local function try_require(config_module, optional)
  local ok, err = pcall(require, config_module)
  if ok then
    return
  end
  local not_found = tostring(err):find("module '" .. config_module .. "' not found", 1, true)
  if optional and not_found then
    return
  end
  vim.notify(("설정 모듈 로드 실패: %s\n%s"):format(config_module, err), vim.log.levels.ERROR)
end

--- 기본 모듈과 그 변형(_<os>, _local)을 순서대로 로드한다. 기본 모듈은 필수, 변형은 선택.
---@param config_module string @module
local function require_config_with_variants(config_module)
  try_require(config_module, false)
  if os_name then
    try_require(config_module .. "_" .. os_name, true)
  end
  try_require(config_module .. "_local", true)
end

-- ==================================================
-- 🛠️ 전역/핵심 변수 설정
-- ==================================================
vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- ==================================================
-- 🛠️ 에디터 options
-- ==================================================
require_config_with_variants("config.core.options")
require_config_with_variants("config.core.autocmds")

-- ==================================================
-- 🔌 플러그인 매니저 초기화
-- ==================================================
require("config.lazy")

-- ==================================================
-- ✨ 플러그인 로딩 후 options
-- ==================================================
require_config_with_variants("config.plugin.options")

-- ==================================================
-- ⌨️  키맵 (순정 보강 + 플러그인 키 전부)
-- ==================================================
require_config_with_variants("config.keymaps")
