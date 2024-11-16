local M = {
  "folke/which-key.nvim",
  event = "VeryLazy",
}

function M.config()
  local which_key = require "which-key"

  which_key.setup({})
  require('utils').which_key_register()
  
end

return M
