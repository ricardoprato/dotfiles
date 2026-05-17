local paths = require("hypr.paths")
local require_all = require("hypr.require_all")

local toggles_dir = paths.state_home .. "/omarchy/toggles/hypr"
package.path = toggles_dir .. "/?.lua;" .. package.path

require_all.files(toggles_dir, nil, { reload = true })
