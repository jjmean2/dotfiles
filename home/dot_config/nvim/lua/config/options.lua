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

-- 철자 검사: 한글(과 한자·가나)은 검사하지 않는다.
-- 'spelllang' 의 특수 값 "cjk" 는 동아시아 문자를 철자 검사 대상에서 빼고, 영어 단어 검사는 그대로 둔다.
-- 이게 없으면 LazyVim 이 markdown·gitcommit 등에서 켜는 spell 이 한글 단어마다 빨간 밑줄을 긋는다.
-- 일시적으로 한글도 검사하려면 :setlocal spelllang-=cjk
vim.opt.spelllang = { "en", "cjk" }
