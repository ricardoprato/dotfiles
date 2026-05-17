# CLAUDE.md

Project guidance for Claude / Claude Code working in this repository.

## Project

**Personal dotfiles, frozen fork of omarchy.** chezmoi manages everything. No install scripts, no profile templating, no GSD workflow. Repository fully self-contained — upstream omarchy is not a runtime dependency.

## Layout (per-app flat)

Each app's configuration lives entirely under its `dot_config/<app>/` dir. omarchy's "engine internals" (formerly in `~/.local/share/omarchy/default/<app>/`) are colocated as `dot_config/<app>/default/`. Editing happens in one place per app.

- `dot_config/hypr/` — Hyprland user files + `default/` (engine: apps/, bindings/, toggles/, omarchy.lua, helpers.lua, paths.lua, plain-bindings.lua, require_all.lua, windows.lua, envs.lua)
- `dot_config/waybar/` — waybar config + `default/` (indicators, weather.sh)
- `dot_config/walker/` — walker config + `default/` (themes, restart.conf)
- `dot_config/alacritty/`, `dot_config/chromium/`, `dot_config/elephant/`, `dot_config/ghostty/`, `dot_config/systemd/`, `dot_config/mako/`, `dot_config/wireplumber/`, `dot_config/voxtype/`, `dot_config/quickshell/` — same pattern
- `dot_local/share/omarchy/` — only what's NOT per-app: `themes/` (22 themes), `applications/` (.desktop launchers), `LICENSE`, `version`, `icon.*`, `logo.*`, plus omarchy-internal `default/` for system-level reference (bash, limine, pacman, plymouth, sddm, snapper, udev, wayland-sessions, firefox/policies.json) and runtime resources (themed/, foot/screensaver.ini, pi/, omarchy-skill/, nautilus-python/)
- `dot_local/share/fonts/omarchy.ttf` — UI icon font (fontconfig discovers it)
- `dot_local/bin/executable_omarchy-*` — 227 omarchy CLI scripts (pruned: dev, install, refresh, remove, reinstall, hw-specific)
- `dot_tmux.conf` → `~/.tmux.conf`
- `dot_XCompose` → `~/.XCompose`
- `private_dot_ssh/` → `~/.ssh/` (mode 0700)
- `private_dot_gnupg/` → `~/.gnupg/` (mode 0700)

## chezmoi conventions

- `dot_<name>` → `.<name>` (hidden)
- `private_<name>` → 0700
- `executable_<name>` → +x
- `.tmpl` suffix → Go templating (only `dot_config/fish/*.tmpl` uses `.chezmoi.homeDir`)
- `.chezmoiignore` excludes CLAUDE.md, README.md, .planning, .worktrees

## Workflow

Single branch `main-omarchy`. Edit in source, `chezmoi apply --force`, commit.

When omarchy bins reference paths, they use:
- `$OMARCHY_PATH` (set to `~/.local/share/omarchy/` by `dot_config/uwsm/env`) for omarchy-internal resources (themes, applications, themed templates)
- `$HOME/.config/<app>/default/` for per-app moved defaults (hypr, waybar, walker, alacritty, chromium, elephant, ghostty, systemd, mako, wireplumber, voxtype, quickshell)

When you need to adapt an omarchy script or default, edit it in place. Reference the pre-fork upstream state via `~/dotfiles-backup-2026-05-17/omarchy-upstream.tar.zst`.

## Per-app flat migration: silent-include trap

The migration from upstream omarchy's `~/.local/share/omarchy/default/<app>/` to per-app flat `~/.config/<app>/default/` is shape-incomplete — scripts, templates, and configs may still reference the old path. These **fail silently**: every consumer tolerates a missing include/config and falls back to built-in defaults. Observed symptoms in this fork:

- mako include missing → `default-timeout=0` built-in → notifications never expire
- walker `additional_theme_location` missing → only bundled themes load
- alacritty/ghostty screensaver `--config-file` missing → terminal's internal defaults silently win

Before editing any path reference, sweep for residual refs across the chezmoi source:

```bash
grep -rn "share/omarchy/default/" $(chezmoi source-path) \
  | grep -v "CLAUDE\|SKILL\|.planning"
```

Already migrated (do not re-introduce old path):

- `dot_local/share/omarchy/themed/mako.ini.tpl` → `~/.config/mako/default/core.ini`
- `dot_config/walker/config.toml` → `~/.config/walker/default/themes/`
- `dot_local/bin/executable_omarchy-launch-screensaver` (alacritty + ghostty cases) → `~/.config/<app>/default/screensaver*`

`dot_local/share/omarchy/omarchy-skill/SKILL.md` still references the upstream layout. It is documentation for an external Claude skill, **intentionally not updated** — do not touch.

## Service quirks

- **Walker has no systemd unit in this fork.** `omarchy-restart-walker` will print `Unable to restart Walker -- RESTART MANUALLY` because it expects `app-walker@autostart.service`. Walker actually runs via D-Bus activation from `dot_config/walker/default/walker.desktop`. To restart after config changes:
  ```bash
  pkill -x walker && setsid -f walker --gapplication-service
  ```

## Constraints

- Arch / Hyprland / Wayland
- Keyboard layout: latam (`dot_config/hypr/input.lua`)
- Default terminal: kitty (`dot_config/xdg-terminals.list`)
- Shell: fish
- Pending manual install: alacritty, imv, kanata, opencode (configs present, binaries not)
