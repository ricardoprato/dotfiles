-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and resolutions possible: hyprctl monitors all

-- This machine: eDP-1 is 1920x1200. Scale pinned to 1.6 (logical 1200x750) rather
-- than "auto", so the resolved value can't drift between sessions.
--
-- GDK_SCALE must be an INTEGER: GTK parses it with integer semantics, so 1.75 falls
-- back to 1. It is also ignored entirely by native-Wayland GTK apps (GTK4 reads
-- wp_fractional_scale_v1 = 1.6; GTK3 reads wl_output.scale, which Hyprland advertises
-- as 2). It only takes effect for GTK apps under XWayland, where
-- xwayland.force_zero_scaling (envs.lua) makes them report raw 1920x1200 at scale 1 —
-- without it they render 1.6x too small. 2 is the nearest sane integer to 1.6, so
-- XWayland apps end up 2/1.6 = 1.25x larger than native ones. Verified by probing
-- GTK3/GTK4 scale factors across GDK_SCALE = unset/1/1.75/2/3 on 2026-07-30.
local omarchy_gdk_scale = 2
local omarchy_monitor_scale = 1.6

-- Optimized for retina-class 2x displays, like 13" 2.8K, 27" 5K, 32" 6K.
-- local omarchy_gdk_scale = 2
-- local omarchy_monitor_scale = "auto"

-- Straight 1x setup for low-resolution displays like 1080p, 1440p, or ultrawides: both 1.
-- local omarchy_gdk_scale = 1
-- local omarchy_monitor_scale = 1

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°)
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })

-- Example for Framework 13 w/ 6K XDR Apple display.
-- hl.monitor({ output = "DP-5", mode = "6016x3384@60", position = "auto", scale = 2 })
-- hl.monitor({ output = "eDP-1", mode = "2880x1920@120", position = "auto", scale = 2 })

-- Disable the second ghost monitor on an Apple 6K XDR over Thunderbolt.
-- hl.monitor({ output = "DP-2", disabled = true })
