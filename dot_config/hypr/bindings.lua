-- Keep only personal keybinding overrides here. Add new bindings with o.bind or
-- replace defaults with o.rebind. See what is bound with:
--   omarchy menu keybindings --print

-- Application and web app bindings. Upstream's preinstalled set is switched off
-- in hyprland.lua (omarchy_preinstalled_bindings = false); these are ours.
o.bind("SUPER + ALT + RETURN", "Tmux", { omarchy = "terminal-tmux" })
o.bind("SUPER + SHIFT + M", "Music", { omarchy = "or-focus spotify" })
o.bind("SUPER + SHIFT + ALT + M", "Music TUI", { tui = "cliamp", focus = true })
o.bind("SUPER + SHIFT + D", "Docker", { tui = "lazydocker" })
o.bind("SUPER + SHIFT + G", "Telegram", { launch = "Telegram", focus = "^org\\.telegram\\.desktop$" })
o.bind("SUPER + SHIFT + O", "Obsidian", { launch = "obsidian", focus = "^obsidian$" })
o.bind("SUPER + SHIFT + E", "Capacities", { launch = "capacities", focus = "^io\\.capacities\\.app$" })
o.bind("SUPER + SHIFT + V", "Passwords", { launch = "bitwarden-desktop", focus = "^Bitwarden$" })
o.bind("SUPER + SHIFT + R", "SSH host picker", { tui = "sshs", focus = true })

o.bind("SUPER + SHIFT + C", "Google Calendar", { webapp = "https://calendar.google.com/", focus = true })
o.bind("SUPER + SHIFT + Y", "YouTube", { webapp = "https://youtube.com/" })
o.bind("SUPER + SHIFT + ALT + G", "WhatsApp", { webapp = "https://web.whatsapp.com/", focus = true })
o.bind("SUPER + SHIFT + CTRL + G", "Google Messages", { webapp = "https://messages.google.com/web/conversations", focus = true })
o.bind("SUPER + SHIFT + P", "Google Photos", { webapp = "https://photos.google.com/", focus = true })
o.bind("SUPER + SHIFT + W", "Google Maps", { webapp = "https://maps.google.com/", focus = true })
o.bind("SUPER + SHIFT + U", "Busuu", { webapp = "https://www.busuu.com/", focus = true })

-- Dictation through voxtype: SUPER + CTRL + X (and SUPER + H) toggle. Upstream binds
-- F9 / Right Alt push-to-talk only when its dictation backend is installed.
o.bind("SUPER + H", nil, "voxtype record toggle")
o.rebind("SUPER + CTRL + X", "Toggle dictation", "voxtype record toggle")
-- o.bind("F9", "Start dictation (push-to-talk)", "voxtype record start")
-- o.bind("F9", "Stop dictation (push-to-talk)", "voxtype record stop", { release = true })

-- Physical keys (code:49 grave, code:61 slash on a US layout) so they work on latam
-- too. Upstream binds the keysyms; drop those so each key has a single bind.
for _, keys in ipairs({ "SUPER + grave", "SUPER + SHIFT + grave", "SUPER + SLASH", "SUPER + ALT + SLASH" }) do
  hl.unbind(keys)
end
o.bind("SUPER + code:49", "Toggle scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))
o.bind("SUPER + SHIFT + code:49", "Move window to scratchpad", hl.dsp.window.move({ workspace = "special:scratchpad", follow = false }))
o.bind("SUPER + code:61", "Monitor scaling up", "omarchy-hyprland-monitor-scaling up")
o.bind("SUPER + ALT + code:61", "Monitor scaling down", "omarchy-hyprland-monitor-scaling down")

-- Output switch, emojis and the calculator (omacalc is not installed here).
o.bind("SUPER + XF86AudioMute", "Switch audio output", "omarchy-audio-output-switch", { locked = true })
o.bind("SUPER + PERIOD", "Emojis", { panel = "omarchy.emojis" })
o.rebind("XF86Calculator", "Calculator", "gnome-calculator")
hl.unbind("SUPER + CTRL + Q")

-- SUPER + SHIFT + S stays Screenshot. Upstream moved Screenshot to SUPER + CTRL + ALT + C and
-- gave SUPER + SHIFT + S to Google Maps (Maps is on SUPER + SHIFT + W here).
o.rebind("SUPER + SHIFT + S", "Screenshot", "omarchy-capture-screenshot")
