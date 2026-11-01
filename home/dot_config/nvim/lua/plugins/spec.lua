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
      require('nvim-tree').setup({
        -- ---- 트리 루트와 nvim cwd 를 한 몸으로 ----
        -- 전제: "nvim 의 cwd 가 곧 프로젝트 루트" (피커, :find, :grep, LSP 가 전부 cwd 를 본다).
        -- nvim-tree 는 자기 루트를 따로 들고 있어서 기본값에서는 셋이 어긋난다. 아래 세 항목이
        -- 양방향을 묶는다. 키는 바뀌지 않는다.

        -- cwd → 트리. :cd (피커의 <leader>fp 포함) 로 cwd 가 바뀌면(DirChanged) 트리 루트도 따라온다.
        -- 기본값 false 면 <leader>fp 뒤 <leader>e 가 이전 프로젝트를 보여준다.
        sync_root_with_cwd = true,

        -- 트리 → cwd. 트리에서 - (상위) 나 Ctrl-] (이 디렉토리를 루트로) 로 루트를 바꿀 때
        -- 기본값은 :lcd 라서 트리 창의 로컬 cwd 만 바뀌고 편집 창과 피커는 모른다.
        -- global = true 면 :cd 가 되어 전체가 함께 움직인다.
        actions = {
          change_dir = { global = true },
        },

        -- 파일 → 트리. 버퍼에 들어갈 때(BufEnter) 트리가 그 파일을 펼쳐 보여주고, 파일이 루트
        -- 밖이면 루트를 옮긴다(cwd 를 우선하고, 없으면 파일의 디렉토리). <leader>E 를 자동으로
        -- 하는 셈이라 "지금 보는 파일이 트리 어디인가" 를 찾을 일이 없어진다.
        update_focused_file = {
          enable = true,
          update_root = true,
        },
      })
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
