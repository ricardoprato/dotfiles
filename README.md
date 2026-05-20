# dotfiles

Personal dotfiles for Arch + Hyprland, managed by [chezmoi](https://www.chezmoi.io/).

Frozen fork of **[Omarchy](https://github.com/basecamp/omarchy)** by David Heinemeier Hansson (©). Upstream code, configs, themes, and CLI binaries are bundled in-tree so the setup is self-contained and reproducible on a new machine without depending on upstream changes.

See [`dot_local/share/omarchy/LICENSE`](dot_local/share/omarchy/LICENSE) for the original MIT terms; personal modifications keep that notice intact as required.

## Layout

```
dot_config/              → ~/.config/        per-app config (one dir per app)
dot_local/share/omarchy/ → ~/.local/share/omarchy/   themes, applications, runtime resources
dot_local/share/fonts/   → ~/.local/share/fonts/     UI icon font
dot_local/bin/           → ~/.local/bin/             omarchy-* CLI binaries (227 scripts)
dot_tmux.conf            → ~/.tmux.conf
dot_XCompose             → ~/.XCompose
private_dot_ssh/         → ~/.ssh/                   (mode 0700)
private_dot_gnupg/       → ~/.gnupg/                 (mode 0700)
system/                  → /etc/ & system-level (NOT chezmoi-managed, copy manually)
```

### chezmoi prefixes

- `dot_<name>` → hidden file (`.<name>`)
- `private_<name>` → mode 0700
- `executable_<name>` → +x
- `symlink_<name>` → file content = symlink target
- `.tmpl` suffix → Go template (only used in `dot_config/fish/*.tmpl` and `dot_config/bat/config.tmpl`)

## Bootstrap (new machine)

```bash
# 1. Install Arch + base packages (Hyprland, kitty, fish, etc.)

# 2. Init chezmoi pointing at this repo
chezmoi init --apply ricardoprato/dotfiles
# Or, if SSH-cloning:
chezmoi init --apply git@github.com:ricardoprato/dotfiles.git

# 3. System-level configs (one-off, with sudo)
sudo cp ~/.local/share/chezmoi/system/grub/grub /etc/default/grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
# Repeat for limine, pacman, sddm, snapper, udev, firefox/policies, etc.
# See dot_local/share/chezmoi/system/<dir>/ for each.

# 4. Enable graphical-session services (already wired via chezmoi-tracked
# symlinks under dot_config/systemd/user/graphical-session.target.wants/)
systemctl --user daemon-reload

# 5. Reboot into Hyprland session.
```

## Default browser (Brave)

Brave is the default for HTTP(S) and for all webapp bindings (`SUPER + SHIFT + *`). Chosen over Zen because it supports Chromium's `--app=<url>` (chromeless PWA windows used by `omarchy-launch-webapp`) and the managed-policy theming hook (`omarchy-theme-set-browser` pushes the active accent into `/etc/brave/policies/managed/color.json`). Zen/Firefox have no equivalent for either.

Wayland flags live in `dot_config/brave-flags.conf` (mirrors `chromium-flags.conf`); Brave reads them automatically on launch.

On a fresh machine, after `chezmoi apply`:

```bash
# 1. Theme policy dir (required for omarchy-theme-set-browser to push colors)
sudo mkdir -p /etc/brave/policies/managed
sudo chmod a+rw /etc/brave/policies/managed

# 2. Default browser + http(s) handlers.
#    NOTE: `env -u BROWSER` is required because dot_config/uwsm/default
#    exports BROWSER=omarchy-launch-browser, which makes xdg-utils refuse
#    to modify the default ("$BROWSER is set and can't be changed").
#    The env var must stay (it points terminal apps at the wrapper);
#    we just unset it for these three commands.
env -u BROWSER xdg-settings set default-web-browser brave-browser.desktop
env -u BROWSER xdg-mime default brave-browser.desktop x-scheme-handler/http
env -u BROWSER xdg-mime default brave-browser.desktop x-scheme-handler/https

# 3. Push initial theme color into Brave
omarchy-theme-refresh
```

Verify: `xdg-settings get default-web-browser` returns `brave-browser.desktop`, and `SUPER + SHIFT + E` (Google Keep) opens a chromeless window.

To switch back to a different browser later: re-run step 2 with the new `*.desktop` name. `omarchy-launch-browser` and `omarchy-launch-webapp` both resolve dynamically via `xdg-settings get`, so no dotfile edits are needed.

## Capture tooling (screenrecord + OCR)

The `omarchy-capture-*` scripts wired in `dot_config/hypr/bindings.lua` orchestrate `hyprpicker` + `slurp` + a tool-specific binary. The tool-specific binaries are NOT pulled in by base Arch / Hyprland — they need explicit install. Failures are silent (stderr piped to `/dev/null`, scripts `exit 1` without notify), so a missing package looks identical to "shortcut does nothing".

```bash
# Screen recording  (ALT + PRINT → screenrecord menu → omarchy-capture-screenrecording)
yay -S gpu-screen-recorder

# OCR text extraction  (SUPER + CTRL + PRINT → omarchy-capture-text-extraction)
sudo pacman -S tesseract-data-eng
# tesseract-data-spa is already pulled in by base; OMARCHY_OCR_LANGS=eng+spa
# (in dot_config/uwsm/env) requires BOTH lang packs — tesseract aborts if any
# requested lang is missing, it does not degrade to "whatever is installed".
```

Verify after install:

```bash
tesseract --list-langs        # expect: eng, osd, spa
which gpu-screen-recorder     # expect: /usr/bin/gpu-screen-recorder
```

`XDG_VIDEOS_DIR` quirk: `~/.config/user-dirs.dirs` may ship pointing at `$HOME/` instead of `$HOME/Videos`. `omarchy-capture-screenrecording` honors it as-is, so recordings land loose in `~`. Fix:

```bash
mkdir -p ~/Videos
sed -i 's|^XDG_VIDEOS_DIR=.*|XDG_VIDEOS_DIR="$HOME/Videos"|' ~/.config/user-dirs.dirs
```

## Optional: dictation (voxtype)

`SUPER + CTRL + X` (toggle) and `F9` (push-to-talk) are pre-wired for [voxtype](https://github.com/jacobwi/voxtype) — local whisper.cpp dictation that types into the active window. Configuration lives in `dot_config/voxtype/config.toml` (default model `base.en`, output mode `type`).

Not installed by default. Install path:

```bash
omarchy-voxtype-install   # pulls voxtype + downloads the whisper model
sudo pacman -S ydotool    # required by output.mode = "type" (simulates kbd input)
```

For Spanish dictation, edit `dot_config/voxtype/config.toml`: `model = "small"`, `language = "es"`.

## Keyboard remapping (kanata)

[kanata](https://github.com/jtroo/kanata) is a kernel-level (uinput) keyboard remapper. Config lives in `dot_config/kanata/config.kbd`; service unit in `dot_config/systemd/user/kanata.service`; auto-enabled via `dot_config/systemd/user/default.target.wants/kanata.service` symlink.

What this fork's config does:

- **Caps Lock** → tap = Escape, hold = Ctrl
- **Home row mods (GACS)** — hold a letter on home row = modifier:
  - Left:  `a`=Super, `s`=Alt, `d`=Ctrl, `f`=Shift
  - Right: `j`=Shift, `k`=Ctrl, `l`=Alt, `;`=Super
- **Double-tap `` ` ``** → toggles a `gaming` layer that disables tap-hold (WASD instant); double-tap again to return.

Tap/hold timing: `tap-time 150` / `hold-time 200` (ms). If mods fire while typing fast, raise `hold-time` to 220–250.

Binary not in base Arch — install path:

```bash
yay -S kanata-bin   # precompiled, avoids cargo build

# udev rule for /dev/uinput access — system-level, not chezmoi-tracked.
# Reference copy lives in system/udev/50-kanata.rules.
sudo cp ~/.local/share/chezmoi/system/udev/50-kanata.rules /etc/udev/rules.d/
sudo groupadd -f uinput
sudo usermod -aG input,uinput "$USER"
sudo udevadm control --reload-rules && sudo udevadm trigger
# Re-login (or reboot) so the group change takes effect.

# Service was auto-enabled by chezmoi apply (default.target.wants symlink);
# just (re)start it on first boot:
systemctl --user daemon-reload
systemctl --user restart kanata
```

Verify:

```bash
systemctl --user status kanata   # expect: active (running)
# Test: Caps tap = Esc in nvim; hold f + c = Ctrl+C in terminal.
```

Emergency exit (in case mods misbehave): physical `Ctrl + Space + Esc` kills the daemon instantly — those keys refer to the BEFORE-remap physical layout, so Caps→Ctrl does NOT count here, use the real Ctrl key.

Pause without disabling: `systemctl --user stop kanata`. Resume: `systemctl --user start kanata`. After editing `config.kbd`: `systemctl --user restart kanata`.

## Workflow

Single branch `main-omarchy`. Edit in source, apply, commit:

```bash
cd ~/.local/share/chezmoi
$EDITOR dot_config/<app>/<file>
chezmoi apply --force
git add -A && git commit -m "..."
```

Themes: `omarchy theme set <name>`. Hooks (`omarchy-restart-btop`, `-bat`, `-waybar`, etc.) re-render configs and reload daemons automatically.

## Conventions

- **Per-app flat**: each app's full configuration lives under its own `dot_config/<app>/` dir. No external "engine" or override layer.
- **systemd user units** for long-running daemons (waybar, mako, hypridle, hyprpolkitagent) instead of Hyprland's `exec_on_start`.
- **`system/` is reference-only**: not applied by chezmoi; consult on new-machine setup.
- **Hyprland config is Lua** (`dot_config/hypr/*.lua`); tool configs (hypridle, hyprlock, hyprsunset, xdph) are `.conf`.

## Constraints

- Arch Linux + Hyprland + Wayland
- Keyboard layout: `latam` (`dot_config/hypr/input.lua`)
- Default terminal: `kitty` (`dot_config/xdg-terminals.list`)
- Shell: `fish`
- Default kernel (when multi-installed): `linux-cachyos` (`system/grub/grub`)

## License

MIT — see [`LICENSE`](LICENSE).

Personal contributions (configs I authored, fish migrations, custom hooks like `restart-bat`) are © 2026 Ricardo Prato under MIT.

Bundled Omarchy code (`dot_local/share/omarchy/`, the `omarchy-*` binaries in `dot_local/bin/`, the Hyprland Lua engine in `dot_config/hypr/`) is © David Heinemeier Hansson, also under MIT — see [`dot_local/share/omarchy/LICENSE`](dot_local/share/omarchy/LICENSE).
