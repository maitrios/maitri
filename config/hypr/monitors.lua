-- Fallback rules for displays no hyprmoncfg profile describes. Arrange displays
-- and save profiles with hyprmoncfg (Setup > Monitors, or the Display panel); its
-- generated rules load last from hyprland.lua and override anything here.
-- See https://wiki.hypr.land/Configuring/Basics/Monitors/

local maitri_gdk_scale = 2
local maitri_monitor_scale = "auto"

hl.env("GDK_SCALE", tostring(maitri_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = maitri_monitor_scale })

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })
