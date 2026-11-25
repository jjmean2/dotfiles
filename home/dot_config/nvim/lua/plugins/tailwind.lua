-- Tailwind IntelliSense(자동완성, 호버, 색상 표시)를 className 속성 밖의 문자열에도 켠다.
--
-- LazyVim lang.tailwind extra 의 tailwindcss 서버 설정에 아래 두 가지를 더한다 (opts 는 깊게 병합된다).
--   classFunctions  cn(...), clsx(...), cva(...), tw`...` 의 인자. tw 는 IntelliSense 와
--                   prettier-plugin-tailwindcss 정렬만을 위한 identity 헬퍼를 쓰는 프로젝트용.
--   classRegex      fooClasses = "...", fooClasses: '...' 처럼 이름이 Classes 로 끝나는 상수나
--                   객체 프로퍼티. 캡처 그룹 1 이 클래스 목록이다. ${} 보간이 있으면 그 앞까지만 인식된다.
--
-- 설정을 바꾼 뒤에는 :LspRestart tailwindcss 로 다시 띄운다.
-- classFunctions 는 비교적 최근 language server 에만 있으니 안 되면 :MasonUpdate 로 올린다.
return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      tailwindcss = {
        settings = {
          tailwindCSS = {
            classFunctions = { "cn", "clsx", "cva", "tw" },
            experimental = {
              classRegex = {
                [==[\b\w*Classes\s*[:=]\s*["'`]([^"'`]*)["'`]]==],
              },
            },
          },
        },
      },
    },
  },
}
