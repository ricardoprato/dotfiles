local paths = require("hypr.default.paths")
local require_all = require("hypr.default.require_all")

require_all.files(paths.omarchy_path .. "/default/hypr/bindings", "hypr.default.bindings")
