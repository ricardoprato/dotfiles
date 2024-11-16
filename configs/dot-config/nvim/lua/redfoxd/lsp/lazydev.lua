--  Plugin that properly configures LuaLS for editing your Neovim config by lazily updating your workspace libraries.
--  https://github.com/folke/lazydev.nvim

local M = {
  "folke/lazydev.nvim",
  opts = {
    library = { "nvim-dap-ui" },
  },
}

return M
