-- Neovim plugin to manage global and project-local settings
-- https://github.com/folke/neoconf.nvim

local M = {
  "folke/neoconf.nvim",
  cmd = "Neoconf",
  config = false,
  dependencies = { "nvim-lspconfig" },
  opts = {}
}

return M
