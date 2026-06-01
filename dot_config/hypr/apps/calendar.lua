-- Google Calendar runs as a Chromium/Brave web app (--app=https://calendar.google.com/).
-- Window class is "<browser>-calendar.google.com__-Default". Hyprland matches the
-- class regex against the FULL string, so the host is wrapped in .* to stay
-- browser-agnostic (brave/chrome/edge/...) without hardcoding the prefix.

-- Float Google Calendar, centered, 875x600 (via system.lua floating-window tag).
o.window(".*calendar\\.google\\.com.*", { tag = "+floating-window" })
