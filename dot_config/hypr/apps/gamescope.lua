-- gamescope hosts the game in a nested compositor, so from Hyprland's side it
-- is one fullscreen surface. Opt out of the default opacity rule (a
-- translucent game window is never what you want) and hold off idle/lock.
o.window("gamescope", {
  fullscreen = true,
  tag = "-default-opacity",
  opacity = "1 1",
  idle_inhibit = "fullscreen",
})
