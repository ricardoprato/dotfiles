-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/

o.window(".*", { suppress_event = "maximize" })

-- Tag all windows for default opacity (apps can override with -default-opacity tag).
o.window(".*", { tag = "+default-opacity" })

-- Fix some dragging issues with XWayland.
hl.window_rule({
  match = {
    class = "^$",
    title = "^$",
    xwayland = true,
    float = true,
    fullscreen = false,
    pin = false,
  },
  no_focus = true,
})

-- Hide xwaylandvideobridge artefact window (Hyprland official fix).
-- Opacity=0 + no_focus + no_initial_focus is enough to mask it.
o.window("xwaylandvideobridge", {
  opacity = "0.0 override 0.0",
  no_initial_focus = true,
  no_focus = true,
})

-- App-specific tweaks (may remove default-opacity tag).
require("hypr.apps")

-- Apply default opacity after apps have had a chance to opt out.
o.window({ tag = "default-opacity" }, { opacity = "0.97 0.9" })
