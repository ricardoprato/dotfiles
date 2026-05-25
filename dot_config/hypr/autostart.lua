-- Apps moved to systemd user units (see dot_config/systemd/user/graphical-session.target.wants/):
--   hypridle, mako, waybar, hyprpolkitagent (replaces polkit-gnome-authentication-agent-1)

o.launch_on_start("fcitx5 --disable notificationitem")
o.launch_on_start("kdeconnect-indicator")
o.launch_on_start("swaybg -i ~/.local/state/dotfiles/current-background -m fill")
o.exec_on_start("uwsm app -- hyprsunset")
o.exec_on_start("omarchy-first-run")
o.exec_on_start("omarchy-powerprofiles-init")
o.launch_on_start("omarchy-hyprland-monitor-watch")

-- Slow app launch fix -- set systemd vars.
o.exec_on_start("systemctl --user import-environment $(env | cut -d'=' -f 1)")
o.exec_on_start("dbus-update-activation-environment --systemd --all")

-- Run post-boot hooks after startup config has loaded.
o.exec_on_start("sleep 2 && omarchy-hook post-boot")

-- Pin core apps to specific workspaces on login.
-- `[workspace N silent]` is parsed by Hyprland's exec dispatcher and only
-- applies to the first window spawned by each command -- later kitty / brave
-- windows opened manually still land on the focused workspace.
-- Terminal/browser resolve via xdg defaults, so changing the system default
-- (xdg-terminals.list / xdg-settings) requires no edit here.
o.exec_on_start("[workspace 1 silent] " .. o.launch("xdg-terminal-exec"))
o.exec_on_start("[workspace 2 silent] omarchy-launch-browser")
o.exec_on_start("[workspace 10 silent] " .. o.launch("thunderbird"))
