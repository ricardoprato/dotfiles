# Feature: Adopt upstream omarchy-shell

## Objective
Replace waybar, walker, mako, swayosd, hyprlock, hypridle and the polkit agent
with upstream's Quickshell-based omarchy-shell (branch `quattro`), keeping the
fork's chezmoi layout, theming pipeline, bindings and WSL gating.

## Inputs
- Upstream ref clone: `/tmp/claude-1000/-home-redfoxd--local-share-chezmoi/7aa1b2e6-290f-4825-b899-5b2a5156f546/scratchpad/up/omarchy` (`up/main`).
- Migration plan: `/tmp/claude-1000/-home-redfoxd--local-share-chezmoi/7aa1b2e6-290f-4825-b899-5b2a5156f546/scratchpad/omarchy-shell-plan.md`.
- Done prerequisites: semantic palette + renderer (odd/tasks/omarchy-aesthetics.md),
  NetworkManager (odd/tasks/networkmanager-migration.md).

## Decisions (2026-10-19)
- Network: NetworkManager (done), shell network panel enabled.
- Lock: shell lock; PAM files via a user-run sudo script; hyprlock stays
  installed as fallback until the shell lock is verified.
- Agents/usage/accounts plugins on (user opted in 2026-10-19); bindings
  SUPER+CTRL+SHIFT+A agent picker added in T5. Herdr stays out (separate feature).
- Defaults taken by the parent (user may override): i18n vendored for en + es only; no new
  wallpapers for existing themes; fork bindings win, only shell dispatchers
  are ported; apps not packaged for Arch (omacalc, omawrite, titlebars, ttfx)
  dropped from binds and dock.

## Constraints
- Desktop never broken between commits: shell lands alongside the old stack,
  switch-over is one commit, removal is a later commit.
- `chezmoi apply` never deletes dropped targets: use `.chezmoiremove`.
- New desktop files and packages gated for `platform=wsl`.
- Vendored upstream code committed in isolation (review noise).

## Tasks
- [x] T1 Theme compat for the shell: `~/.local/state/omarchy/current/{theme,theme.name,background}` links, `shell.toml.tpl` + missing renderer tokens (route: delegated writer)
- [x] T2 Vendor `shell/`, shell defaults, `shell.json`, `$OMARCHY_PATH` symlinks, wsl ignore (route: delegated writer)
- [x] T3 Shell bins (`omarchy-shell`, launch/restart, thin menu helpers, notification-send, audio/brightness/network/bluetooth helpers) + `desktop` packages (route: delegated writer)
- [x] T4 Smoke test alongside waybar with conflicting plugins disabled; no commit (route: delegated verifier)
- [x] T5 Hypr helpers/paths/shortcuts for shell dispatchers (route: delegated writer)
- [x] T6 User-run sudo script for shell lock PAM files (route: delegated writer + user-run)
- [x] T7 Switch-over: autostart, bindings, menu, lock, idle, toggles, theme-set, `.chezmoiremove` (route: delegated writer; live switch done, user relogin pending)
- [x] T8 Remove old stack (waybar/walker/mako/swayosd/hyprlock/hypridle, templates, units, obsolete bins) (route: delegated writer)
- [x] T9 Shell-dependent extras: dock/minimize, workspace layouts, per-monitor workspaces, network/audio/bluetooth/weather tooling (route: delegated writer)

## Delivery
exception-ok (direct commits on main-omarchy). One commit per task; T2 isolated.

## Progress / evidence
- T1 done (route: delegated writer). The shell reads `current/theme/{colors.toml,
  shell.toml,backgrounds}`, `current/background`, `current/theme.name` under
  `~/.local/state/omarchy`. theme-set now builds `$DOTFILES_STATE_PATH/current/theme`
  (symlinks to every file of the source theme except shell.toml, which the
  renderer writes there; a theme-shipped shell.toml wins as upstream) and links
  `~/.local/state/omarchy/current/{theme,theme.name,background}` to it and to
  `current-theme` / `current-background`. Renderer gained `gradient_start`,
  `shell_gradient`, `color_to_shell_hex` (ported) and a `shell.toml` destination
  exception; `shell.toml.tpl` ported verbatim. Live push `omarchy-shell shell
  applyTheme` runs only when a quickshell on `omarchy/shell` is running.
  Not ported: `shell.<section>.toml` per-section overrides (no fork theme ships
  one; upstream only tokyo-night has `shell.lock.toml`). Checks: all 23 themes
  `omarchy-theme-set` rc=0, shell.toml 235 lines with 0 `{{`; hackerman
  active-border renders the gradient, catppuccin the solid accent; current/ links
  resolve; `bash -n` + shellcheck clean; waybar still running; theme restored to
  catppuccin.
- T2 done (route: delegated writer). Vendored up/main `shell/` (238 files, 5
  `executable_` for the .sh helpers), `default/omarchy/{launcher.hides,
  omarchy-menu.jsonc,shortcuts}`, `default/input-methods/*` (5),
  `default/i18n/{en,es-MX,plural.jq,locales.json}`, `config/omarchy/shell.json`
  under `dot_local/share/omarchy/` (257 files, commit 758a9a7, alone). Skipped
  `default/omarchy/sudo-no-update` (update plumbing). Glue commit: `symlink_bin`
  (-> ../../bin = ~/.local/bin), `symlink_themes` (-> ../dotfiles/themes),
  locales.json trimmed to en + es-MX so the language picker offers only vendored
  catalogs, wsl ignore for bin/config/default/shell/themes. Note: applying
  replaced the stale May copy of `~/.local/share/omarchy/themes` (102M real dir,
  duplicate of repo themes, only read by omarchy-theme-list) with the symlink.
  Checks: `diff -r` shell vs up/main identical (238 files, 5 executable);
  defaults identical; `chezmoi apply` ok; `chezmoi -c <wsl cfg> ignored` lists
  the 5 paths, native lists none.
- T3 done (route: delegated writer). Ported 52 upstream bins verbatim (shell/
  launch-shell/restart-shell/shell-config, bar/dock/osd/toggle-bar, i18n/language/
  input-method, audio-output-*, audio-input-set-default, bluetooth-{device,power},
  network-{status,qr,password,band,speedtest}, dns, clipboard-*, hyprland-{focus-app,
  session-locked,session-lock-stranded,workspace-layout-current/default,
  monitor-{scaling,clamshell,laptop,external-active}}, hw-{display,clamshell,
  laptop-closed}, monitor-state, system-{sleep-lock,stats}, weather-location,
  menu-{emoji-insert,timezone}, plugin-catalog, remove-launcher-entry, ...).
  Skipped on purpose: audio-tuning/restart-audio (need default/audio),
  default-dictation, locale-generate (root sudoers), channel-current, agent-*,
  tailscale-*, theme-bg-boot-intro (OWE). Fork-authored: `shell-running` (IPC
  ping; wsl-gated) and Walker fallbacks in `omarchy-menu-{select,input}`; the
  ported `omarchy-menu-file` is upstream's. Without a shell they behave exactly
  as before (stub-walker args identical). `omarchy-theme-set` now uses
  `shell-running` instead of pgrep.
  Same-named fork bins kept (live stack): menu, menu-images, notification-send
  (fork prefixes the glyph and calls notify-send; upstream uses busctl with
  hints + --exec/-r/-p), system-lock (hyprlock), toggle-nightlight/idle,
  brightness-display (swayosd), battery-status, reminder, powerprofiles-*,
  theme-switcher, theme-bg-switcher, weather-status, workspace-layout-toggle.
  T7 swaps these for upstream's. Packages added to `desktop`: bluez, bluez-tools,
  ddcutil, ffmpeg, hyprland-guiutils, inotify-tools, libvips, mpv-mpris,
  qrencode, qt6-{base,declarative,imageformats,multimedia,svg,wayland}, wtype,
  zbar; user must run the installer for the 6 not yet installed (bluez-tools,
  ddcutil, mpv-mpris, qrencode, wtype, zbar). Checks: `bash -n` all; shellcheck
  warnings only upstream style (SC2155 etc.); all 53 new bins in wsl ignore;
  `omarchy-theme-set catppuccin` rc=0; `omarchy-i18n`/`omarchy-language` run;
  waybar still running; `omarchy-shell shell ping` -> "not running" rc=1.
- T3 addendum (agents opt-in, 2026-10-19). Ported all 21 `omarchy-agent*` and
  `omarchy-default-agent` bins verbatim (7 python3, rest bash; no account/usage
  command was run, only `bash -n` on bash ones and shellcheck: SC1071/SC2164
  from the python shebangs and upstream style). Agents plugin is vendored and
  the shipped shell.json has no `disabledPlugins`. Crash bins
  (`omarchy-crash-watch/-mute`) left out: the plugin does not call them.
  Install helpers the agent bins reference are not ported yet:
  `omarchy-install-{chromium-claude,hermes-cli,openclaw-cli}`,
  `omarchy-launch-openclaw`, `omarchy-mise-{default-tools,install}`.
  All agent bins are wsl-gated (they serve the desktop shell plugin; tokens stay
  on the desktop). Heads-up: enabling the plugin makes its Main.qml run
  `omarchy-agent-usage-update` (reads agent tokens, calls vendor usage APIs).
- T4 done (route: delegated verifier, no code commit besides one fix). Launched
  `omarchy-launch-shell` from the real `~/.local/share/omarchy/shell` with a
  temporary HOME/XDG_CONFIG_HOME in the scratchpad (symlinks to the real config,
  override shell.json: bar at bottom, notifications/polkit/lock/osd/idle/
  background/dock/clipboard/nightlight/battery/reminders listed in
  `disabledPlugins`; agents left unloaded) and a scratchpad PATH dir with upstream copies of the
  collision bins. Not in the repo. Results: `omarchy-shell shell ping` ok,
  `listPlugins` 40, waybar (top) and shell bar (bottom) side by side, root menu,
  network panel with the REAL NetworkManager (connected SSID, band, DNS, known
  and other networks), audio panel (outputs/inputs) and bluetooth panel (paired
  devices) all render; journal tag `omarchy-shell`: only WARNs (playerctld has no
  player; desktop-entry line; missing `omarchy-theme-bg-boot-intro` in the first
  run, fixed by porting it). Shell killed; `pgrep -af quickshell` = only the
  pre-existing select-by-image daemon (same as before); mako/waybar untouched.
  The agents panel was not opened: loading the plugin triggers usage-update
  (tokens + vendor APIs). Screenshots: `shell-smoke/0{1-5}-*.png` in the session scratchpad.
  FINDINGS for T7 (the fork versions of these bins lack the flags the shell
  calls; they must be replaced by upstream's when the shell goes live):
  `omarchy-capture-screenrecording --status` (the fork script ignores it and
  starts the region picker: with the shell's indicators polling it, stuck
  hyprpicker/slurp overlays covered the screen on the first run), `battery-status
  --shell`, `powerprofiles-list --active-state`, `sudo-passwordless --active`,
  `theme-switcher --print-rows`, `reminder show --json`, `notification-send`
  (hints, --exec). The `disabledPlugins` key did not stop the startup cover
  (`omarchy-background` layer, black until the boot-intro helper exits); the
  helper was ported (exits 0 without OWE). It writes
  `~/.local/state/omarchy/background-intro.session-id`; removed after the test.

- T5 done (route: delegated writer, together with T6). `helpers.lua` gained upstream's
  `o.shell_quote/shell_succeeds/cmd_present/cmd_missing/rebind` and the
  `{menu=}{panel=}{audio=}{brightness=}{ipc=}` dispatchers: each resolves to
  `hl.dsp.global("omarchy:<kind>.<target>")` when `$OMARCHY_PATH/default/omarchy/
  shortcuts` lists it, else to the plain command fallback (`omarchy-menu toggle`,
  `omarchy-shell shell toggle`, ...). `paths.lua` takes upstream's `env_or` (empty
  var = unset), fork default path kept. Not ported (YAGNI until T9): `bind_hold`,
  `launch_terminal`, `bind_commands`, `floating_apps`, `transparent_window`,
  `require_all` exclude, `omarchy-shell` layer rules. New bins verbatim from up/main:
  `omarchy-hyprland-window-width`, `omarchy-toggle-fullscreen-desktop` (already
  wsl-gated by the `omarchy-hyprland-*` / `omarchy-toggle-*` globs; monitor-scaling,
  input-method, agent bins were already ported and identical).
  Binds added (fork file `bindings.lua`): SUPER+Q close; SUPER+code:49 / SUPER+SHIFT+
  code:49 scratchpad toggle / move (physical grave key, keysym GRAVE is not reachable
  on latam); SUPER+Home / SUPER+ALT+Home window width restore / save; SUPER+code:61 /
  SUPER+ALT+code:61 monitor scaling up / down (replace the old cycle binds, same physical
  key; SLASH needs Shift on latam); SUPER+A select all; SUPER+I / SUPER+SHIFT+I input
  language cycle; SUPER+CTRL+ALT+F fullscreen desktop; SUPER+CTRL+SHIFT+A agent picker.
  SUPER+C/V/X now upstream's (CTRL+C/V, CTRL+SHIFT+C/V in terminals tagged `terminal`,
  focused surface instead of `activewindow`). Skipped: SUPER+CTRL+Q (`omacalc` is not on
  Arch; XF86Calculator keeps gnome-calculator), SUPER+ALT+L layout back (needs the
  workspace-layouts module, T9), Herdr, SUPER+ALT+SHIFT+E, webcam-resize, XF86Eject,
  SHIFT+XF86Audio*. All user conflict keys unchanged. `hyprctl binds -j` before/after
  (matching modmask|key|description): 204 -> 214; +12 added (A, Home x2, I x2, Q,
  scratchpad x2, agent, fullscreen desktop, scaling up/down), -2 removed (the two
  scaling-cycle binds); nothing else differs.
  Not-yet-loaded `dot_config/hypr/shell-bindings.lua`: o.rebind of every key whose
  waybar/walker/mako/swayosd action the shell replaces (menus, panels, volume/
  brightness/media, notifications) plus the shell-only ones (SUPER+CTRL+D/P/ALT+D/E,
  SUPER+CTRL+1..9, SUPER+ALT+SPACE dock, ALT+XF86AudioPlay); SUPER+M waits for T9.
  Notification keys use lower-case `comma` (xkbcommon name); the fork's current
  upper-case `COMMA` binds probably never match, worth a check. T7 flips by adding
  `require("hypr.shell-bindings")` after `hypr.bindings` in `hyprland.lua`.
  Checks: `hyprctl reload` + `hyprctl configerrors` empty after helpers/paths and after
  bindings; temporary `hyprctl eval 'require("hypr.shell-bindings")'` -> errors empty,
  214 -> 229 binds, then `hyprctl reload` restored the exact 214 set; `omarchy-hyprland-
  window-width save` then `restore` on the active kitty window rc=0 (saved 1176, no
  resize), state file removed; `omarchy-toggle-fullscreen-desktop on` then `off` rc=0,
  bar-off/no-gaps y/y then n/n; `bash -n` + shellcheck clean on both bins; waybar still
  running. Not exercised (disruptive or side effects): monitor-scaling up/down,
  input-method cycle, agent picker, SUPER+C/V/X key delivery.

- T6 done (route: delegated writer + user-run). `dot_local/bin/executable_shell-lock-setup-pam`
  (ours: plain header, wsl-gated in `.chezmoiignore`, refuses on WSL, `--dry-run`, `sudo -v`
  up front, idempotent via `cmp`, replaced/removed files copied with `cp -a --parents` to
  `/var/backups/shell-lock-pam-<ts>/`). Upstream's only lock PAM source is `bin/omarchy-
  apply-lock` (no etc/pam.d files, no FIDO2 service for the lock; the plugin reads
  `omarchy-lock-password` and `omarchy-lock-fingerprint` only). Installs verbatim:
  `/etc/pam.d/omarchy-lock-password` (always; the plugin's `missing-pam` check is exactly
  `FileView /etc/pam.d/omarchy-lock-password` loading, hence mode 644), and, only when
  `fprintd-list $user` shows enrolled fingers, `/etc/pam.d/omarchy-lock-fingerprint` plus
  fprintd's `system-sleep/fprintd-resume` hook (755) and `10-stop-timeout.conf` drop-in
  (+ `daemon-reload`, embedded as heredocs since `default/systemd` is not vendored). With no
  fingers/package the fingerprint files are removed (harmless), a failed probe keeps the
  current state. Preconditions: pam_faillock/pam_unix and `system-local-login` exist.
  Checks: `bash -n` + shellcheck clean; `shell-lock-setup-pam --dry-run` rc=0 without sudo
  (this machine: fingers enrolled, nothing installed yet -> plans the 4 files as `new`);
  `chezmoi -c <wsl cfg> ignored` lists it, native does not. NOT run (needs sudo).
  User must run: `shell-lock-setup-pam` (then `omarchy-shell lock status` once the shell runs).

- T7 done (route: delegated writer; live switch run in the user's session, authorized).
  Commits: 59b07f5 (upstream shell-aware bins), 777cbdf (menu swap), a6f6e9d (theme-set
  and pickers), 3c2af62 (hypr switch, autostart, units, `.chezmoiremove`), 3bac3a6
  (sudo-passwordless flags). Inventory: every `omarchy-*` the vendored shell invokes was
  checked against the fork copy; the ones lacking its flags or still tied to the old
  stack now come from up/main: battery-status, brightness-display(+apple,+ddc),
  brightness-keyboard, capture-screenrecording (+ capture-region, -process, webcam-list/
  -resize), notification-send, powerprofiles-list/-set, reminder, system-wake,
  toggle-idle/-nightlight/-notification-silencing, weather-icon/-status, font-set/-current,
  cmd-/pkg- helpers, launch-tui/-or-focus-tui/-floating-terminal-with-presentation (+
  restart-gum, show-done), audio-input-mute, menu (thin wrapper), menu-images,
  theme-switcher/-bg-switcher/-bg-set/-remove and launch-screensaver (these five with the
  fork `$DOTFILES_*`, `~/.config/dotfiles` and per-app default paths re-applied).
  Fork behavior kept: launch-webapp chromium fallback, launch-wifi, restart-app (systemd
  unit first) and the restart-* scripts are untouched files; system-lock = shell lock +
  rbw vault lock (no 1Password, no hyprlock); weather location moved from
  `OMARCHY_WEATHER_LOCATION` to `~/.local/state/omarchy/settings/weather.json` (chezmoi
  `create_`, seeded Buenos Aires -34.61,-58.38; env var dropped from `uwsm/env`); active
  power profile mark = the shell provider's native current row; no Sunshine entry exists in
  the fork menu nor in upstream's default jsonc, so no extension file was needed; theme-set
  pipeline kept (only the waybar/swayosd/mako/walker restarts dropped; the shell recolors
  through applyTheme). Not taken from upstream, adapted in place: omarchy-sudo-passwordless
  (upstream is a package-installed root rewrite; fork script gained `--active`/`--disable`
  and an indicator refresh), audio-output-switch, toggle-touchpad/-touchscreen (swayosd ->
  `omarchy-osd`), menu-keybindings, menu-tmux-keybindings, yazi-kdeconnect-share (walker ->
  `omarchy-menu-select`). Hypr: `hyprland.lua` loads `hypr.shell-bindings` after bindings,
  autostart runs `omarchy-launch-shell` (swaybg and first-run dropped), `apps/omarchy-shell.lua`
  from upstream, the four waybar-position binds removed; hyprlock.conf/hypridle.conf stay as
  unused fallback; hyprlock package stays. Units: the six `graphical-session.target.wants`
  symlinks (hypridle, mako, polkit-gnome, swayosd-server, walker, waybar) left the source and
  are listed in `.chezmoiremove`; unit files stay for T8.
  Checks (live): `chezmoi apply --force --no-tty --exclude=scripts,externals` ok; `hyprctl
  reload` + `hyprctl configerrors` empty; old units stopped (all six `is-active` inactive,
  `is-enabled` disabled), elephant/swaybg/select-by-image quickshell killed, `pgrep` shows no
  waybar/walker/mako/swayosd/hypridle/polkit-gnome; `omarchy-launch-shell` detached ->
  `omarchy-shell shell ping` ok; `journalctl -t omarchy-shell --since -5min` only WARN
  (unrecognized pragma, QString::arg missing placeholders for dock.noAppsMatch /
  common.uninstallConfirm / clock.monthYear / elsewhen.here, playerctld no player, invalid
  desktop-entry line, input-keyboard-symbolic icon, invalid SNI registration); `busctl --user
  status org.freedesktop.Notifications` owner quickshell, `GetServerInformation` = quickshell;
  `notify-send` rendered as a shell card; `omarchy-osd -i volume -p 40` and the
  `omarchy:audio.raise/lower` global shortcuts show the OSD; `omarchy-menu summon root` opens
  the shell menu; network panel lists the NM connection (Blueorange 5 GHz, DNS, known
  networks); `omarchy-shell lock status` -> passwordPam true, fingerprint true (not locked);
  journal: `omarchy polkit agent registered`, `idle-monitor: active` (idle 150 s screensaver /
  300 s lock from the seeded `~/.config/omarchy/shell.json`); `omarchy-theme-set catppuccin`
  -> `tokyo-night` -> `catppuccin` rc 0, bar pixel #1E1E2E -> #1A1B26 live;
  `omarchy-capture-screenrecording --status`, `battery-status --shell`, `powerprofiles-list
  --active-state`, `reminder show --json`, `theme-switcher --print-rows`, weather-status/icon
  all answer without launching a picker, no slurp/hyprpicker process; `hyprctl binds`: 214 ->
  225, diff is exactly shell-bindings (rebinds + bar panels 1-9, display/power/calendar/world
  clock, ALT+XF86AudioPlay) plus the four removed waybar-position binds and the
  COMMA -> comma notification binds; `chezmoi diff` empty afterwards; `bash -n` on all touched
  bins. Screenshots: `t7/{notif,osd,menu,network,theme-catppuccin,theme-tokyo-night,bar}.png`
  in the session scratchpad. Not exercised (user must test): real lock/unlock with password and
  with fingerprint, idle timeout (screensaver at 2.5 min, lock at 5 min), relogin (autostart
  was reproduced by launching `omarchy-launch-shell` by hand), `sudo-passwordless --active`
  on a grant, shell dock (no minimize yet, T9). Notes: the shell seeded
  `~/.config/omarchy/shell.json` itself (not chezmoi-tracked; decide in T8/T9 whether to track
  it); `powerprofilesctl` fails under mise's python in non-desktop shells (gi missing), the
  desktop session path is unaffected.
  Rollback recipe (live): `git revert --no-edit 3bac3a6 3c2af62 a6f6e9d 777cbdf 59b07f5` (newest
  first), `chezmoi apply --force --no-tty --exclude=scripts,externals`, `pkill -f 'quickshell -n
  -p'` (or `omarchy-shell shell ping` first; refuses while locked), then `systemctl --user enable
  --now walker.service waybar.service mako.service swayosd-server.service polkit-gnome.service
  hypridle.service` (units still ship; the revert restores the wants links and drops
  `.chezmoiremove`), `hyprctl reload`. hyprlock is still installed for a TTY-safe fallback.

- T8 done (route: delegated writer; commits 1a90517 configs/units/templates, 087432b bins,
  5d7e6d8 powerprofiles fix, 91341c0 packages, plus this doc). Removed from source: app dirs
  waybar, walker, mako, swayosd, elephant, quickshell (select-by-image.qml; nothing in the
  source started its daemon, it came from the old fork `omarchy-menu-images`, which now drives
  the shell `image-selector`), hypr `hypridle.conf`/`hyprlock.conf`/`apps/walker.lua`, units
  polkit-gnome/swayosd-server/walker, six themed templates (hyprlock, mako, quickshell, swayosd,
  walker, waybar) and the hyprlock destination exception, toggle stubs `empty_mako.ini` and
  `empty_walker.css`, 20 bins (launch-walker, restart-{waybar,walker,mako,swayosd,hypridle},
  toggle-waybar, style-waybar-position, swayosd-{client,brightness,kbd-brightness},
  style-corners-{hyprlock,mako,walker}, notification-dismiss, voxtype-{status,config},
  launch-{audio,bluetooth}, update-available-reset). `bindings.lua` lost 14 binds the shell
  bindings replace (swayosd volume/media, walker menus, makoctl, toggle-waybar); the matching
  `o.rebind`s stay (harmless, and they unbind the rest). Callers repointed or trimmed:
  menu-input/menu-select (walker fallback gone, shell only), style-corners (hyprland only),
  tz-select, voxtype-install/-model, webapp-remove(-all), first-run, setup-security-fingerprint
  (hyprlock icon), update-perform, omarchy group descriptions, theme-set-templates. All deployed
  targets are in `.chezmoiremove` (6 whole app dirs, hypr files, 3 units, 3 state toggles, 6
  installed templates, 20 bins). Packages dropped from `packages.toml`: waybar, walker,
  elephant-*-bin (10), mako, swayosd, hypridle, hyprlock, polkit-gnome. `.chezmoiignore` wsl block
  lost the six dead app dirs and `omarchy-swayosd-*`. Fix: `omarchy-powerprofiles-{list,set}`
  call powerprofilesctl with `/usr/bin` first in PATH (mise python lacks gi); upstream clone was
  gone (tmp wiped) so no upstream comparison. `--active-state` -> `power-saver 0 / balanced 1 /
  performance 0`. `~/.config/omarchy/shell.json`/`shell.toml` stay untracked runtime state
  (no source, apply cannot clobber), documented in the local CLAUDE.md, whose layout, theming and
  service sections were rewritten for the shell.
  Kept with reason: `omarchy-hyprland-session-lock-stranded` (pgrep still lists hyprlock, harmless
  guard), `shell-running` (theme-set uses it), `omarchy-menu-images` (already shell-backed),
  `omarchy-style-corners` (thin wrapper), `omarchy-system-{logout,reboot,shutdown}` and
  `omarchy-wifi-powersave` (unrelated to the old stack), `swaybg` package (not on the T8 list),
  voxtype default config comment, `omarchy-skill/SKILL.md` (external doc, never touched), the
  vendored shell tree.
  Checks: dead-ref sweep (source minus odd/, CLAUDE.md, vendored shell) leaves only those kept
  items; `chezmoi apply` ok then `chezmoi diff` empty; all `.chezmoiremove` targets absent from
  $HOME; `hyprctl reload` + `configerrors` empty; `omarchy-shell shell ping` ok; `omarchy-theme-set
  catppuccin` rc 0, no template errors, no waybar/walker/mako dirs recreated; `chezmoi -c <wsl cfg>
  managed` has no desktop dirs; no select-by-image/waybar/walker/swayosd/hypridle/elephant
  process; `bash -n` clean on every touched bin. FINDING: after the reboot `mako` (package still
  installed, D-Bus activation file `fr.emersion.mako.service`) had claimed
  `org.freedesktop.Notifications` before the shell; `systemctl --user stop mako.service` and the
  shell took the name back at once. Removing the package fixes it for good.

- T9 done (route: delegated writer; commits 0735b13 layouts, 41bf6aa minimize, 3b81564 per-monitor,
  45deac1 helpers, plus this doc). Layouts: `workspace-modes.lua`/`workspace-layouts.lua` ported
  (requires renamed to `hypr.*`), `toggles.lua` loads layouts last, `omarchy-hyprland-workspace-layout-
  toggle` replaced by upstream's (dwindle -> scrolling -> floating, per-workspace files under
  `~/.local/state/omarchy/workspace-layouts`, notification via the shell); SUPER+L keeps its key,
  SUPER+ALT+L cycles back. Default stays dwindle (no saved file = nothing changes). helpers gained
  `o.floating_apps` (recorded by `o.window`) and `o.bind_expressions`. BUG FOUND AND FIXED: the bar's
  workspace buttons dispatch `o.workspaces.focus(..)`, which did not exist since T7 (nil index); helpers
  now define a global-numbering fallback that monitor-workspaces overrides. Minimize: upstream bin
  verbatim, `SUPER+M` in `shell-bindings.lua`; it only acts on floating workspaces because the dock
  only shows there (upstream design). Dock pins (untracked `~/.config/omarchy/shell.json`, set with
  `omarchy-dock pinned`): Nautilus, brave-browser, kitty (omacalc/omawrite/X/YouTube/chromium/foot
  dropped; uninstalled pins were already hidden by the dock). Per-monitor: module ported verbatim,
  opt-in via `hypr-monitor-workspaces on|off|toggle|status` (ours, wsl-gated) which copies
  `hypr/toggles/monitor-workspaces.lua` (loads the module, rebinds the number/arrow keys, adds
  SUPER+SHIFT+CTRL+arrows window-to-monitor); `off` removes the block state files the bar reads.
  Helpers: kept out as unused: `bind_hold`, `launch_terminal`, `bind_commands`, `transparent_window`,
  `require_all` exclude, `omarchy-hyprland-titlebars` plugin (not on Arch; modes skip it when absent).
  Shell layer rules (dock, dock-apps, ...) were already in `apps/omarchy-shell.lua`. Tooling: inventory
  of every `omarchy-*` the shell tree and the default menu name vs `dot_local/bin`; ported
  hw-{laptop,x86,webcam,fingerprint}, capture-{qr,text,screenrecording-with-webcam}, network-wifi-
  connected, sleep-disabled, restart-audio, launch-config-editor, toggle-animations (+ `no-animations`
  flag), plugin-{add,list,clone,remove,enable,disable,validate}, menu-plugin, git-url-check (verbatim,
  wsl-ignored). Deliberately not ported: audio-tuning (+ default/audio: per-model speaker tunings
  for Asus/Dell, the panel only skips their sinks), hw-aarch64-apple and hw-platform (Apple Silicon),
  channel-current, default-dictation (update channel / dictation picker, fork has its own voxtype),
  theme-extras, sudo-docker, system-factory-reset (btrfs, destructive), crash-watch/toggle-crash-
  capture (no plugin calls the watcher), tailscale-send/receive and herdr items (Tailscale plugin is
  disabled, Herdr is a separate feature), install-*/remove-* menu actions (pruned from the fork on
  purpose), webapp-handler, emacs, dgx-spark. Menu `when` guards on these simply hide the entries.
  Checks: `hyprctl reload` + `configerrors` empty after each unit; `hyprctl binds -j` diffs: layouts
  +SUPER+ALT+L and the SUPER+L description, minimize +SUPER+M, per-monitor on +4 SUPER+SHIFT+CTRL+
  arrows (off: identical to before); ws 9 cycled dwindle -> scrolling -> floating -> back, state file
  removed; test kitty (class t9test) on floating ws 9: `omarchy-hyprland-window-minimize` moved it to
  `special:minimized`, the dock showed it (screenshot), moving it back and closing it left no client;
  `hypr-monitor-workspaces on` (eDP-1 block 0 written to the state file, `o.workspaces.focus(3)` ok)
  then `off` (state files gone, workspace ids 1/2/10 unchanged, `o.workspaces.move_window` nil again,
  binds identical); `omarchy-toggle-animations off`/`on` flips `animations:enabled`; `hw-laptop`,
  `hw-x86`, `hw-webcam`, `hw-fingerprint`, `network-wifi-connected` rc 0, `sleep-disabled` rc 1,
  `plugin-list` lists plugins; `bash -n` + shellcheck (warning level) clean on all new bins; `chezmoi
  -c <wsl cfg> managed` lists none of the new desktop paths; `omarchy-shell shell ping` ok.
  Not exercised: SUPER+M/SUPER+ALT+L key delivery, real 2-monitor behavior of per-monitor workspaces,
  `omarchy-restart-audio` (restarts pipewire), capture-qr/-text (region picker), plugin add/enable.

## Next step
Optional follow-ups, each a separate decision: Herdr as its own feature; whether `~/.config/omarchy/shell.json` (dock pins, clock, zones) should be tracked in chezmoi; GTK glass symlink for Ghostty blur (`gtk/glass.css`); remove the `mako` package (it still wins the notifications D-Bus name after a reboot, T8 finding); user hand-test of per-monitor workspaces on a second monitor.
