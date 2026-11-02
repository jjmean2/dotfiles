-- ==================================================
-- 🧭 statusline (순정, 플러그인 없음). :h 'statusline'
-- ==================================================
-- 멘탈 모델: statusline 옵션은 printf 비슷한 포맷 문자열 하나다. nvim 이 화면을 그릴 때마다
-- 그 문자열을 평가해 창 아래 한 줄을 만든다. "%!함수()" 로 두면 함수가 돌려준 문자열을
-- 포맷으로 쓰므로, 상황에 따라 항목을 넣고 뺄 수 있다.
--
-- 쓰는 항목 (:h 'statusline' 의 표)
--   %f 경로  %m 수정됨[+]  %r 읽기전용  %y 파일형식  %l:%c 줄:열  %p%% 위치 퍼센트
--   %<  너무 길면 여기서부터 자른다   %=  여기부터 오른쪽 정렬   %#그룹#...%*  색 바꾸기/되돌리기
--
-- 플러그인은 값을 "제공" 만 한다. gitsigns 가 b:gitsigns_head(브랜치)와 b:gitsigns_status
-- (+추가 ~변경 -삭제 개수)를 버퍼 변수로 두고, 진단과 LSP 이름은 nvim API 에서 읽는다.
-- 그래서 플러그인이 없어도 그 항목만 비고 나머지는 그대로 나온다.
--
-- 결과 예:  home/dot_config/nvim/init.lua [+]  main +3 ~1        E1 W2  lua_ls  [lua] 42:7 35%

-- 포맷 문자열에서 % 는 항목 표시라, 브랜치 이름 같은 외부 값에 든 % 는 %% 로 피한다.
local function esc(s)
  return (tostring(s):gsub("%%", "%%%%"))
end

function JwVim.statusline()
  local parts = {}

  -- [왼쪽] 경로와 상태 플래그
  parts[#parts + 1] = " %<%f %m%r"

  -- git: 브랜치와 hunk 개수 (gitsigns 가 붙은 버퍼에만 있음)
  local head = vim.b.gitsigns_head
  if head and head ~= "" then
    parts[#parts + 1] = "  %#Directory#" .. esc(head) .. "%*"
    local st = vim.b.gitsigns_status
    if st and st ~= "" then
      parts[#parts + 1] = " " .. esc(st)
    end
  end

  parts[#parts + 1] = "%="

  -- [오른쪽] 진단 개수: 심각도별로 색을 입혀 "E1 W2 I0 H0" 중 0 이 아닌 것만
  local counts = vim.diagnostic.count(0)
  local sev = vim.diagnostic.severity
  for _, item in ipairs({
    { sev.ERROR, "E", "DiagnosticError" },
    { sev.WARN, "W", "DiagnosticWarn" },
    { sev.INFO, "I", "DiagnosticInfo" },
    { sev.HINT, "H", "DiagnosticHint" },
  }) do
    local n = counts[item[1]]
    if n and n > 0 then
      parts[#parts + 1] = " %#" .. item[3] .. "#" .. item[2] .. n .. "%*"
    end
  end

  -- 붙은 LSP 서버 이름
  local names = {}
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    names[#names + 1] = client.name
  end
  if #names > 0 then
    parts[#parts + 1] = "  " .. esc(table.concat(names, ","))
  end

  -- 파일 형식, 위치
  parts[#parts + 1] = "  %y %l:%c %p%% "

  return table.concat(parts)
end

-- 3: 창이 여러 개여도 맨 아래에 statusline 하나만 (VS Code 처럼). %! 는 현재 창 기준으로
-- 평가되므로 "지금 커서가 있는 창" 의 정보가 나온다. 2 로 바꾸면 창마다 하나씩이다.
vim.o.laststatus = 3
vim.o.statusline = "%!v:lua.JwVim.statusline()"
