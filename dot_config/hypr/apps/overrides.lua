-- Small personal deltas on top of Omarchy's app rules.

-- Float Telegram, centered, 875x600 (floating-window tag, see upstream system.lua).
o.window("org.telegram.desktop", { tag = "+floating-window" })

-- nmtui (launch-wifi, ours) floats like the other Omarchy TUIs.
o.window("org.omarchy.nmtui", { tag = "+floating-window" })

-- gnome-calculator is bound to XF86Calculator.
o.window("org.gnome.Calculator", { float = true })

-- Hide the xwaylandvideobridge artefact window (Hyprland's official fix, see
-- wiki.hypr.land/Useful Utilities/Screen-Sharing).
o.window("xwaylandvideobridge", {
  opacity = "0.0 override 0.0",
  no_initial_focus = true,
  no_focus = true,
  no_anim = true,
  no_blur = true,
  max_size = "1 1",
})
