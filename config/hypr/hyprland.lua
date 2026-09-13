-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- maitri's bootstrap keeps path setup out of this user config.
dofile((os.getenv("MAITRI_PATH") or "/usr/share/maitri") .. "/default/hypr/bootstrap.lua")

-- Disable all maitri default bindings. Add your own in hypr/bindings.lua.
-- maitri_default_bindings = false
--
-- Or disable only bindings for maitri's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- maitri_preinstalled_bindings = false

-- Load maitri defaults.
require("default.hypr.maitri")

-- Put your personal overrides in these files. They're loaded after maitri's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })
