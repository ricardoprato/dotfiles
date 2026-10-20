-- Personal environment and window rules that do not fit the other modules.
local paths = require("default.hypr.paths")

-- Qt style: kvantum (upstream exports QT_QPA_PLATFORMTHEME=gtk3 and keeps it).
hl.env("QT_STYLE_OVERRIDE", "kvantum")

-- Config for the Playwright MCP (gives its Chrome its own class so the rules in
-- apps/playwright.lua do not touch the everyday Chrome). Passed through the
-- environment because the plugin's .mcp.json is overwritten on every update.
hl.env("PLAYWRIGHT_MCP_CONFIG", paths.home .. "/.config/playwright-mcp.json")

-- Upstream's envs.lua puts $OMARCHY_PATH/bin first in the PATH of everything
-- Hyprland spawns, which would hide the overrides and our own scripts in
-- ~/.local/bin. Same order as the session PATH (uwsm/env): ~/.local/bin, then
-- the upstream bin dir, then the rest.
local first = { paths.home .. "/.local/bin", paths.omarchy_path .. "/bin" }
local skip = { [first[1]] = true, [first[2]] = true }
local path = {}
for _, entry in ipairs(first) do table.insert(path, entry) end
for entry in (os.getenv("PATH") or "/usr/local/bin:/usr/bin"):gmatch("[^:]+") do
  if not skip[entry] then table.insert(path, entry) end
end
hl.env("PATH", table.concat(path, ":"))
