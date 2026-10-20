-- Personal window rules: one file per app in ~/.config/hypr/apps/. Omarchy's own
-- rules live in the upstream external; these load after them and win.
local paths = require("default.hypr.paths")
local require_all = require("default.hypr.require_all")

require_all.files(paths.config_home .. "/hypr/apps", "hypr.apps")
