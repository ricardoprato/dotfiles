-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Engine = the upstream omarchy external (default/hypr, never edited). It is
-- pinned by path rather than by the compositor's OMARCHY_PATH, so a reload works
-- whatever environment Hyprland was started with. Everything below this file
-- is ours; see odd/tasks/omarchy-upstream-overlay.md.
local omarchy_path = os.getenv("HOME") .. "/.local/share/omarchy-upstream"
dofile(omarchy_path .. "/default/hypr/bootstrap.lua")
package.path = package.path .. ";" .. omarchy_path .. "/?.lua"
local paths = dofile(omarchy_path .. "/default/hypr/paths.lua")
paths.omarchy_path = omarchy_path
package.loaded["default.hypr.paths"] = paths

-- Keep upstream's preinstalled app/web app binds (ChatGPT, X, HEY...) off; the
-- ones we use are in bindings.lua.
omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Personal overrides, loaded after the defaults so they win.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")
require("hypr.apps")
require("hypr.personal")

-- Toggle config flags dynamically.
require("default.hypr.toggles")
