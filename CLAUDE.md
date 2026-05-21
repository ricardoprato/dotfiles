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
- `dot_local/bin/executable_<name>` (no `omarchy-` prefix) — our own scripts, written for this fork. Examples: `kitty-tab-picker` (Alt+D fuzzy folder picker, bound in `dot_config/kitty/kitty.conf`), `restart-bat` (bat cache refresh helper)
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
- `.chezmoiexternal.toml` declares git repos chezmoi clones+pulls into target paths (e.g., `~/.config/nvim` from `github.com/ricardoprato/nvim`). Externals keep their own `.git` dir and standalone push/pull workflow; chezmoi pulls them every `refreshPeriod` (default in this repo: 168h). Dirty working tree blocks the pull — commit or stash before `chezmoi apply`.

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

**Push (6 handlers)** — apps that can't include external files; theme-set runs a script that pushes colors into the app:
- `omarchy-theme-set-gnome` — `gsettings set`
- `omarchy-theme-set-browser` — writes `/etc/<browser>/policies/managed/color.json`
- `omarchy-theme-set-vscode` — patches VS Code `settings.json`
- `omarchy-theme-set-obsidian` — copies CSS into Obsidian vault theme dir
- `omarchy-theme-set-keyboard-{asus-rog,f16}` — sends RGB to hardware-specific tools
- `omarchy-theme-set-foot` — sends OSC escapes to running foot windows (live update — pull-pattern fallback for fresh windows still works)

Zen/Firefox are intentionally NOT themed: their only customization hook is `userChrome.css` (legacy/deprecated by Mozilla, requires `toolkit.legacyUserProfileCustomizations.stylesheets`). Keeping with upstream omarchy's philosophy — themea solo lo officially-customizable — Zen uses its built-in theme system (`about:preferences` → Themes) or AMO themes.

### Adding a new theme

```bash
cd ~/.local/share/chezmoi
mkdir -p dot_local/share/dotfiles/themes/<name>/backgrounds
```

Minimum required inside the theme dir:

```
themes/<name>/
  colors.toml             REQUIRED — palette source of truth
  backgrounds/*.{png,jpg} REQUIRED — at least one wallpaper image
  preview.png             optional — for the theme switcher card
  light.mode              optional — empty file marker for light themes
  neovim.lua              optional — colorscheme spec table for nvim integration
  vscode.json             optional — { name, extension } for VS Code handler
  btop.theme              optional — copy from another theme and adapt
  icons.theme             optional — GNOME icon theme name string
```

`colors.toml` must define at minimum:

```toml
accent = "#7aa2f7"
cursor = "#c0caf5"
foreground = "#a9b1d6"
background = "#1a1b26"
selection_foreground = "#c0caf5"
selection_background = "#3d4a8a"

# ANSI palette (used by terminals)
color0  = "#15161e"
color1  = "#f7768e"
# ... color2..color15
```

Each key is available in templates in 3 forms: `{{ accent }}` → `#7aa2f7`, `{{ accent_strip }}` → `7aa2f7` (no `#`), `{{ accent_rgb }}` → `122,162,247` (decimal).

Apply and switch:

```bash
chezmoi apply --force
omarchy-theme-set <name>
```

The theme appears automatically in `omarchy-theme-switcher` (it reads from `$DOTFILES_PATH/themes/`).

### Adding a template for a new app

**Case 1 — app supports `include`/`@import`/`source` (pull pattern):**

1. Create template:
   ```bash
   chezmoi edit ~/.local/share/dotfiles/themed/<app>.<ext>.tpl
   # body uses {{ accent }}, {{ background }}, etc.
   ```
2. Make the app's entry config import the rendered file:
   ```bash
   chezmoi edit ~/.config/<app>/<entry-config>
   # add: include theme.<ext>  /  @import "theme.<ext>";  /  source = ~/.config/<app>/theme.<ext>
   ```
3. If reload-on-change is needed, add a call in `omarchy-theme-set` near the other `omarchy-restart-*` lines.
4. `chezmoi apply --force && omarchy-theme-refresh`

The renderer automatically discovers `<app>.<ext>.tpl` and writes to `~/.config/<app>/theme.<ext>` by convention. No edit to `omarchy-theme-set-templates` needed.

**Case 2 — app has no include mechanism (full-config theming, like starship):**

1. Create template containing the entire app config, with placeholders for colors.
2. Add a destination exception in `omarchy-theme-set-templates`:
   ```bash
   <app>.<ext>)  echo "$HOME/.config/<app>/<real-config-name>" ;;
   ```
3. If a chezmoi-tracked version of that config existed, remove it: `git -C $(chezmoi source-path) rm dot_config/<app>/<real-config-name>` (template now owns the file).
4. `chezmoi apply --force && omarchy-theme-refresh`

**Case 3 — app needs imperative push (gsettings, settings.json patch, hardware CLI):**

1. (Optional) Create template if the handler needs a rendered file as input (Case 1).
2. Write `~/.local/bin/executable_omarchy-theme-set-<app>` that reads the rendered file and applies it via the app's API.
3. Add call in `omarchy-theme-set` under the "Push-pattern handlers" block.
4. `chezmoi apply --force && omarchy-theme-refresh`

### Verification

```bash
# Sweep for dead refs after any path-related change
grep -rn "share/omarchy/default/\|omarchy/current/" $(chezmoi source-path) \
  | grep -v "CLAUDE\|SKILL\|.planning"
# Expect: empty
```

## Workflow

Single branch `main-omarchy`. Edit in source, `chezmoi apply --force`, commit.

When omarchy bins reference paths, they use:
- `$DOTFILES_PATH` / `$DOTFILES_STATE_PATH` for the theming pipeline
- `$OMARCHY_PATH` (= `~/.local/share/omarchy/`) for non-theming resources (applications, pi/, foot/screensaver.ini, omarchy-skill/)
- `$HOME/.config/<app>/default/` for per-app moved engine defaults
- `$HOME/.config/<app>/theme.<ext>` for rendered theme output

When you need to adapt an omarchy script or default, edit it in place. Reference the pre-fork upstream state via `~/dotfiles-backup-2026-05-17/omarchy-upstream.tar.zst`.

## Naming convention: ours vs omarchy

Clear separation between forked-from-omarchy and our own additions:

- **`omarchy-<name>`** — came from upstream omarchy. May be modified in place for this fork, but provenance is upstream. Carries the `# omarchy:summary=...` header used by omarchy's script catalog.
- **`<name>`** (no prefix) — written by us for this fork. Plain shebang + plain comment header. Do NOT add `# omarchy:summary=` — that header is reserved for upstream scripts.

When creating a new helper script:

1. Drop it in `dot_local/bin/executable_<descriptive-name>` — no `omarchy-` prefix.
2. Use a plain header comment describing purpose; skip the `omarchy:summary=` line.
3. If a kitty/hypr/waybar binding invokes it, reference the bare name (the script lands in `~/.local/bin/` which is on `$PATH`).

Current personal scripts: `kitty-tab-picker`, `restart-bat`. Pattern is by negative space — omarchy prefix is the marker; absence of it means ours.

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
- Pending manual install: alacritty, imv, opencode (configs present, binaries not)
- kanata: install steps documented in README ("Keyboard remapping (kanata)"). Binary `kanata-bin` from AUR; udev rule at `system/udev/50-kanata.rules` (reference-only, copy to `/etc/udev/rules.d/`); service auto-enabled via `dot_config/systemd/user/default.target.wants/kanata.service` symlink.
