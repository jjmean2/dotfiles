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
        -- ---- 워크스페이스 모델 (VS Code 의 workspace folder, IntelliJ 의 project) ----
        -- W = 전역 cwd = 프로젝트 루트. 피커, :find, :grep, LSP 가 전부 W 를 본다.
        --   1. 트리 루트는 W 의 뷰다. 항상 트리 루트 == W.
        --   2. W 는 명시적 행동으로만 바뀐다: :cd, <leader>fp, <leader>fP, 트리의 - / Ctrl-],
        --      그리고 시작할 때 한 번 (core/autocmds.lua 의 StartupWorkspace).
        --   3. 파일을 여는 것은 W 를 바꾸지 않는다. W 안 파일이면 트리에서 펼쳐 보여주고,
        --      밖이면(:h, ~/.zshrc, gd 로 들어간 라이브러리 소스) 트리는 그대로 둔다.
        --   4. 일반 파일이 아닌 버퍼(help, terminal, quickfix, 피커 …)는 트리와 무관하다.
        -- 자세한 시나리오: :h jw-cwd

        -- W → 트리. :cd 로 cwd 가 바뀌면(DirChanged) 트리 루트도 따라온다 (규칙 1).
        -- :lcd 로 인한 윈도우 단위 변경은 nvim-tree 가 스스로 무시한다.
        sync_root_with_cwd = true,

        -- 트리 → W. 트리에서 - (상위) 나 Ctrl-] (이 디렉토리를 루트로) 는 W 를 옮기는 명시적
        -- 행동으로 본다 (규칙 2). 기본값은 :lcd 라 트리 창만 바뀌므로 :cd 로 바꾼다.
        actions = {
          change_dir = { global = true },
          -- 기본값 true 는 파일을 열 때(<CR>, o, <Tab>)마다 트리 너비를 view.width(30)로
          -- 되돌린다. VS Code·JetBrains 처럼 직접 조절한 너비를 유지한다.
          -- 트리를 닫았다 다시 열면 여전히 view.width 로 돌아간다 (위키 레시피
          -- "Remember nvim-tree window size per tab" 으로 해결 가능, 아직 안 씀).
          open_file = { resize_window = false },
        },

        -- 파일 → 트리 (VS Code 의 explorer.autoReveal). 버퍼에 들어갈 때(BufEnter) 그 파일이
        -- W 안이면 트리에서 펼쳐 보여준다.
        update_focused_file = {
          enable = true,
          -- 규칙 3. 켜 두면 W 밖 파일을 열 때 루트를 그 파일 디렉토리로 옮기는데, 이 경로는
          -- 내부적으로 change_dir → :cd 까지 실행해서 W 자체가 바뀐다 (예: :h 한 번에
          -- cwd 가 $VIMRUNTIME/doc 이 됨). 프로젝트 전환은 <leader>fP 로 명시적으로 한다.
          update_root = { enable = false },
          -- 규칙 4. buftype 이 있는 버퍼는 따라가지 않는다.
          exclude = function(ev)
            return vim.bo[ev.buf].buftype ~= ""
          end,
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
