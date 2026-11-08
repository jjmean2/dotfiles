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
local project_patterns = {
  "~/dev/jwlee/*",
  "~/dev/opensources/*",
  "~/dev/opensources/@forked/*",
  "~/dev/playground/*/*",
  "~/dev/workspaces/*/*",
}

local dev = {}
for _, pattern in ipairs(project_patterns) do
  local parent = pattern:gsub("/%*$", "")
  for _, dir in ipairs(vim.fn.glob(parent, false, true)) do
    if vim.fn.isdirectory(dir) == 1 then
      dev[#dev + 1] = dir
    end
  end
end

return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        projects = { dev = dev },
      },
    },
  },
}
