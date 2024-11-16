local M = {
  "lukas-reineke/indent-blankline.nvim",
  event = "BufReadPre",
  main = "ibl"
}

M.opts = {
  indent = { char = "▏" },
  scope = { show_start = false, show_end = false },
  exclude = {
    buftypes = {
      "nofile",
      "terminal",
    },
    filetypes = {
      "help",
      "startify",
      "aerial",
      "alpha",
      "dashboard",
      "lazy",
      "neogitstatus",
      "NvimTree",
      "neo-tree",
      "Trouble",
    },
  },
}

function M.config()
  local highlight = {
    "RainbowRosewater",
    "RainbowFlamingo",
    "RainbowPink",
    "RainbowMauve",
    "RainbowRed",
    "RainbowMaroon",
    "RainbowPeach",
    "RainbowYellow",
    "RainbowGreen",
    "RainbowTeal",
    "RainbowSky",
    "RainbowSapphire",
    "RainbowBlue",
    "RainbowLavender",
  }

  local hooks = require "ibl.hooks"
  -- create the highlight groups in the highlight setup hook, so they are reset
  -- every time the colorscheme changes
  hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
      vim.api.nvim_set_hl(0, "RainbowRosewater", { fg = "#f5e0dc" })
      vim.api.nvim_set_hl(0, "RainbowFlamingo", { fg = "#f2cdcd" })
      vim.api.nvim_set_hl(0, "RainbowPink", { fg = "#f5c2e7" })
      vim.api.nvim_set_hl(0, "RainbowMauve", { fg = "#cba6f7" })
      vim.api.nvim_set_hl(0, "RainbowRed", { fg = "#f38ba8" })
      vim.api.nvim_set_hl(0, "RainbowMaroon", { fg = "#eba0ac" })
      vim.api.nvim_set_hl(0, "RainbowPeach", { fg = "#fab387" })
      vim.api.nvim_set_hl(0, "RainbowYellow", { fg = "#f9e2af" })
      vim.api.nvim_set_hl(0, "RainbowGreen", { fg = "#a6e3a1" })
      vim.api.nvim_set_hl(0, "RainbowTeal", { fg = "#94e2d5" })
      vim.api.nvim_set_hl(0, "RainbowSky", { fg = "#89dceb" })
      vim.api.nvim_set_hl(0, "RainbowSapphire", { fg = "#74c7ec" })
      vim.api.nvim_set_hl(0, "RainbowBlue", { fg = "#89b4fa" })
      vim.api.nvim_set_hl(0, "RainbowLavender", { fg = "#b4befe" })
  end)

  require("ibl").setup { indent = { highlight = highlight } }
  
end

return M
