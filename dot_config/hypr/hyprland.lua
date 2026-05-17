-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Make ~/.config Lua modules and omarchy resources requirable.
package.path = os.getenv("HOME")
  .. "/.config/?.lua;"
  .. (os.getenv("OMARCHY_PATH") or (os.getenv("HOME") .. "/.local/share/omarchy"))
  .. "/?.lua;"
  .. package.path

-- Shared helpers (o.bind/launch/window wrappers, command_from, etc.).
require("hypr.helpers")

-- Core configuration.
require("hypr.envs")
require("hypr.looknfeel")
require("hypr.input")
require("hypr.windows")
require("hypr.apps")
require("hypr.monitors")
require("hypr.bindings")
require("hypr.autostart")

-- Dynamic toggles (rounded corners, single-window aspect ratio, etc.).
require("hypr.toggles")

-- Current theme overrides.
do
  local paths = require("hypr.paths")
  local theme = io.open(paths.config_home .. "/omarchy/current/theme/hyprland.lua", "r")
  if theme then
    theme:close()
    require("omarchy.current.theme.hyprland")
  end
end
