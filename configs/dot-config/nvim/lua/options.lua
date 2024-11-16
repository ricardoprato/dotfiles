vim.opt.viewoptions:remove "curdir" -- disable saving current directory with views
vim.opt.shortmess:append { s = true, I = true } -- disable search count wrap and startup messages
vim.opt.backspace:append { "nostop" } -- don't stop backspace at insert
if vim.fn.has "nvim-0.9" == 1 then
  vim.opt.diffopt:append "linematch:60" -- enable linematch diff algorithm
end
local options = {
  opt = {
    breakindent = true, -- wrap indent to match  line start
    backup = false, -- creates a backup file
    clipboard = "unnamedplus", -- allows neovim to access the system clipboard
    cmdheight = 1, -- more space in the neovim command line for displaying messages
    completeopt = { "menu", "menuone", "noselect" },
    copyindent = true, -- copy the previous indentation on autoindenting
    conceallevel = 0, -- so that `` is visible in markdown files
    fileencoding = "utf-8", -- the encoding written to a file
    foldmethod = "manual", -- folding, set to "expr" for treesitter based folding
    foldexpr = "", -- set to "nvim_treesitter#foldexpr()" for treesitter based folding
    fillchars = { eob = " " }, -- disable `~` on nonexistent lines
    foldenable = true, -- enable fold for nvim-ufo
    foldlevel = 99, -- set high foldlevel for nvim-ufo
    foldlevelstart = 99, -- start with all code unfolded
    foldcolumn = vim.fn.has "nvim-0.9" == 1 and "1" or nil, -- show foldcolumn in nvim 0.9
    hidden = true, -- required to keep multiple buffers and open multiple buffers
    hlsearch = true, -- highlight all matches on previous search pattern
    ignorecase = true, -- ignore case in search patterns
    mouse = "a", -- allow the mouse to be used in neovim
    pumheight = 10, -- pop up menu height
    showmode = false, -- we don't need to see things like -- INSERT -- anymore
    smartcase = true, -- smart case
    splitbelow = true, -- force all horizontal splits to go below current window
    splitright = true, -- force all vertical splits to go to the right of current window
    swapfile = false, -- creates a swapfile
    termguicolors = true, -- set term gui colors (most terminals support this)
    timeoutlen = 300, -- time to wait for a mapped sequence to complete (in milliseconds)
    title = true, -- set the title of window to the value of the titlestring
    titlestring = "%<%F%=%l/%L - nvim", -- what the title of the window will be set to
    undofile = true, -- enable persistent undo
    updatetime = 100, -- faster completion
    writebackup = false, -- if a file is being edited by another program (or was written to file while editing with another program), it is not allowed to be edited
    expandtab = true, -- convert tabs to spaces
    shiftwidth = 2, -- the number of spaces inserted for each indentation
    tabstop = 2, -- insert 2 spaces for a tab
    cursorline = true, -- highlight the current line
    number = true, -- set numbered lines
    relativenumber = true, -- show relative numberline
    numberwidth = 4, -- set number column width to 2 {default 4}
    signcolumn = "yes", -- always show the sign column, otherwise it would shift the text each time
    wrap = false, -- display lines as one long line
    scrolloff = 10, -- minimal number of screen lines to keep above and below the cursor.
    sidescrolloff = 8, -- minimal number of screen lines to keep left and right of the cursor.
    showcmd = false,
    virtualedit = "block", -- allow going past end of line in visual block mode
    ruler = false,
    laststatus = 3,
    history = 100, -- number of commands to remember in a history table
    infercase = true, -- infer cases in keyword completion
    linebreak = true, -- wrap lines at 'breakat'
    preserveindent = true, -- preserve indent structure as much as possible
    showtabline = 2, -- always display tabline
    list = true,
    listchars = { tab = '» ', trail = '·', nbsp = '␣' },
    inccommand = 'split',
  },
  g = {
    mapleader = " ", -- set leader key
    maplocalleader = ",", -- set default local leader key
    max_file = { size = 1024 * 100, lines = 10000 }, -- set global limits for large files
    autoformat_enabled = true, -- enable or disable auto formatting at start (lsp.formatting.format_on_save must be enabled)
    autopairs_enabled = true, -- enable autopairs at start
    cmp_enabled = true, -- enable completion at start
    codelens_enabled = true, -- enable or disable automatic codelens refreshing for lsp that support it
    diagnostics_mode = 3, -- set the visibility of diagnostics in the UI (0=off, 1=only show in status line, 2=virtual text off, 3=all on)
    highlighturl_enabled = true, -- highlight URLs by default
    inlay_hints_enabled = false, -- enable or disable LSP inlay hints on startup (Neovim v0.10 only)
    lsp_handlers_enabled = true, -- enable or disable default vim.lsp.handlers (hover and signature help)
    semantic_tokens_enabled = true, -- enable or disable LSP semantic tokens on startup
    notifications_enabled = true, -- disable notifications  
    git_worktrees = nil, -- enable git integration for detached worktrees (specify a table where each entry is of the form { toplevel = vim.env.HOME, gitdir=vim.env.HOME .. "/.dotfiles" })
    have_nerd_font = true,
  },
  t = vim.t.bufs and vim.t.bufs or { bufs = vim.api.nvim_list_bufs() }, -- initialize buffers for the current tab
}

for scope, table in pairs(options) do
  for setting, value in pairs(table) do
    vim[scope][setting] = value
  end
end
