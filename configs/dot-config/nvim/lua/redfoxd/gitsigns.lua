local M = {
  "lewis6991/gitsigns.nvim",
  event = "BufReadPre",
}

M.opts = {
  signs = {
    add = { text = "▎" },
    change = { text = "▎" },
    delete = { text = "▎" },
    topdelete = { text = "▎" },
    changedelete = { text = "▎" },
    untracked = { text = "┆" },
  },
}

return M
