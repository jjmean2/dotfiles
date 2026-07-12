return {
  { 'tomasiser/vim-code-dark' },
  { 'michaeljsmith/vim-indent-object' },
  { 'tpope/vim-surround' },
  {
    'metalelf0/jellybeans-nvim',
    dependencies = { 'rktjmp/lush.nvim' }
  },
  { 'folke/tokyonight.nvim' },
  { 'nvim-tree/nvim-web-devicons' },
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('nvim-tree').setup()
    end
  },
  {
    "mason-org/mason.nvim",
    opts = {}
  },
  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.nvim' }, -- if you use the mini.nvim suite
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' },        -- if you use standalone mini plugins
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {},
    enabled = false,
  },
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    -- 플러그인이 로드될 때 실행할 초기화 함수를 정의합니다.
    config = function()
      -- 이 안에서 setup을 호출합니다.
      local configs = require('nvim-treesitter')
      configs.setup {
        -- 필요한 파서들을 지정 (알아서 다운로드됨)
        ensure_installed = { "lua", "typescript", "javascript", "tsx", "python", "html", "css" },
        sync_install = false,
        -- 실시간 구문 강조 (선택)
        highlight = { enable = true },
        -- ★ 핵심: Tree-sitter 기반 동적 들여쓰기 활성화
        indent = { enable = true }
      }
    end
  }
  -- {
  -- 'nvim-telescope/telescope.nvim',
  --   tag = '0.1.5',
  --   dependencies = { 'nvim-lua/plenary.nvim' },
  --   config = function()
  --     require('telescope').setup()
  --   end
  -- }
  -- {
  --  "kdheepak/lazygit.nvim",
  --  lazy = true,
  --  cmd = {
  --   "LazyGit",
  --   "LazyGitConfig",
  --   "LazyGitCurrentFile",
  --   "LazyGitFilter",
  --   "LazyGitFilterCurrentFile",
  --  },
  --  -- optional for floating window border decoration
  --  dependencies = {
  --   "nvim-lua/plenary.nvim",
  --  },
  --  -- setting the keybinding for LazyGit with 'keys' is recommended in
  --  -- order to load the plugin when the command is run for the first time
  --  keys = {
  --   { "<leader>lg", "<cmd>LazyGit<cr>", desc = "LazyGit" }
  --  }
  -- }
  --   {
  --   "NeogitOrg/neogit",
  --   lazy = true,
  --   dependencies = {
  --     "nvim-lua/plenary.nvim",         -- required
  --     "sindrets/diffview.nvim",        -- optional - Diff integration
  --
  --     -- Only one of these is needed.
  --     "nvim-telescope/telescope.nvim", -- optional
  --     "ibhagwan/fzf-lua",              -- optional
  -- "nvim-mini/mini.pick",           -- optional
  --     "folke/snacks.nvim",             -- optional
  --   },
  --   cmd = "Neogit",
  --   keys = {
  --     { "<leader>gg", "<cmd>Neogit<cr>", desc = "Show Neogit UI" }
  --   }
  -- }
}
