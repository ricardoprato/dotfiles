-- Personal autostart. Omarchy's defaults already start the shell, power
-- profiles, the monitor watcher, udiskie and the post-boot hook.
o.launch_on_start("fcitx5 --disable notificationitem")
o.launch_on_start("kdeconnect-indicator")
o.exec_on_start("uwsm app -- hyprsunset")

-- Slow app launch fix -- also hand the whole environment to the systemd user manager.
o.exec_on_start("systemctl --user import-environment $(env | cut -d'=' -f 1)")

-- Pin core apps to specific workspaces on login.
-- `[workspace N silent]` is parsed by Hyprland's exec dispatcher and only
-- applies to the first window spawned by each command -- later kitty / brave
-- windows opened manually still land on the focused workspace.
-- Terminal/browser resolve via xdg defaults, so changing the system default
-- (xdg-terminals.list / xdg-settings) requires no edit here.
o.exec_on_start("[workspace 1 silent] " .. o.launch("xdg-terminal-exec"))
o.exec_on_start("[workspace 2 silent] omarchy-launch-browser")
o.exec_on_start("[workspace 10 silent] " .. o.launch("thunderbird"))
