-- App-specific window rules and workspace assignments.
-- One file per app under hypr/apps/. Add a new file there to register
-- rules for a new app; this loader picks it up automatically.
local paths = require("hypr.paths")
local require_all = require("hypr.require_all")

require_all.files(paths.config_home .. "/hypr/apps", "hypr.apps")
