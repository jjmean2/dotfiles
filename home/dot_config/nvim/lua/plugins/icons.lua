-- Node·프론트엔드 생태계 파일 아이콘.
--
-- LazyVim 은 아이콘을 mini.icons 로 받고 nvim-web-devicons 는 mini.icons 로 흉내 낸다(mock). 그래서
-- 플러그인이 devicons 를 찾아도 답은 mini.icons 표에서 나온다. mini.icons 는 파일 이름 → 확장자 →
-- vim.filetype.match() 순으로 찾는데, 파일 이름 표가 작아서 pnpm-lock.yaml 은 YAML, vite.config.ts 는
-- TypeScript, yarn.lock·.yarnrc·bun.lockb 는 기본 아이콘으로 끝난다. 여기서 파일 이름 표에 더한다.
-- lazy.nvim 이 opts 를 LazyVim 기본값과 병합하므로 LazyVim 이 넣은 항목은 그대로 남는다.
--
-- 글리프는 Nerd Font 문자다(플러그인이 아니라 폰트에 들어 있다). 코드포인트는 nerd-fonts 의
-- glyphnames.json 이름으로 적었다. Ghostty 1.4 에 내장된 Symbols Nerd Font 에 없는 것(dev-biome,
-- dev-turbo, dev-nuxt 등 3.4 이후 글리프)은 쓰지 않는다. 확인: ghostty +show-face --cp=0xE865
-- 색은 mini.icons 의 MiniIcons* 그룹으로만 고른다(색 테마가 그 그룹을 칠한다).

local cp = vim.fn.nr2char
local g = {
  node = cp(0xE718), -- dev-nodejs_small
  npm = cp(0xE71E), -- dev-npm
  pnpm = cp(0xE865), -- dev-pnpm
  yarn = cp(0xE8EC), -- dev-yarn
  bun = cp(0xE76F), -- dev-bun
  deno = cp(0xE7C0), -- dev-denojs
  ts = cp(0xF06E6), -- md-language_typescript (mini.icons 의 TypeScript 와 같은 글리프)
  vite = cp(0xE8D7), -- dev-vitejs
  vitest = cp(0xE8D9), -- dev-vitest
  next = cp(0xE83E), -- dev-nextjs
  nuxt = cp(0xF1106), -- md-nuxt
  svelte = cp(0xE697), -- seti-svelte
  astro = cp(0xE735), -- dev-astro
  tailwind = cp(0xE8BA), -- dev-tailwindcss
  postcss = cp(0xE86A), -- dev-postcss
  babel = cp(0xE75D), -- dev-babel
  webpack = cp(0xE8E3), -- dev-webpack
  rollup = cp(0xE892), -- dev-rollup
  eslint = cp(0xE7D2), -- dev-eslint
  prettier = cp(0xE6B4), -- custom-prettier
  jest = cp(0xE807), -- dev-jest
  playwright = cp(0xE863), -- dev-playwright
  cypress = cp(0xE7B9), -- dev-cypressio
  storybook = cp(0xE8B3), -- dev-storybook
  vercel = cp(0xE8D3), -- dev-vercel
  netlify = cp(0xE83C), -- dev-netlify
  markdown = cp(0xF0354), -- md-language_markdown (mini.icons 의 Markdown 과 같은 글리프)
}

local file = {}

local function add(names, glyph, hl)
  for _, name in ipairs(names) do
    file[name] = { glyph = glyph, hl = hl }
  end
end

-- name.config.{js,ts,...} 처럼 확장자만 다른 설정 파일 묶음.
local config_exts = { "js", "mjs", "cjs", "ts", "mts", "cts" }
local function add_config(bases, glyph, hl)
  local names = {}
  for _, base in ipairs(bases) do
    for _, ext in ipairs(config_exts) do
      names[#names + 1] = base .. "." .. ext
    end
  end
  add(names, glyph, hl)
end

-- 런타임·패키지 매니저
add({ "package.json", ".nvmrc", ".node-version" }, g.node, "MiniIconsGreen")
add({ "package-lock.json", "npm-shrinkwrap.json", ".npmrc", ".npmignore" }, g.npm, "MiniIconsRed")
add({ "pnpm-lock.yaml", "pnpm-workspace.yaml", ".pnpmfile.cjs", ".pnpmfile.mjs" }, g.pnpm, "MiniIconsYellow")
add({ "yarn.lock", ".yarnrc", ".yarnrc.yml" }, g.yarn, "MiniIconsAzure")
add({ "bun.lock", "bun.lockb", "bunfig.toml" }, g.bun, "MiniIconsOrange")
add({ "deno.json", "deno.jsonc", "deno.lock" }, g.deno, "MiniIconsGrey")

-- TypeScript 설정
add({ "tsconfig.json", "jsconfig.json", "tsconfig.base.json", "tsconfig.build.json" }, g.ts, "MiniIconsAzure")
add({ "tsconfig.app.json", "tsconfig.node.json", "tsconfig.test.json" }, g.ts, "MiniIconsAzure")

-- 번들러·프레임워크
add_config({ "vite.config" }, g.vite, "MiniIconsPurple")
add_config({ "vitest.config", "vitest.workspace" }, g.vitest, "MiniIconsGreen")
add_config({ "next.config" }, g.next, "MiniIconsGrey")
add_config({ "nuxt.config" }, g.nuxt, "MiniIconsGreen")
add_config({ "svelte.config" }, g.svelte, "MiniIconsOrange")
add_config({ "astro.config" }, g.astro, "MiniIconsOrange")
add_config({ "webpack.config" }, g.webpack, "MiniIconsAzure")
add_config({ "rollup.config" }, g.rollup, "MiniIconsRed")
add_config({ "babel.config" }, g.babel, "MiniIconsYellow")
add({ ".babelrc", ".babelrc.json" }, g.babel, "MiniIconsYellow")

-- CSS
add_config({ "tailwind.config" }, g.tailwind, "MiniIconsCyan")
add_config({ "postcss.config" }, g.postcss, "MiniIconsRed")
add({ ".postcssrc", ".postcssrc.json" }, g.postcss, "MiniIconsRed")

-- 린터·포맷터
add_config({ "eslint.config" }, g.eslint, "MiniIconsPurple")
add({ ".eslintrc", ".eslintrc.json", ".eslintrc.js", ".eslintrc.cjs", ".eslintignore" }, g.eslint, "MiniIconsPurple")
add_config({ "prettier.config", ".prettierrc" }, g.prettier, "MiniIconsBlue")
add(
  { ".prettierrc", ".prettierrc.json", ".prettierrc.yaml", ".prettierrc.yml", ".prettierignore" },
  g.prettier,
  "MiniIconsBlue"
)

-- 테스트
add_config({ "jest.config" }, g.jest, "MiniIconsRed")
add_config({ "playwright.config" }, g.playwright, "MiniIconsGreen")
add_config({ "cypress.config" }, g.cypress, "MiniIconsGrey")

-- 배포
add({ "vercel.json" }, g.vercel, "MiniIconsGrey")
add({ "netlify.toml" }, g.netlify, "MiniIconsCyan")

return {
  "nvim-mini/mini.icons",
  opts = {
    file = file,
    extension = {
      -- mini.icons 표에도 vim.filetype.match() 에도 없어 기본 아이콘이 된다.
      mdx = { glyph = g.markdown, hl = "MiniIconsYellow" },
      -- .storybook/main.ts 같은 건 이름으로 못 잡으므로 stories 파일만.
      ["stories.tsx"] = { glyph = g.storybook, hl = "MiniIconsRed" },
      ["stories.ts"] = { glyph = g.storybook, hl = "MiniIconsRed" },
      ["stories.jsx"] = { glyph = g.storybook, hl = "MiniIconsRed" },
      ["stories.js"] = { glyph = g.storybook, hl = "MiniIconsRed" },
    },
  },
}
