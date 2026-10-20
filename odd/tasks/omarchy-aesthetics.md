# Feature: Port upstream omarchy aesthetics (palette, glass, corners, new themes)

## Objective
Bring the visual layer of upstream omarchy (branch `quattro`) into this fork
without adopting omarchy-shell: semantic palette schema, glass/transparency
modes, window corner styles, and the new themes.

## Problem
Upstream moved `colors.toml` from `color0..15`/`cursor` to a semantic schema
(`mode`, `selection`, `muted`, `dark_background`, `red`, `bright_*`, ...) and
rewrote every theme and template. Any new upstream theme or template is
unusable until the fork's renderer, themes and templates speak that schema.

## Scope
- Renderer (`omarchy-theme-set-templates`): support every token/filter upstream
  templates use, keeping the fork's render-destination convention.
- Palette: 21 themes take upstream's `colors.toml` (themes were otherwise
  untouched, fork-only `neovim.lua` stays). Templates: take upstream's where
  they exist; port fork-only ones (waybar, walker, mako, swayosd, hyprlock,
  quickshell, starship, spotify-player) to the new keys.
- New themes `lupine` and `starship` (~6.5 MB of backgrounds).
- Corners: upstream corner styles (theme/sharp/rounded) replacing
  `omarchy-style-corners-hyprland`.
- Glass: opaque/transparent/glassy modes for windows plus matching terminal,
  btop and GTK translucency. Bar-glassy is out (needs omarchy-shell).

## Out of scope
omarchy-shell, new push handlers/templates for other apps (claude, tmux,
vscode, fcitx5, ...), wallpapers of existing themes, bug-fix drift.

## Constraints
- Upstream reference: `/tmp/claude-1000/-home-redfoxd--local-share-chezmoi/7aa1b2e6-290f-4825-b899-5b2a5156f546/scratchpad/up/omarchy`, ref `up/main`.
- Desktop must keep working after every commit (current theme re-applies cleanly).
- Fork conventions: `$DOTFILES_PATH`/`$DOTFILES_STATE_PATH`, render to
  `~/.config/<app>/theme.<ext>`, flat `dot_config/hypr/`, new desktop files
  gated for `platform=wsl` in `.chezmoiignore`.
- Keep user-modified `~/.config/dotfiles/themes` (if any) working or flag it.

## Acceptance criteria
- `omarchy-theme-set <name>` succeeds for all 23 themes; no rendered file
  contains `{{`; kitty, waybar, walker, mako, hyprland, btop pick up colors.
- `hyprctl configerrors` empty after reload in every corner/glass mode.
- `chezmoi ignored` with `platform=wsl` still excludes all desktop paths.

## TDD
Mode: enabled (global config), no test runner in repo. Proof: render checks
(grep for unreplaced tokens, diff rendered output for the current theme before
and after), `hyprctl configerrors`, `chezmoi apply --dry-run`.

## Delivery
Strategy: exception-ok — repo policy is direct commits on `main-omarchy`, no
PRs. Forecast ~900 authored lines plus vendored theme files. One work-unit
commit per task.

## Tasks
- [x] T1 Renderer + palette schema migration + template port (route: delegated writer — many files)
- [x] T2 New themes lupine, starship (route: delegated writer)
- [x] T3 Corner styles (route: delegated writer)
- [x] T4 Glass/transparency modes (route: delegated writer)
- [x] T5 Fix leftovers: theme corner mode, GTK translucency, CLAUDE.md hypr path (route: delegated writer)

## Progress / evidence
- T1 done (route: delegated writer). Renderer rewritten on upstream's awk engine
  (mix/mix_strip/mix_rgb, hypr_gradient, _strip/_rgb) with the fork's
  destination map; palette parsing/aliases/derived shades come from the new
  `omarchy-theme-color` (fork copy of upstream, default colors file under
  `$DOTFILES_STATE_PATH/current-theme-dir`). Legacy keys still resolve.
- 21 `colors.toml` replaced by upstream's; 12 templates taken from upstream
  (fork had no deltas vs base); starship/spotify-player ported colorN -> semantic
  names; waybar/walker/mako/swayosd/hyprlock/quickshell only use
  accent/foreground/background (unchanged). `omarchy-theme-colors-from-alacritty`
  now emits `selection` and drops `cursor`/`selection_*`.
- Static per-theme extras (btop.theme, light.mode, waybar.css, ...) left alone:
  the fork renders templates, not those files. CLAUDE.md is gitignored; its
  schema section was updated locally.
- Checks: all 21 themes render with no `{{` left and rc=0; `omarchy-theme-set
  catppuccin` ok; `hyprctl configerrors` empty; `bash -n` ok. Catppuccin diff vs
  before: only upstream palette changes (cursor/selection, ANSI 0/7/15, btop
  selected_bg/gradient) plus hyprland inactive border and kitty
  dynamic_background_opacity from upstream templates.
- Commit: see `git log` ("migrate palette to upstream semantic color schema").

- T2 done (route: delegated writer). lupine + starship vendored from up/main
  (colors.toml, backgrounds, previews, unlock images, icons.theme); added
  fork-only `neovim.lua` (lupine -> catppuccin-latte, starship -> gruvbox: no
  dedicated colorschemes) and `light.mode` for lupine (fork's gnome handler
  reads the marker). Checks: `omarchy-theme-set lupine|starship` rc=0, no `{{`
  in rendered files, `hyprctl configerrors` empty, both listed in themes dir.
- T3 done (route: delegated writer). Added `omarchy-hyprland-corners`
  (theme|sharp|rounded, upstream script minus i18n) + `toggles/corners-{sharp,
  rounded}.lua`; `omarchy-style-corners` now accepts theme|sharp|round and calls
  it (still sets hyprlock/mako/walker); menu got a Theme entry; removed
  `omarchy-style-corners-hyprland` and dead `rounded-corners.conf`. Fixed
  `omarchy-hyprland-toggle` FLAG_SOURCE (pointed at non-existent
  `~/.config/hypr/default/toggles`) and moved `require("hypr.toggles")` after the
  theme in `hyprland.lua` so toggles override theme. Fork theme template has no
  rounding, so "theme" == base looknfeel (0). Checks: rounded/sharp/theme ->
  `hyprctl getoption decoration:rounding` 6/0/0; persists after `hyprctl
  reload`; `hyprctl configerrors` empty; `bash -n` ok; wsl globs
  (`omarchy-hyprland-*`, `omarchy-style-*`, `.config/hypr`) cover new files.
  Left at sharp (pre-change look).
- T4 done (route: delegated writer). Ported `omarchy-hyprland-window-transparency`
  (opaque|transparent|glassy), `omarchy-theme-set-glass` (adapted to render
  `~/.config/<app>/theme.*` in place, no staging/flock, no user gtk.css import
  because `~/.config/gtk-4.0` is a GTK theme symlink), `hypr/glass.lua`,
  `toggles/window-{glassy,opaque}.lua` (fork tags: default-opacity, terminal,
  chromium-based-browser), `gtk/glass.css`. theme-set-templates calls
  theme-set-glass after rendering. Style menu got an Opacity entry. Existing
  per-window `omarchy-hyprland-window-transparency-toggle` kept (upstream's relies
  on a `transparent` tag rule the fork lacks). Checks: all modes rc=0,
  `hyprctl configerrors` empty, kitty window opacity 1/1/0.97 for
  opaque/glassy/transparent, kitty `background_opacity 0.65` block present in
  glassy and gone after leaving it, `omarchy-theme-set catppuccin` rc=0 with no
  `{{`, `bash -n` ok, wsl: new bins match `omarchy-hyprland-*`, `.config/hypr` already ignored,
  `.local/share/omarchy/gtk` added; `omarchy-theme-set-glass` stays installed on
  wsl on purpose (theme-set-templates calls it; it no-ops without the files).
- T5 done (route: delegated writer). Corner "theme" mode was sharp because theme
  static files were never read. Upstream rule (`render_templates`): a file the
  theme ships under the template's name wins over the template. Fork renderer now
  copies `current-theme-dir/<name>` to the template destination instead of
  rendering it. Synced hyprland.lua (solitude gains rounding 6, kanagawa, lumon)
  and solitude btop.theme from up/main; removed 28 stale static files that
  upstream no longer ships and would now shadow templates (17 btop.theme,
  5 waybar.css, 4 swayosd.css, 2 hyprlock.conf). Checks: solitude + corners theme
  -> rounding 6; catppuccin + theme -> 0; `hyprctl configerrors` empty; no `{{`
  in rendered files; `bash -n` ok; wsl ignore still covers hypr/glass paths.
  GTK glass NOT done: `~/.config/gtk-4.0` is a dangling symlink to
  `~/.themes/catppuccin-mocha-mauve-standard+default/gtk-4.0` (target missing,
  not chezmoi-managed, no package owns it); `~/.config/gtk-3.0` is an empty
  unmanaged dir and `backdrop-filter` is GTK4-only. Writing a gtk.css means
  replacing the user's symlink, so left alone; glass reaches GTK only via
  Ghostty's custom CSS. CLAUDE.md (local) layout corrected.

## Notes
- `chezmoi apply` needs `--exclude=scripts,externals` here (installer needs
  sudo; nvim external has unstaged changes).

## Next step
omarchy-shell phase (out of scope here); user to review T5 and decide on the dangling gtk-4.0 symlink.
