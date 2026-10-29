return {
  { 'tomasiser/vim-code-dark' },
  { 'michaeljsmith/vim-indent-object' },
  { 'tpope/vim-surround' },
  {
    'metalelf0/jellybeans-nvim',
    dependencies = { 'rktjmp/lush.nvim' }
  },
  { 'folke/tokyonight.nvim' },
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('nvim-tree').setup()
    end
  },
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
