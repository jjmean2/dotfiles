-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- 인코딩: 한글 레거시 파일(cp949 / EUC-KR)을 latin1 보다 먼저 시도한다.
-- 'fileencodings' 는 파일을 읽을 때 앞에서부터 시도해 오류 없이 읽히는 첫 인코딩을 쓴다.
-- 기본값은 "ucs-bom,utf-8,default,latin1" 이라 UTF-8 이 아닌 한글 파일이 latin1 로 읽혀 깨져
-- 보인다. latin1 은 어떤 바이트열이든 읽히므로 맨 뒤에 두어야 한다. LazyVim 은 이 옵션을 건드리지 않는다.
-- 읽힌 인코딩은 :set fenc? 로 확인한다. 저장도 그 인코딩으로 하므로 원본 인코딩이 유지된다.
vim.opt.fileencodings:remove("latin1")
vim.opt.fileencodings:append({ "cp949", "latin1" })
