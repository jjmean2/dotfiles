-- neotest 어댑터. test.core extra 는 neotest 만 깔고 어댑터는 비워 두므로 테스트 러너마다 여기에 더한다.
--
-- 어댑터는 모든 머신·모든 프로젝트에 깔아 두어도 된다. 어댑터가 스스로 자기 프로젝트인지 보고 맞을 때만 붙는다.
--   neotest-vitest: 테스트 파일 이름(*.test.ts 등) 이면서 가까운 package.json (또는 cwd 의 package.json,
--                   모노레포 루트) 의 dependencies/devDependencies 에 vitest 가 있을 때만 그 파일을 맡는다.
-- 그래서 jest 프로젝트를 열어도 vitest 로 돌지 않는다. jest 가 필요해지면 "nvim-neotest/neotest-jest" 를
-- dependencies 에 더하고 adapters 에 ["neotest-jest"] = {} 를 넣으면 된다 (각자 자기 프로젝트만 맡는다).
--
-- 프로젝트마다 달라야 하는 것 (vitest 실행 명령, 설정 파일 경로 등) 은 여기서 정하지 않고 그 프로젝트의
-- .lazy.lua 에서 opts 를 덮어쓴다 (docs/tool-scope.md 의 D):
--   return { { "nvim-neotest/neotest", opts = { adapters = { ["neotest-vitest"] = {
--     vitestCommand = "pnpm vitest", vitestConfigFile = "vitest.workspace.ts" } } } } }
--
-- 키: <leader>tr 커서의 테스트, <leader>tt 파일, <leader>ts 요약 창, <leader>to 출력, <leader>tw 감시 모드,
--     <leader>td 커서의 테스트를 디버거로 (dap.core extra. vitest 는 lang.typescript 의 js-debug-adapter 를 쓴다)
return {
  {
    "nvim-neotest/neotest",
    dependencies = { "marilari88/neotest-vitest" },
    opts = {
      adapters = {
        -- {} 이면 LazyVim 이 require("neotest-vitest") 를 그대로 쓴다 (기본 설정).
        ["neotest-vitest"] = {},
      },
    },
  },
}
