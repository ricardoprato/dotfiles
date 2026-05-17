-- Omarchy Hyprland setup: helpers, defaults, and current theme overrides.

require("hypr.default.helpers")

-- Use Omarchy defaults, but don't edit these directly.
require("hypr.default.autostart")
require("hypr.default.bindings.media")
require("hypr.default.bindings.clipboard")
require("hypr.default.bindings.tiling-v2")
require("hypr.default.bindings.utilities")
require("hypr.default.envs")
require("hypr.default.looknfeel")
require("hypr.default.input")
require("hypr.default.windows")

-- Current theme overrides.
do
  local paths = require("hypr.default.paths")
  local theme = io.open(paths.config_home .. "/omarchy/current/theme/hyprland.lua", "r")
  if theme then
    theme:close()
    require("omarchy.current.theme.hyprland")
  end
end
