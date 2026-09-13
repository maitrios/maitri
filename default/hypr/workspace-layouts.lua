-- Restore workspace layouts saved by maitri-hyprland-workspace-layout-toggle.

local paths = require("default.hypr.paths")
local require_all = require("default.hypr.require_all")

local layouts_dir = paths.state_home .. "/maitri/workspace-layouts"

require_all.files(layouts_dir, "maitri.workspace-layouts", { reload = true })
