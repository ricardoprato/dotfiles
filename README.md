# dotfiles

My personal [chezmoi](https://www.chezmoi.io/) overlay on top of
**[Omarchy](https://github.com/basecamp/omarchy)** (Arch + Hyprland), created by
David Heinemeier Hansson and the Omarchy contributors. See the
[Omarchy manual](https://learn.omarchy.com/) for the system itself.

This repository is **not** a copy or fork of Omarchy. It holds only my own
configuration, plus a few whole-file overrides of Omarchy scripts. Omarchy
itself is downloaded by chezmoi at a pinned commit.

## Requirements

- Arch Linux or CachyOS with kernel, bootloader and microcode already installed
  (chezmoi manages userland only).
- `git` and `chezmoi`.
- Network access on the first apply (Omarchy and the nvim config are fetched).

The Omarchy pin lives in [`.chezmoidata/omarchy.toml`](.chezmoidata/omarchy.toml);
[`.chezmoiexternal.toml.tmpl`](.chezmoiexternal.toml.tmpl) extracts that commit
to `~/.local/share/omarchy-upstream` (`$OMARCHY_PATH`, set in
`dot_config/uwsm/env`). Never edit files there: apply re-extracts them.

## Install on a new machine

```bash
sudo pacman -S --needed git chezmoi
chezmoi init --apply git@github.com:ricardoprato/dotfiles.git
```

`init` asks once and stores the answers in `~/.config/chezmoi/chezmoi.toml`
(machine-local, never committed):

- Git author email and name; Spotify client ID (empty skips it).
- Feature units: `work`, `content`, `gaming`.
- Platform (`native` or `wsl`), GPU vendor, chassis (laptop/desktop). Empty
  means autodetect.

Re-running `init` only asks what is new. Then:

```bash
systemctl --user daemon-reload     # graphical-session services
# reboot into Hyprland
```

Apply configs without touching packages: `DOTFILES_SKIP_PACKAGES=1 chezmoi apply`.

## What this repo contains

| Path | Purpose |
|---|---|
| `.chezmoi.toml.tmpl` | Machine manifest (the prompts above) |
| `.chezmoidata/packages.toml` | Package sets per feature unit and GPU vendor |
| `.chezmoidata/omarchy.toml` | Omarchy pin and the override list |
| `.chezmoiscripts/` | Package installer (adds only, never removes) |
| `.chezmoiignore` | Gates files by unit and platform |
| `dot_config/` | Personal configs: fish, kitty, tmux, ghostty, alacritty, bat, btop, yazi, git, lazygit, mise, atuin, spotify-player, systemd user units, uwsm env, and more |
| `dot_config/hypr/` | Personal Hyprland deltas only (monitors, input, bindings, app rules); Omarchy's engine comes from the pin |
| `dot_config/omarchy/` | User theme overlays (`themes/`), templates (`themed/`) and hooks (`hooks/`) read by Omarchy |
| `dot_local/bin/` | My own scripts and the upstream overrides |
| `system/` | Reference files for `/etc` and boot (not applied by chezmoi) |
| `tests/` | bats tests for `upstream-sync` |
| `LICENSE`, `NOTICE`, `LICENSES/` | Licensing, see below |

`~/.config/nvim` is an external repo ([ricardoprato/nvim](https://github.com/ricardoprato/nvim)).

### Feature units

A machine is `base` plus the units its manifest enables.

| Unit | Contents |
|---|---|
| `base` | Hyprland desktop, shell, fonts, theming, audio, networking, CLI |
| `work` | Docker, libvirt/QEMU, language runtimes, VPN clients, editors |
| `content` | Blender, FreeCAD, GIMP, Inkscape, OBS, LV2 plugins, OCR |
| `gaming` | Steam/Proton, gamescope, gamemode, MangoHud, Wine, emulators |

On `wsl` the machine is CLI-only: `base` and `work` headless sets install, all
graphical config is ignored. To change a unit, edit `[data.features]` in
`~/.config/chezmoi/chezmoi.toml` and run `chezmoi apply`. Turning a unit off
removes its configs but leaves its packages installed. Add packages in
`.chezmoidata/packages.toml`; userland only (no kernel, bootloader or drivers).

`game-run -h` documents the gamescope + gamemode + MangoHud wrapper.

### Overrides of Omarchy scripts

Whole-file replacements in `dot_local/bin/executable_omarchy-*`, listed with a
reason and the upstream hash in `.chezmoidata/omarchy.toml`:

- `omarchy-launch-webapp`: chromium fallback when the default browser has no `--app=`.
- `omarchy-theme-set-browser`: writes the managed browser policy directly.
- `omarchy-theme-set-glass`: drops the `gtk.css` import block.
- `omarchy-restart-app`: prefers the systemd user unit.
- `omarchy-system-lock`: `rbw lock` instead of 1Password.
- `omarchy-powerprofiles-list` / `-set`: `powerprofilesctl` pinned to `/usr/bin`.
- `omarchy-sudo-passwordless`, `omarchy-menu-keybindings`, `omarchy-windows-vm`:
  frozen older versions (the upstream tools were rewritten).

Each file starts with a header naming its upstream file and commit.

## Updating Omarchy

```bash
upstream-sync --dry-run            # read-only report against upstream HEAD
upstream-sync                      # bump pin, apply, run checks, commit pin + report
upstream-sync <ref>                # sha, tag or branch instead of HEAD
upstream-sync --accept-override bin/omarchy-system-lock
```

The report covers new/removed scripts, binding changes, themes, templates,
userland migrations and every override whose upstream file changed. Real runs
write it to `odd/upstream-sync/<date>-<sha>.md`. Any failed check restores the
old pin. After porting an upstream change into an override, run
`--accept-override` to record the new upstream hash. Suggested routine: once a
month.

## System scripts (run by hand)

- `network-migrate-networkmanager [--dry-run]`: switch Wi-Fi from iwd to NetworkManager (needs sudo).
- `shell-lock-setup-pam`: install the PAM services the Omarchy shell lock screen needs (needs sudo).

## Post-install notes

- Default browser is Brave: `dot_config/brave-flags.conf` holds its Wayland flags.
  Theme colors need `sudo mkdir -p /etc/brave/policies/managed` and
  `sudo chmod a+rw` on it, then `omarchy-theme-refresh`. Set it as default with
  `env -u BROWSER xdg-settings set default-web-browser brave-browser.desktop`.
- Screen recording needs `gpu-screen-recorder` (AUR); OCR capture needs both
  `tesseract-data-eng` and `tesseract-data-spa`.
- Dictation: `omarchy-install-dictation-voxtype`.
- System files: copy what you need from `system/<dir>/` (grub, limine, pacman,
  snapper, udev, ...) by hand.

## Development

```bash
cd ~/.local/share/chezmoi
chezmoi diff --exclude=scripts     # review before applying
chezmoi apply --force
```

Pre-commit secret scan: `sudo pacman -S gitleaks && git config core.hooksPath .githooks`.
Branch `main-omarchy`; conventional commits.

## License

Original work: MIT, (c) 2026 Ricardo Prato ([`LICENSE`](LICENSE)). Omarchy is MIT,
(c) David Heinemeier Hansson and contributors; it is fetched, not redistributed,
except the overrides above, which keep Omarchy's license
([`LICENSES/omarchy-MIT.txt`](LICENSES/omarchy-MIT.txt)). See [`NOTICE`](NOTICE).
