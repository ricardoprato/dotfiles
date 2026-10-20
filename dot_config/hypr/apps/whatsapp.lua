-- WhatsApp runs as a Chromium/Brave web app (--app=https://web.whatsapp.com/).
-- Window class is "<browser>-web.whatsapp.com__-Default". Hyprland matches the
-- class regex against the FULL string, so the host is wrapped in .* to stay
-- browser-agnostic (brave/chrome/edge/...) without hardcoding the prefix.

-- Prevent WhatsApp from stealing focus on new messages.
o.window(".*web\\.whatsapp\\.com.*", { focus_on_activate = false })

-- Float WhatsApp, centered, 875x600 (via system.lua floating-window tag).
o.window(".*web\\.whatsapp\\.com.*", { tag = "+floating-window" })
