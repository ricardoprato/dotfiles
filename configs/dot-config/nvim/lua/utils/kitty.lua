local M = {}

-- Mappings between directions and commands
local direction_mappings = { h = "left", j = "bottom", k = "top", l = "right" }

-- Function to navigate within Neovim or to fallback to Kitty navigation
function M.navigate(direction)
  -- Get the next window in the specified direction
  local next_window = vim.fn.winnr("1" .. direction)

  -- If not already in the next window, perform Neovim window command
  if vim.fn.winnr() ~= next_window then
    vim.api.nvim_command("wincmd " .. direction)
  else
    -- Otherwise, use Kitty's navigation system
    local kitty_command = string.format("kitty @ kitten kittens/navigate_kitty.py %s", direction_mappings[direction])
    vim.fn.system(kitty_command)
  end
end

-- Convenience functions for directional navigation
M.navigateLeft = function()
  M.navigate("h")
end
M.navigateRight = function()
  M.navigate("l")
end
M.navigateUp = function()
  M.navigate("k")
end
M.navigateDown = function()
  M.navigate("j")
end

return M
