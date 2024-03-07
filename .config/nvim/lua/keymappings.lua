-- Define Mapleader
vim.g.mapleader = " "
local icons = require('utils.icons')
local utils = require('utils')
local maps = utils.empty_map_table()
local terminal = require('utils.terminal')
local kitty = require('utils.kitty')

local sections = {
  s = { desc = icons.ui.Search .. " Search" },
  p = { desc = icons.ui.Package .. " Packages" },
  l = { desc = icons.ui.Code .. " LSP" },
  u = { desc = icons.ui.Window .. " UI/UX" },
  b = { desc = icons.ui.Tab .. " Buffers" },
  bs = { desc = icons.ui.Sort .. " Sort Buffers" },
  d = { desc = icons.ui.DebugConsole .. " Debugger" },
  g = { desc = icons.git.Octoface .. " Git" },
  t = { desc = icons.ui.Terminal .. " Terminal" },
}

-- navigation
maps.insert_mode["<A-Up>"] = "<C-\\><C-N><C-w>k"
maps.insert_mode["<A-Down>"] = "<C-\\><C-N><C-w>j"
maps.insert_mode["<A-Left>"] = "<C-\\><C-N><C-w>h"
maps.insert_mode["<A-Right>"] = "<C-\\><C-N><C-w>l"

-- Move current line / block with Alt-j/k ala vscode.
maps.insert_mode["<A-j>"] = "<Esc>:m .+1<CR>==gi"
maps.insert_mode["<A-k>"] = "<Esc>:m .-2<CR>==gi"
maps.normal_mode["<A-j>"] = ":m .+1<CR>=="
maps.normal_mode["<A-k>"] = ":m .-2<CR>=="

-- QuickFix
maps.normal_mode["]q"] = ":cnext<CR>"
maps.normal_mode["[q"] = ":cprev<CR>"
maps.normal_mode["<C-q>"] = ":call QuickFixToggle()<CR>"

maps.normal_mode["<Leader>w"] = {":w!<CR>",  desc = "Save" }
maps.normal_mode["<Leader>q"] = {":q<CR>",  desc = "Quit" }
maps.normal_mode["<Leader>n"] = {"<cmd>enew<cr>",  desc = "New file" }
maps.normal_mode["tt"] = {":t.<CR>",  desc = "New file" }
maps.normal_mode['<Esc>'] = ':noh<CR>'

-- Terminal window navigation
maps.term_mode["<C-h>"] = "<C-\\><C-N><C-w>h"
maps.term_mode["<C-j>"] = "<C-\\><C-N><C-w>j"
maps.term_mode["<C-k>"] = "<C-\\><C-N><C-w>k"
maps.term_mode["<C-l>"] = "<C-\\><C-N><C-w>l"

-- Better indenting
maps.visual_mode["<"] = "<gv"
maps.visual_mode[">"] = ">gv"

-- Move current line / block with Alt-j/k ala vscode.
maps.visual_block_mode["<A-j>"] = ":m '>+1<CR>gv-gv"
maps.visual_block_mode["<A-k>"] = ":m '<-2<CR>gv-gv"

-- navigate tab completion with <c-j> and <c-k>
-- runs conditionally
maps.command_mode["<C-j>"] = { 'pumvisible() ? "\\<C-n>" : "\\<C-j>"'}
maps.command_mode["<C-k>"] = { 'pumvisible() ? "\\<C-p>" : "\\<C-k>"'}

-- NeoTree
maps.normal_mode["<leader>e"] = { "<cmd>Neotree toggle<cr>", desc = "Toggle Explorer" }
maps.normal_mode["<leader>o"] = {
  function()
    if vim.bo.filetype == "neo-tree" then
      vim.cmd.wincmd "p"
    else
      vim.cmd.Neotree "focus"
    end
  end,
  desc = "Toggle Explorer Focus",
}

-- Alpha
maps.normal_mode["<leader>h"] = {
function()
  local wins = vim.api.nvim_tabpage_list_wins(0)
  if #wins > 1 and vim.api.nvim_get_option_value("filetype", { win = wins[1] }) == "neo-tree" then
    vim.fn.win_gotoid(wins[2]) -- go to non-neo-tree window to toggle alpha
  end
  require("alpha").start(false, require("alpha").default_config)
end,
desc = "Home Screen",
}

-- Plugin Manager
maps.normal_mode["<leader>p"] = sections.p
maps.normal_mode["<leader>pi"] = { function() require("lazy").install() end, desc = "Plugins Install" }
maps.normal_mode["<leader>ps"] = { function() require("lazy").home() end, desc = "Plugins Status" }
maps.normal_mode["<leader>pS"] = { function() require("lazy").sync() end, desc = "Plugins Sync" }
maps.normal_mode["<leader>pu"] = { function() require("lazy").check() end, desc = "Plugins Check Updates" }
maps.normal_mode["<leader>pU"] = { function() require("lazy").update() end, desc = "Plugins Update" }

-- Package Manager
maps.normal_mode["<leader>pm"] = { "<cmd>Mason<cr>", desc = "Mason Installer" }
maps.normal_mode["<leader>pM"] = { "<cmd>MasonUpdateAll<cr>", desc = "Mason Update" }

-- Navigate tabs
maps.normal_mode["<tab>"] = { function() vim.cmd.tabnext() end, desc = "Next tab" }
maps.normal_mode["<S-tab>"] = { function() vim.cmd.tabprevious() end, desc = "Previous tab" }

-- Manage Buffers
maps.normal_mode["<leader>c"] = { function() require("utils.buffer").close() end, desc = "Close buffer" }
maps.normal_mode["<leader>C"] = { function() require("utils.buffer").close(0, true) end, desc = "Force close buffer" }
maps.normal_mode["<tab>"] =
  { function() require("utils.buffer").nav(vim.v.count > 0 and vim.v.count or 1) end, desc = "Next buffer" }
maps.normal_mode["<S-tab>"] = {
  function() require("utils.buffer").nav(-(vim.v.count > 0 and vim.v.count or 1)) end,
  desc = "Previous buffer",
}
maps.normal_mode[">b"] = {
  function() require("utils.buffer").move(vim.v.count > 0 and vim.v.count or 1) end,
  desc = "Move buffer tab right",
}
maps.normal_mode["<b"] = {
  function() require("utils.buffer").move(-(vim.v.count > 0 and vim.v.count or 1)) end,
  desc = "Move buffer tab left",
}

maps.normal_mode["<leader>b"] = sections.b
maps.normal_mode["<leader>bc"] =
  { function() require("utils.buffer").close_all(true) end, desc = "Close all buffers except current" }
maps.normal_mode["<leader>bC"] = { function() require("utils.buffer").close_all() end, desc = "Close all buffers" }
maps.normal_mode["<leader>bl"] =
  { function() require("utils.buffer").close_left() end, desc = "Close all buffers to the left" }
maps.normal_mode["<leader>bp"] = { function() require("utils.buffer").prev() end, desc = "Previous buffer" }
maps.normal_mode["<leader>br"] =
  { function() require("utils.buffer").close_right() end, desc = "Close all buffers to the right" }
maps.normal_mode["<leader>bs"] = sections.bs
maps.normal_mode["<leader>bse"] = { function() require("utils.buffer").sort "extension" end, desc = "By extension" }
maps.normal_mode["<leader>bsr"] =
  { function() require("utils.buffer").sort "unique_path" end, desc = "By relative path" }
maps.normal_mode["<leader>bsp"] = { function() require("utils.buffer").sort "full_path" end, desc = "By full path" }
maps.normal_mode["<leader>bsi"] = { function() require("utils.buffer").sort "bufnr" end, desc = "By buffer number" }
maps.normal_mode["<leader>bsm"] = { function() require("utils.buffer").sort "modified" end, desc = "By modification" }

-- GitSigns
maps.normal_mode["<leader>g"] = sections.g
maps.normal_mode["]g"] = { function() require("gitsigns").next_hunk() end, desc = "Next Git hunk" }
maps.normal_mode["[g"] = { function() require("gitsigns").prev_hunk() end, desc = "Previous Git hunk" }
maps.normal_mode["<leader>gl"] = { function() require("gitsigns").blame_line() end, desc = "View Git blame" }
maps.normal_mode["<leader>gL"] = { function() require("gitsigns").blame_line { full = true } end, desc = "View full Git blame" }
maps.normal_mode["<leader>gp"] = { function() require("gitsigns").preview_hunk() end, desc = "Preview Git hunk" }
maps.normal_mode["<leader>gh"] = { function() require("gitsigns").reset_hunk() end, desc = "Reset Git hunk" }
maps.normal_mode["<leader>gr"] = { function() require("gitsigns").reset_buffer() end, desc = "Reset Git buffer" }
maps.normal_mode["<leader>gs"] = { function() require("gitsigns").stage_hunk() end, desc = "Stage Git hunk" }
maps.normal_mode["<leader>gS"] = { function() require("gitsigns").stage_buffer() end, desc = "Stage Git buffer" }
maps.normal_mode["<leader>gu"] = { function() require("gitsigns").undo_stage_hunk() end, desc = "Unstage Git hunk" }
maps.normal_mode["<leader>gd"] = { function() require("gitsigns").diffthis() end, desc = "View Git diff" }

-- Smart Splits
if vim.env.KITTY_WINDOW_ID then
  maps.normal_mode["<C-h>"] = { function() kitty.navigateLeft() end, desc = "Move to left split" }
  maps.normal_mode["<C-j>"] = { function() kitty.navigateDown() end, desc = "Move to below split" }
  maps.normal_mode["<C-k>"] = { function() kitty.navigateUp() end, desc = "Move to above split" }
  maps.normal_mode["<C-l>"] = { function() kitty.navigateRight() end, desc = "Move to right split" }
else
  maps.normal_mode["<C-h>"] = { "<C-w>h", desc = "Move to left split" }
  maps.normal_mode["<C-j>"] = { "<C-w>j", desc = "Move to below split" }
  maps.normal_mode["<C-k>"] = { "<C-w>k", desc = "Move to above split" }
  maps.normal_mode["<C-l>"] = { "<C-w>l", desc = "Move to right split" }
end

maps.normal_mode["<C-Up>"] = { "<cmd>resize -2<CR>", desc = "Resize split up" }
maps.normal_mode["<C-Down>"] = { "<cmd>resize +2<CR>", desc = "Resize split down" }
maps.normal_mode["<C-Left>"] = { "<cmd>vertical resize -2<CR>", desc = "Resize split left" }
maps.normal_mode["<C-Right>"] = { "<cmd>vertical resize +2<CR>", desc = "Resize split right" }

if vim.fn.has "mac" == 1 then
  maps.normal_mode["<A-Up>"] = maps.normal_mode["<C-Up>"]
  maps.normal_mode["<A-Down>"] = maps.normal_mode["<C-Down>"]
  maps.normal_mode["<A-Left>"] = maps.normal_mode["<C-Left>"]
  maps.normal_mode["<A-Right>"] = maps.normal_mode["<C-Right>"]
end

-- Telescope
maps.normal_mode["<leader>s"] = sections.s
maps.normal_mode["<leader>gb"] =
  { function() require("telescope.builtin").git_branches { use_file_path = true } end, desc = "Git branches" }
maps.normal_mode["<leader>gc"] = {
  function() require("telescope.builtin").git_commits { use_file_path = true } end,
  desc = "Git commits (repository)",
}
maps.normal_mode["<leader>gC"] = {
  function() require("telescope.builtin").git_bcommits { use_file_path = true } end,
  desc = "Git commits (current file)",
}
maps.normal_mode["<leader>gt"] =
  { function() require("telescope.builtin").git_status { use_file_path = true } end, desc = "Git status" }
maps.normal_mode["<leader>s<CR>"] = { function() require("telescope.builtin").resume() end, desc = "Resume previous search" }
maps.normal_mode["<leader>s'"] = { function() require("telescope.builtin").marks() end, desc = "Find marks" }
maps.normal_mode["<leader>s/"] =
  { function() require("telescope.builtin").current_buffer_fuzzy_find() end, desc = "Find words in current buffer" }
maps.normal_mode["<leader>sb"] = { function() require("telescope.builtin").buffers() end, desc = "Find buffers" }
maps.normal_mode["<leader>sc"] = { function() require("telescope.builtin").grep_string() end, desc = "Find word under cursor" }
maps.normal_mode["<leader>sC"] = { function() require("telescope.builtin").commands() end, desc = "Find commands" }
maps.normal_mode["<leader>sf"] = { function() require("telescope.builtin").find_files() end, desc = "Find files" }
maps.normal_mode["<leader>sF"] = {
  function() require("telescope.builtin").find_files { hidden = true, no_ignore = true } end,
  desc = "Find all files",
}
maps.normal_mode["<leader>sh"] = { function() require("telescope.builtin").help_tags() end, desc = "Find help" }
maps.normal_mode["<leader>sk"] = { function() require("telescope.builtin").keymaps() end, desc = "Find keymaps" }
maps.normal_mode["<leader>sm"] = { function() require("telescope.builtin").man_pages() end, desc = "Find man" }
maps.normal_mode["<leader>so"] = { function() require("telescope.builtin").oldfiles() end, desc = "Find history" }
maps.normal_mode["<leader>sr"] = { function() require("telescope.builtin").registers() end, desc = "Find registers" }
maps.normal_mode["<leader>st"] =
  { function() require("telescope.builtin").colorscheme { enable_preview = true } end, desc = "Find themes" }
maps.normal_mode["<leader>sw"] = { function() require("telescope.builtin").live_grep() end, desc = "Find words" }
maps.normal_mode["<leader>sW"] = {
  function()
    require("telescope.builtin").live_grep {
      additional_args = function(args) return vim.list_extend(args, { "--hidden", "--no-ignore" }) end,
    }
  end,
  desc = "Find words in all files",
}

-- Terminal
maps.normal_mode["<leader>t"] = sections.t
if vim.fn.executable "lazygit" == 1 then
  maps.normal_mode["<leader>gg"] = {
    function()
      local worktree = require("utils.git").file_worktree()
      local flags = worktree and (" --work-tree=%s --git-dir=%s"):format(worktree.toplevel, worktree.gitdir) or ""
      terminal.toggle_term_cmd("lazygit " .. flags)
    end,
    desc = "ToggleTerm lazygit",
  }
  maps.normal_mode["<leader>tl"] = maps.normal_mode["<leader>gg"]
end
if vim.fn.executable "lazydocker" == 1 then
  maps.normal_mode["<leader>td"] = { function() terminal.toggle_term_cmd "lazydocker" end, desc = "ToggleTerm lazydocker" }
  maps.term_mode["<leader>td"] = maps.normal_mode["<leader>td"]
end
if vim.fn.executable "node" == 1 then
  maps.normal_mode["<leader>tn"] = { function() terminal.toggle_term_cmd "node" end, desc = "ToggleTerm node" }
end
if vim.fn.executable "gdu" == 1 then
  maps.normal_mode["<leader>tu"] = { function() terminal.toggle_term_cmd "gdu" end, desc = "ToggleTerm gdu" }
end
if vim.fn.executable "btm" == 1 then
  maps.normal_mode["<leader>tt"] = { function() terminal.toggle_term_cmd "btm" end, desc = "ToggleTerm btm" }
end
local python = vim.fn.executable "python" == 1 and "python" or vim.fn.executable "python3" == 1 and "python3"
if python then maps.normal_mode["<leader>tp"] = { function() terminal.toggle_term_cmd(python) end, desc = "ToggleTerm python" } end
maps.normal_mode["<leader>tf"] = { "<cmd>ToggleTerm direction=float<cr>", desc = "ToggleTerm float" }
maps.normal_mode["<leader>th"] = { "<cmd>ToggleTerm size=10 direction=horizontal<cr>", desc = "ToggleTerm horizontal split" }
maps.normal_mode["<leader>tv"] = { "<cmd>ToggleTerm size=80 direction=vertical<cr>", desc = "ToggleTerm vertical split" }
maps.normal_mode["<F7>"] = { "<cmd>ToggleTerm<cr>", desc = "Toggle terminal" }
maps.term_mode["<F7>"] = maps.normal_mode["<F7>"]
maps.normal_mode["<C-'>"] = maps.normal_mode["<F7>"] -- requires terminal that supports binding <C-'>
maps.term_mode["<C-'>"] = maps.normal_mode["<F7>"] -- requires terminal that supports binding <C-'>

-- Debugger
maps.normal_mode["<leader>d"] = sections.d
maps.visual_mode["<leader>d"] = sections.d
-- modified function keys found with `showkey -a` in the terminal to get key code
-- run `nvim -V3log +quit` and search through the "Terminal info" in the `log` file for the correct keyname
maps.visual_mode["<F2>"] = { function() require("dapui").eval() end, desc = "Evaluate Input" }
maps.normal_mode["<F5>"] = { function() require("dap").continue() end, desc = "Debugger: Start" }
maps.normal_mode["<F17>"] = { function() require("dap").terminate() end, desc = "Debugger: Stop" } -- Shift+F5
maps.normal_mode["<F21>"] = { -- Shift+F9
  function()
    vim.ui.input({ prompt = "Condition: " }, function(condition)
      if condition then require("dap").set_breakpoint(condition) end
    end)
  end,
  desc = "Debugger: Conditional Breakpoint",
}
maps.normal_mode["<F29>"] = { function() require("dap").restart_frame() end, desc = "Debugger: Restart" } -- Control+F5
maps.normal_mode["<F6>"] = { function() require("dap").pause() end, desc = "Debugger: Pause" }
maps.normal_mode["<F9>"] = { function() require("dap").toggle_breakpoint() end, desc = "Debugger: Toggle Breakpoint" }
maps.normal_mode["<F10>"] = { function() require("dap").step_over() end, desc = "Debugger: Step Over" }
maps.normal_mode["<F11>"] = { function() require("dap").step_into() end, desc = "Debugger: Step Into" }
maps.normal_mode["<F23>"] = { function() require("dap").step_out() end, desc = "Debugger: Step Out" } -- Shift+F11
maps.normal_mode["<leader>db"] = { function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint (F9)" }
maps.normal_mode["<leader>dB"] = { function() require("dap").clear_breakpoints() end, desc = "Clear Breakpoints" }
maps.normal_mode["<leader>dc"] = { function() require("dap").continue() end, desc = "Start/Continue (F5)" }
maps.normal_mode["<leader>dC"] = {
  function()
    vim.ui.input({ prompt = "Condition: " }, function(condition)
      if condition then require("dap").set_breakpoint(condition) end
    end)
  end,
  desc = "Conditional Breakpoint (S-F9)",
}
maps.normal_mode["<leader>di"] = { function() require("dap").step_into() end, desc = "Step Into (F11)" }
maps.normal_mode["<leader>do"] = { function() require("dap").step_over() end, desc = "Step Over (F10)" }
maps.normal_mode["<leader>dO"] = { function() require("dap").step_out() end, desc = "Step Out (S-F11)" }
maps.normal_mode["<leader>dq"] = { function() require("dap").close() end, desc = "Close Session" }
maps.normal_mode["<leader>dQ"] = { function() require("dap").terminate() end, desc = "Terminate Session (S-F5)" }
maps.normal_mode["<leader>dp"] = { function() require("dap").pause() end, desc = "Pause (F6)" }
maps.normal_mode["<leader>dr"] = { function() require("dap").restart_frame() end, desc = "Restart (C-F5)" }
maps.normal_mode["<leader>dR"] = { function() require("dap").repl.toggle() end, desc = "Toggle REPL" }
maps.normal_mode["<leader>ds"] = { function() require("dap").run_to_cursor() end, desc = "Run To Cursor" }
maps.normal_mode["<leader>da"] = { function() require("dap").set_exception_breakpoints() end, desc = "Set Exception Breakpoint" }

maps.normal_mode["<leader>de"] = {
  function()
    vim.ui.input({ prompt = "Expression: " }, function(expr)
      if expr then require("dapui").eval(expr, { enter = true }) end
    end)
  end,
  desc = "Evaluate Input",
}
maps.visual_mode["<leader>de"] = { function() require("dapui").eval() end, desc = "Evaluate Input (F2)" }
maps.normal_mode["<leader>du"] = { function() require("dapui").toggle() end, desc = "Toggle Debugger UI" }
maps.normal_mode["<leader>dh"] = { function() require("dap.ui.widgets").hover() end, desc = "Debugger Hover" }

utils.set_keymaps(maps)
