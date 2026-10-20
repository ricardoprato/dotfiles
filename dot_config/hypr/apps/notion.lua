-- Notion runs as a Chromium/Brave web app (--app=https://www.notion.so/).
-- Window class is "<browser>-www.notion.so__-Default". Hyprland matches the class
-- regex against the FULL string, so the host is wrapped in .* to stay
-- browser-agnostic (brave/chrome/edge/...) without hardcoding the prefix.

-- Float Notion, centered, 875x600 (via system.lua floating-window tag).
o.window(".*notion\\.so.*", { tag = "+floating-window" })
