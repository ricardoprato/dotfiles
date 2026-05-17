# CLAUDE.md

Project guidance for Claude / Claude Code working in this repository.

## Project

**Personal dotfiles, frozen fork of omarchy.** chezmoi manages everything. No install scripts, no profile templating, no GSD workflow. Repository fully self-contained — upstream omarchy is not a runtime dependency.

## Layout (per-app flat)

Each app's configuration lives entirely under its `dot_config/<app>/` dir. omarchy's "engine internals" (formerly in `~/.local/share/omarchy/default/<app>/`) are colocated as `dot_config/<app>/default/`. Editing happens in one place per app.

- `dot_config/hypr/` — Hyprland user files + `default/` (engine: apps/, bindings/, toggles/, omarchy.lua, helpers.lua, paths.lua, plain-bindings.lua, require_all.lua, windows.lua, envs.lua) + `theme/` (rendered by theme pipeline: hyprland.lua, hyprlock.conf, gum_env.lua — not chezmoi-tracked)
- `dot_config/waybar/` — waybar config + `default/` (indicators, weather.sh) + `theme.css` (rendered, not chezmoi)
- `dot_config/walker/` — walker config + `default/` (themes, restart.conf) + `theme.css` (rendered, not chezmoi)
- `dot_config/alacritty/`, `dot_config/chromium/`, `dot_config/elephant/`, `dot_config/ghostty/`, `dot_config/systemd/`, `dot_config/mako/`, `dot_config/wireplumber/`, `dot_config/voxtype/`, `dot_config/quickshell/`, `dot_config/btop/`, `dot_config/kitty/`, `dot_config/helix/`, `dot_config/swayosd/`, `dot_config/hyprland-preview-share-picker/` — same per-app pattern (`<entry>`, `default/` if applicable, `theme.<ext>` rendered)
- `dot_local/share/dotfiles/` — **theming pipeline source** (decoupled from omarchy namespace):
  - `themes/<name>/` — 21 source themes (colors.toml, backgrounds/, preview*, static per-app files like btop.theme, vscode.json)
  - `themed/<app>.<ext>.tpl` — 19 templates with `{{ key }}` placeholders rendered per theme set
- `dot_local/share/omarchy/` — non-theming resources only: `applications/` (.desktop launchers), `omarchy-skill/`, `pi/`, `nautilus-python/`, `foot/screensaver.ini`, `LICENSE`, `version`, `icon.*`, `logo.*`
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
- `symlink_<name>` → symlink whose target = file contents (e.g., `dot_config/btop/themes/symlink_current.theme`)
- `empty_<name>` → allow tracking empty files (chezmoi skips empty otherwise)
- `.tmpl` suffix → Go templating (`dot_config/fish/*.tmpl`, `dot_config/bat/config.tmpl`)
- `.chezmoiignore` excludes CLAUDE.md, README.md, .planning, .worktrees

## Theming pipeline

The theming pipeline is **fully decoupled from the omarchy namespace**. Themes and templates live under `~/.local/share/dotfiles/`; runtime state under `~/.local/state/dotfiles/`; rendered output lands inside each app's own `~/.config/<app>/` dir.

```
~/.local/share/dotfiles/
  themes/<name>/            source themes (colors.toml, backgrounds/, static per-app files)
  themed/<app>.<ext>.tpl    templates with {{ key }} placeholders

~/.local/state/dotfiles/
  current-theme             text: active theme name (e.g., "tokyo-night")
  current-theme-dir         symlink → themes/<name>/  (for scripts to read backgrounds, colors.toml, vscode.json, light.mode, etc.)
  current-background        symlink → backgrounds/<picked>.png
  theme-keyboard.rgb        rendered hardware-specific keyboard color

~/.config/<app>/theme.<ext> rendered output (not chezmoi-tracked)
```

Env vars (set in `dot_config/uwsm/env`): `DOTFILES_PATH=~/.local/share/dotfiles`, `DOTFILES_STATE_PATH=~/.local/state/dotfiles`.

### Render destination convention

`omarchy-theme-set-templates` maps each `<app>.<ext>.tpl` → `~/.config/<app>/theme.<ext>` by convention. Inline exceptions for files whose app dir or destination differs:

| Template | Destination |
|---|---|
| `hyprland.lua.tpl` | `~/.config/hypr/theme/hyprland.lua` |
| `hyprlock.conf.tpl` | `~/.config/hypr/theme/hyprlock.conf` |
| `gum_env.lua.tpl` | `~/.config/hypr/theme/gum_env.lua` |
| `hyprland-preview-share-picker.css.tpl` | `~/.config/hyprland-preview-share-picker/theme.css` |
| `keyboard.rgb.tpl` | `~/.local/state/dotfiles/theme-keyboard.rgb` |
| `starship.toml.tpl` | `~/.config/starship.toml` (starship has no include mechanism; template owns the full config) |

### Pull vs push consumers

**Pull (most apps)** — entry config in `dot_config/<app>/` includes/imports/sources the rendered `theme.<ext>` file. Examples: kitty `include theme.conf`, mako `include=~/.config/mako/theme.ini`, waybar `@import "theme.css"`, hyprlock `source = ~/.config/hypr/theme/hyprlock.conf`. New windows/restart picks up new theme automatically.

**Push (5 handlers)** — apps that can't include external files; theme-set runs a script that pushes colors into the app:
- `omarchy-theme-set-gnome` — `gsettings set`
- `omarchy-theme-set-browser` — writes `/etc/<browser>/policies/managed/color.json`
- `omarchy-theme-set-vscode` — patches VS Code `settings.json`
- `omarchy-theme-set-obsidian` — copies CSS into Obsidian vault theme dir
- `omarchy-theme-set-keyboard-{asus-rog,f16}` — sends RGB to hardware-specific tools
- `omarchy-theme-set-foot` — sends OSC escapes to running foot windows (live update — pull-pattern fallback for fresh windows still works)

### Adding a new app to the theme pipeline

3 steps:
1. Drop `<app>.<ext>.tpl` in `dot_local/share/dotfiles/themed/` with `{{ foreground }}` / `{{ accent }}` / `{{ background }}` etc. placeholders (see `colors.toml` for available keys, with `_strip` and `_rgb` variants).
2. Ensure `~/.config/<app>/<entry>` includes/imports `theme.<ext>` (creating the entry file in chezmoi if needed).
3. If the app needs reload-on-theme-change, add a call in `omarchy-theme-set` to its restart helper.

No edits to `omarchy-theme-set-templates` needed unless the destination doesn't match the convention.

## Workflow

Single branch `main-omarchy`. Edit in source, `chezmoi apply --force`, commit.

When omarchy bins reference paths, they use:
- `$DOTFILES_PATH` / `$DOTFILES_STATE_PATH` for the theming pipeline
- `$OMARCHY_PATH` (= `~/.local/share/omarchy/`) for non-theming resources (applications, pi/, foot/screensaver.ini, omarchy-skill/)
- `$HOME/.config/<app>/default/` for per-app moved engine defaults
- `$HOME/.config/<app>/theme.<ext>` for rendered theme output

When you need to adapt an omarchy script or default, edit it in place. Reference the pre-fork upstream state via `~/dotfiles-backup-2026-05-17/omarchy-upstream.tar.zst`.

## Per-app flat migration: silent-include trap

The migration from upstream omarchy's `~/.local/share/omarchy/default/<app>/` to per-app flat `~/.config/<app>/default/` is shape-incomplete — scripts, templates, and configs may still reference the old path. These **mostly fail silently**: every consumer tolerates a missing include/config and falls back to built-in defaults. Observed symptoms in this fork:

- mako include missing → `default-timeout=0` built-in → notifications never expire
- walker `additional_theme_location` missing → only bundled themes load
- alacritty/ghostty screensaver `--config-file` missing → terminal's internal defaults silently win
- **Exception**: mako fails LOUDLY (`Failed to parse config`) when an `include=` points at a missing file. The themed `mako.ini` previously included `~/.local/state/omarchy/toggles/mako.ini` (missing). Stub now tracked at `dot_local/state/omarchy/toggles/empty_mako.ini`.

Before editing any path reference, sweep for residual refs across the chezmoi source:

```bash
grep -rn "share/omarchy/default/\|omarchy/current/\|share/omarchy/themes\|share/omarchy/themed" $(chezmoi source-path) \
  | grep -v "CLAUDE\|SKILL\|.planning"
```

`dot_local/share/omarchy/omarchy-skill/SKILL.md` still references the upstream layout. It is documentation for an external Claude skill, **intentionally not updated** — do not touch.

## Service quirks

- **Walker has no systemd unit in this fork.** Walker runs via D-Bus activation from `dot_config/walker/default/walker.desktop`. `omarchy-restart-walker` has been rewritten to `pkill -x walker && setsid -f walker --gapplication-service` for this fork.
- **Walker caches CSS theme tokens in the running daemon** — kill+relaunch is required after theme changes; a `makoctl reload` style soft reload does not exist. `omarchy-theme-set` calls `omarchy-restart-walker` after each theme switch.
- **omarchy-toggle state** lives at `~/.local/state/omarchy/toggles/` (NOT under `dotfiles/`). It's omarchy-feature state, not theming state, so it stays in the omarchy namespace. Empty stubs (`empty_mako.ini`, `empty_walker.css`) tracked in chezmoi prevent silent-include failures.

## Constraints

- Arch / Hyprland / Wayland
- Keyboard layout: latam (`dot_config/hypr/input.lua`)
- Default terminal: kitty (`dot_config/xdg-terminals.list`)
- Shell: fish
- Pending manual install: alacritty, imv, kanata, opencode (configs present, binaries not)
