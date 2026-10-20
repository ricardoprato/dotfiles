-- Look'n'feel deltas on top of Omarchy's defaults.

hl.config({
  general = {
    -- Upstream grabs the window border to resize; we only resize with the keys.
    resize_on_border = false,
  },

  decoration = {
    shadow = {
      enabled = true,
      range = 2,
      render_power = 3,
      color = "rgba(1a1a1aee)",
    },

    blur = {
      enabled = true,
      size = 2,
      passes = 2,
      special = true,
      brightness = 0.60,
      contrast = 0.75,
    },
  },

  group = {
    groupbar = {
      indicator_height = 0,
    },
  },
})

-- Slide the scratchpad in vertically.
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "easeOutQuint", style = "slidevert" })
