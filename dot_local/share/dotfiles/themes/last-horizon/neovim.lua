return {
  {
    "bjarneo/aether.nvim",
    name = "aether",
    priority = 1000,
    lazy = false,
    config = function() vim.cmd.colorscheme("aether") end,
  },
}
