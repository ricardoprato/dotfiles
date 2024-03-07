local M = {}

local mappings = { h = "left", j = "bottom", k = "top", l = "right" }

function M.navigate(direction)
	local next_win = vim.fn.winnr("1" .. direction)
	if vim.fn.winnr() ~= next_win then
		vim.api.nvim_command("wincmd " .. direction)
	else
		local command = "kitty @ kitten kittens/navigate_kitty.py " .. mappings[direction]
		vim.fn.system(command)
	end
end

function M.navigateLeft()
	M.navigate("h")
end

function M.navigateRight()
	M.navigate("l")
end
function M.navigateUp()
	M.navigate("k")
end
function M.navigateDown()
	M.navigate("j")
end

return M
