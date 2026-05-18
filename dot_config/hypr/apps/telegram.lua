-- Prevent Telegram from stealing focus on new messages.
o.window("org.telegram.desktop", { focus_on_activate = false })

-- Float Telegram, centered, 875x600 (via system.lua floating-window tag).
o.window("org.telegram.desktop", { tag = "+floating-window" })
