local M = {
  "stevearc/conform.nvim",
  opts = {},
}

function M.config()
  require("conform").setup({
    formatters_by_ft = {
      lua = { "stylua" },
      -- Conform will run multiple formatters sequentially
      python = { "isort", "black" },
      -- Use a sub-list to run only the first available formatter
      javascript = { { "prettierd", "prettier" } },
      xml = { "xmlformatter" },
    },
  })
end

return M
