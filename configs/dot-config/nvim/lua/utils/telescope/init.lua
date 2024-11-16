local M = {}

local _, builtin = pcall(require, "telescope.builtin")

-- Smartly opens either git_files or find_files, depending on whether the working directory is
-- contained in a Git repo.
function M.find_project_files(opts)
  opts = opts or {}
  local ok = pcall(builtin.git_files, opts)

  if not ok then
    builtin.find_files(opts)
  end
end

return M
