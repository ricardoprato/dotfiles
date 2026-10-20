# Feature: Converge on upstream omarchy with a vendor + overlay model

## Objective
Make pulling upstream omarchy improvements a routine, low-cost step: vendor
upstream unmodified at a pinned commit, keep every personal change as an
overlay (override, hook, extension, user config or a small patch), and sync
with one command that reports what changed.

## Problem
The fork edits upstream files in place and remapped their paths (flat per-app
`~/.config/<app>/default/`, `$DOTFILES_PATH` theming, everything mixed in
`~/.local/bin`). Every upstream change to a shared file is a manual merge or a
manual path re-adaptation; the omarchy-shell port cost hours for that reason.
Upstream moves ~40 commits/day.

## Target model
- `~/.local/share/omarchy/` = upstream tree subset (`bin/`, `default/`,
  `config/` seeds, `themes/`, `shell/`, `applications/`) vendored verbatim at
  the commit recorded in a pin file. Never hand-edited.
- `~/.local/bin` first on PATH, holding only personal overrides and our own
  scripts; `$OMARCHY_PATH/bin` after it.
- Personal config through upstream extension points: `~/.config/hypr/*`
  (`o.rebind`, `hl.unbind`), `~/.config/omarchy/{hooks,extensions,themes,themed}`,
  `~/.config/omarchy/shell.json`.
- `patches/*.patch` only for changes no extension point covers; applied by the
  sync, failing per patch.
- Paths converge to upstream's (`$OMARCHY_PATH/default/<app>`,
  `~/.local/state/omarchy/current`), dropping the fork's remaps.
- chezmoi keeps its role: manifest, feature units, packages, WSL gating,
  personal configs, externals.

## Constraints
- Desktop never broken between commits (shell live, theme-set working).
- WSL gating preserved; CLI pieces still work on WSL.
- The user's behavior changes survive (inventory: rbw lock, launch-webapp
  chromium fallback, launch-wifi nmtui, restart-app via units, weather location,
  bindings, kitty/tmux/fish setup, starship/spotify-player templates,
  per-theme neovim.lua).
- Naming: our scripts carry no `omarchy-` prefix (the sync tool included).
- Runs after T9 of odd/tasks/omarchy-shell.md (single writer at a time).

## Decisions
- 2026-10-20: per-monitor workspaces follow upstream (always on); drop the fork's
  opt-in toggle `hypr-monitor-workspaces` during T4.
- 2026-10-20: upstream is consumed as a chezmoi external (fetched from
  basecamp/omarchy at the pinned commit), not committed to this repo; the repo
  holds only the overlay. Patches become whole-file overrides (externals are
  re-extracted on apply, so in-place patches would be reverted).
- 2026-10-20: `omarchy-sudo-passwordless` and `omarchy-theme-set-browser` stay as
  frozen whole-file overrides (no packaged helper/sudoers); sync reports when
  upstream changes them (base hash in the pin file).

## Tasks
- [x] T1 Classify every fork `omarchy-*` bin and `default/` file vs pinned upstream: identical / path-remap only / behavior override / fork-only; same for configs. Output the overlay list (route: delegated mapper)
- [x] T2 Upstream as a chezmoi external: `.chezmoiexternal.toml.tmpl` archive of `basecamp/omarchy` at the pinned commit (`.chezmoidata/omarchy.toml`) into a side-by-side dir `~/.local/share/omarchy-upstream` (everything but install/ (except helpers/), migrations, tests, docs, manual, plans, agents, etc/, theme intros); pin file + override base hashes; keep the desktop working on the current fork tree until the cut-over (route: delegated writer). PATH `~/.local/bin` first moves to T3/T4 (it only matters once `$OMARCHY_PATH/bin` is upstream's).
- [x] T3 Cut-over of bins: drop the 169 identical + 94 stale + 20 remap copies from the repo; keep only overrides (launch-webapp, theme-set-browser, sudo-passwordless, and the 5 formerly-patched bins as whole-file overrides) + our own scripts; repoint the 12 callers of names upstream removed (route: delegated writer)
- [x] T4 Converge per-app defaults and hypr: drop `dot_config/<app>/default/*` (external provides `$OMARCHY_PATH/default/<app>`); hypr becomes upstream's `default/hypr` engine + ~250 lines of user files; drop the fork's `hypr-monitor-workspaces` toggle (per-monitor follows upstream) (route: delegated writer)
- [x] T5 Converge theming on upstream's pipeline (`~/.local/state/omarchy/current`, `~/.config/omarchy/{themes,themed,hooks}`: starship/spotify-player user templates, bat hook, per-theme neovim.lua/vscode.json overlays), retire `$DOTFILES_PATH` remaps and the fork's vendored themes; adopt upstream's extra templates + push handlers (claude, neovim, vscode, tmux, fcitx5, pi, hermes, t3code — user approved 2026-10-20; must respect the user's own nvim/tmux/claude config and be reversible); one atomic commit (route: delegated writer)
- [x] T6 Sync tool `upstream-sync <ref>` (ours, no omarchy- prefix): bump the pin, `chezmoi apply`, run checks (all themes render, `hyprctl configerrors`, shell ping, `bash -n` on overrides), report new bins/binds/userland migrations and every override whose upstream base hash changed; dry-run mode; re-sync of the same ref = empty diff (route: delegated writer)
- [x] T7 First real sync to current upstream with the tool; review report; catch up overrides (route: delegated writer + user review)
- [x] T8 Attribution and docs: README ("personal overlay on Omarchy, requires commit X, contains only my changes"), root LICENSE scoped to own work + NOTICE for upstream (MIT (c) DHH), override headers naming their upstream source; local CLAUDE.md; optional monthly sync reminder (route: delegated writer + ask user)

## Acceptance criteria
- `upstream-sync <same pinned ref>` on a clean tree produces no diff.
- `upstream-sync <newer ref>` produces one isolated vendor commit plus a report;
  checks pass or fail per named check/patch.
- Fork overrides are an explicit, short list (files in `~/.local/bin`,
  `patches/`, user config), documented.

## Delivery
exception-ok (direct commits on main-omarchy), one commit per task; vendor
commits isolated.

## TDD
Mode: enabled (global), no runner. Proof per task: render/apply/configerrors/
shell checks; T2 adds an idempotence check (re-sync same ref = empty diff).

## Progress / evidence
- T7 done (route: delegated writer). Commits: 484c339 pre-sync bind (`o.rebind("SUPER + SHIFT + S",
  "Screenshot", ...)` in `hypr/bindings.lua`, user decision 2026-10-20), 93a6bad
  `chore(omarchy): sync upstream to 3ac43659` (pin + report `odd/upstream-sync/2026-10-20-3ac43659.md`).
  Upstream HEAD had moved to 3ac43659 since the T6 dry run (112 commits, bins +1/~10, bindings
  +8/-7, shell plugins 5/28 files, migrations 3, overrides 9 tracked / 0 drifted); the tool ran
  its checks (chezmoi diff empty, bash -n, theme-set, hyprctl reload+configerrors, shell ping),
  removed 2 upstream-deleted files, restarted the shell (tree changed, unlocked) and committed.
  Independent checks: `hyprctl configerrors` empty; `omarchy-shell shell ping` ok;
  `omarchy-theme-set catppuccin` rc 0 (current theme restored: catppuccin); `chezmoi diff
  --exclude=scripts` 0 lines; `hyprctl binds -j` before/after (key+modmask+description+flags):
  only the upstream moves below differ, every user-owned bind unchanged, SUPER+SHIFT+S ->
  Screenshot. Journal since restart: no errors (known warnings: desktop-entry line, unrecognized
  pragma OmarchyLoadPatch, portal app id; all seen on earlier days too).
- T7 binding changes accepted (upstream): SUPER+CTRL+ALT+C Screenshot (duplicate of the kept
  SUPER+SHIFT+S), SUPER+CTRL+N Network panel (replaces nightlight toggle), SUPER+CTRL+W Background
  switcher (was Network), SUPER+CTRL+T Theme menu (was Activity), SUPER+SHIFT+T Activity/btop.
  Calculator SUPER+SHIFT+Q and upstream's Maps on SUPER+SHIFT+S sit in the preinstalled-bindings
  block that the fork switches off, so neither is bound; XF86Calculator stays gnome-calculator.
  No upstream key collides with a user bind. The user's `hl.unbind("SUPER + CTRL + Q")` is now
  a no-op (upstream dropped that bind), harmless.
- T7 migrations (not run, fork never runs omarchy-migrate): 1792343099 (mise `node@latest`
  removal; user's mise pins node = "24", nothing to do), 1792343225 (mise auto_prune=false;
  not set in the user's config, nothing to do), 1792474908 (Brave Origin Copy URL shortcut; no
  Brave Origin profile exists, and the fork uses its own copy-url extension). No actions.

- T5 done (route: delegated writer). Commits: eddc922 inert additions (user templates,
  theme overlays, bat hook), 006211e the atomic pipeline switch, 6b2f4e4 cleanup of the
  dead fork-tree duplicates; plus one uncommitted edit in the user's nvim repo (see notes).
  Evidence: repo tracked files 841 -> 275, working tree (without .git) 114 MB -> 2.7 MB;
  BEFORE snapshot of catppuccin rendered files vs AFTER `current/theme`: kitty, alacritty,
  ghostty, foot, starship, hypr hyprland.lua/gum_env.lua, shell.toml, obsidian, chromium,
  share-picker css byte-identical; btop differs (before: a stale Frappe-flavoured file, now
  the Mocha palette rendered from colors.toml); `omarchy-theme-list` output identical (23
  names). `omarchy-theme-set <t>` for all 23 themes (OMARCHY_THEME_WAIT=1, vscode extension
  installs skipped via the skip toggle): rc 0 each, `current/theme.name` = t, no `{{` in
  any file under `current/theme` (incl. starship.toml and spotify-player.toml), all 23
  neovim.lua overlays and the 5 vscode.json overlays staged over the official theme, the
  shell bar pixel (`grim`) equals the theme background for every theme (live applyTheme
  works; only warning was the shell's one stale-path image load at the cut-over). Modes:
  `omarchy-hyprland-window-transparency glassy` writes `# omarchy-glass` blocks into
  current/theme kitty/alacritty/ghostty/foot/btop (gtk.css untouched), a theme switch under
  glassy re-applies them, `transparent` removes them; `omarchy-hyprland-corners theme`
  then `sharp` toggled the state file and rounding stayed 0. bat hook: gruvbox ->
  `--theme="gruvbox-dark"`, back -> Catppuccin Mocha. nvim headless: colorscheme
  catppuccin-mocha through `current/theme/neovim.lua`; fish `STARSHIP_CONFIG` set and
  starship renders. `hyprctl configerrors` empty, `omarchy-shell shell ping` ok,
  `chezmoi diff --exclude=scripts` 0 lines after every apply (final too). WSL: `chezmoi -c
  <platform=wsl> managed` has the omarchy themed/themes/hooks overlay, restart-bat, btop
  symlink, no spotify template, no kitty/hypr; a no-hyprctl sandbox HOME run of
  `omarchy-theme-set catppuccin` exited 0, fired the theme-set.d hook (bat) and rendered
  starship.toml without placeholders (only `omarchy-restart-hyprctl` reports "Theme retint
  failed", cosmetic). Final state restored: catppuccin, background 1-totoro, transparent,
  corners sharp (toggles/hypr = corners-sharp.lua only).

- T4 done (route: delegated writer; live shell restart and menu checks passed, relogin
  advised). Commits: 4909e70 OMARCHY_PATH, 300f403 per-app defaults, 71f5dcd hypr engine.
  Evidence: repo files 893 -> 836 (tracked dot_config/hypr 2704 lines -> 264 across 16 files);
  `hyprctl configerrors` empty after each reload; `chezmoi diff --exclude=scripts` 0 lines
  after every apply; hypr-spawned process env: PATH starts `~/.local/bin`,
  `omarchy-upstream/bin`, OMARCHY_PATH=omarchy-upstream, QT_STYLE_OVERRIDE=kvantum,
  PLAYWRIGHT_MCP_CONFIG and GDK_SCALE=2 set; `hyprctl getoption` snapshot (30 options:
  gaps, rounding, blur, shadow, kb_layout latam, kb_options, repeat, numlock, layout,
  active_border...) identical except kb_variant/natural_scroll/follow_mouse now
  explicitly `set` (same values); monitor eDP-1 scale 1.6 1920x1200 identical;
  `omarchy-shell shell ping` ok, `omarchy-restart-shell` + ping ok (running shell is
  `quickshell -p omarchy-upstream/shell`, env OMARCHY_PATH=omarchy-upstream),
  `omarchy-menu summon root` opened the menu layer and `omarchy-menu close` closed it,
  `omarchy-theme-set catppuccin` rc 0, 23 themes listed; wsl `managed` (platform=wsl)
  has no hypr/alacritty/ghostty/chromium/systemd/uwsm and keeps the external.
  Binds (`hyprctl binds -j`, key+description+flags): 227 before -> 241 after; none lost
  except description/flag-only changes; the 20 new binds are upstream's (see changed
  behavior). Lua dispatchers are opaque in `binds -j`, so actions of user binds were
  checked statically against the fork file (identical).

### T5 design notes (2026-10-20)
- User theme overlay mechanism: `~/.config/omarchy/themes/<theme>/` holding only
  `neovim.lua` (23) and `vscode.json` (ethereal, miasma, ristretto, vantablack, white).
  Upstream copies the official dir into staging first and then `cp -r`s the user dir on top,
  so a partial dir overlays file by file instead of shadowing the theme (verified by
  staging every theme). Rule to remember: a user dir with `.git` is "installed" and denied
  `*.lua`/terminal configs/vscode.json. `light.mode` markers are not needed (upstream
  colors.toml carries `mode`).
- starship: user template + `STARSHIP_CONFIG` exported by fish (no hook, no patch);
  spotify-player: user template + chezmoi symlink `theme.toml` -> rendered file (path
  symlink, survives upstream's rm+mv swap). bat: hook calls `restart-bat`; `config.tmpl`
  reads `current/theme.name`.
- nvim: the user's repo `lua/plugins/theme.lua` dofile()s `current/theme/neovim.lua`
  (one path edit). The edit is NOT committed: the repo's pre-commit code review (GGA)
  rejects the file for pre-existing style findings; left as a working-tree change for
  the user to commit/bypass. No upstream neovim push handler exists (template only).
- Dropped the fork's `omarchy-system-theme.ts` pi extension (pi not installed; upstream's
  pi handler/template supersede it) and `pi/`, plymouth/sddm/foot/gtk/icon/logo/version
  copies: upstream's plymouth bins use `$OMARCHY_PATH/default/{plymouth,sddm}` and
  `default/gtk/glass.css` is byte-identical to the fork's. Kept in `share/omarchy`:
  applications/ (hidden stubs, 11 deployed; unrelated to theming, revisit in T8),
  omarchy-skill/, LICENSE (T8) and the `bin` symlink (stale session envs: shells and
  terminals started before T4 still hold OMARCHY_PATH/PATH pointing at the old tree;
  relogin, then the symlink can go).
- Overrides now: glass (rebuilt from the pinned upstream minus the gtk.css block, upstream
  base hash unchanged), browser (reads `current/theme/chromium.theme`), tmux (new no-op, hash
  recorded in the pin file). `shell-running` (ours) deleted, nothing called it.

### T5 push handler table (all upstream, run by theme-set; written paths)
| Handler | Enabled? | Writes |
|---|---|---|
| claude | on (`~/.claude` exists) | `~/.claude/themes/omarchy.json` only; NOT activated. `omarchy-theme-set-claude --activate` would set `theme: custom:omarchy` in `~/.claude/settings.json` (undo: `jq 'del(.theme)'`) |
| vscode | on (`code` present) | `Code/User/settings.json` `workbench.colorTheme` (sed in place) and, when the theme's extension is missing, `code --install-extension` (skip toggle `skip-vscode-theme-changes`); themes without a descriptor get a generated local "Omarchy" extension under `~/.vscode/extensions` |
| fcitx5 | inert | nothing until `omarchy-theme-set-fcitx5 --activate`, which would write `~/.local/share/fcitx5/themes/omarchy/` and `Theme=omarchy` in `~/.config/fcitx5/conf/classicui.conf` |
| pi | no-op | `~/.pi/agent/themes/omarchy-system.json` only if `~/.pi/agent` exists (pi not installed) |
| hermes | no-op | `~/.hermes` skin only after Hermes ran once (not installed) |
| t3code | no-op | `~/.t3/userdata/themes/omarchy.json` only if that dir exists (not installed) |
| tmux | disabled (override no-op) | upstream would set global `window-style`, env vars and pane palettes on the running server |
| hunk | on | `SIGWINCH` to running hunk only |
| herdr-machines | on | ssh mirror only if `herdr` lists machines and the toggle is on (herdr absent) |
| neovim | template only | `current/theme/neovim.lua`, read by the nvim repo |
| obsidian, gnome, browser, keyboard, foot | on | as before (vault theme.css, gsettings, `/etc/brave/policies/managed/color.json`, keyboard rgb, foot OSC) |

### T5 changed behavior (accepted upstream behavior)
- Backgrounds are upstream's (webp, plus jpg/png where unchanged); tokyo-night's backgrounds
  differ (upstream moved to `0-liftoff` etc.). Repeating `omarchy-theme-set <same theme>`
  cycles to the next background (upstream), and `current/background` points through
  `current/theme/backgrounds/`.
- btop catppuccin colors now come from the template (Mocha) instead of a stale static file.
- Theme list/switcher/shell picker are upstream's (user dirs only overlay); `omarchy-theme-set`
  now also runs theme-bg-cache, herdr mirror, hunk, hook; gnome mode derives from
  colors.toml. The fork's OWE intros are not installed (excluded from the external).
- Gone: `~/.config/<app>/theme.*` rendered copies, `~/.local/state/dotfiles`,
  `$DOTFILES_PATH`, `~/.config/starship.toml`, `~/.config/hypr/theme*`.
- Known noise: WSL (no hyprctl) prints "Theme retint failed: omarchy-restart-hyprctl".
- Not verified live: a cold login; the visible effect in a freshly opened kitty/ghostty;
  claude/fcitx5 activation (left to the user); vscode extension install path (skipped).

### T4 design notes (2026-10-20)
- OMARCHY_PATH repointed to `~/.local/share/omarchy-upstream` now (uwsm/env; live: systemd
  user manager + `hl.env`). Reasons: upstream's envs.lua re-exports OMARCHY_PATH to every
  Hyprland child anyway, upstream bins read `$OMARCHY_PATH/default/*` that the fork tree
  never had, and the shell tree is byte-identical. The T3 theme worry is handled by
  retargeting the 3 transitional bins that read `$OMARCHY_PATH` (theme-list and
  plymouth-set-by-theme use `$DOTFILES_PATH/themes`, theme-set-glass uses the explicit
  `~/.local/share/omarchy/gtk/glass.css`); every other theme bin already used
  `$DOTFILES_PATH`. Fork leftovers in `~/.local/share/omarchy` and who reads them:
  gtk/glass.css (theme-set-glass, explicit path), plymouth/ + sddm/ (omarchy-plymouth-*,
  explicit path), pi/, omarchy-skill/, nautilus-python/ (no active reader), applications/
  (typora.desktop etc.; upstream's applications/ is what `$OMARCHY_PATH/applications`
  now is), foot/screensaver.ini (replaced by default/foot/screensaver.ini),
  config/omarchy/shell.json (identical in the external), i18n locales trim (dropped, the
  language list is upstream's 50). The fork tree's now-dead duplicates (shell/, default/,
  config/) stay in the repo until a cleanup (T5/T8); deleting them under a running shell
  was avoided.
- hyprland.lua pins the engine by path (`~/.local/share/omarchy-upstream`) and patches
  `package.loaded["default.hypr.paths"].omarchy_path`, so reload works whatever env
  Hyprland started with (live compositor still had the old env). Upstream's
  envs.lua PATH is re-ordered in `hypr/personal.lua`.
- Per-app defaults: all 15 `dot_config/<app>/default/*` files were install-time copies
  nothing read at runtime except 3 transitional bins and chromium-flags; deleted (targets in
  `.chezmoiremove`). The Chromium copy-url extension moved to
  `~/.config/chromium/extensions/copy-url` (upstream's needs a native-messaging host that is
  not installed here); chromium/brave flags point to it. The 6 transitional hypr/default
  bins were dropped; upstream's versions resolve and pass `bash -n`.
- State marker `first-run-user` (chezmoi run_once_after script + touched live) keeps
  upstream's first-run flow out of the login autostart.
- User binds are a delta in `hypr/bindings.lua`: app/web app binds (preinstalled set off),
  SUPER+CTRL+X and SUPER+H voxtype (F9 stays unbound; upstream binds it only when its
  dictation backend is installed), code:49/code:61 (upstream grave/SLASH unbound so each key
  has one bind), SUPER+XF86AudioMute, SUPER+PERIOD emojis, XF86Calculator gnome-calculator,
  SUPER+CTRL+Q (omacalc, not installed) unbound. SUPER+SHIFT+/ is unbound (preinstalled
  set off).

### T4 changed behavior (accepted upstream behavior)
- Per-monitor workspaces always on: SUPER+TAB, SHIFT+TAB, CTRL+TAB, mouse wheel and
  SUPER+SHIFT+ALT+arrows are per-monitor; the active workspace moved to 1 on first reload.
- New upstream binds: SHIFT+XF86AudioMute, SHIFT+XF86AudioPause/Play (media source),
  XF86Eject, CTRL+SPACE terminal prefix passthrough, SUPER+CTRL+SHIFT+arrows (move window
  to monitor), SUPER+CTRL+K Herdr keybindings, webcam overlay resize (SUPER+ALT), Apple SMC lid switches;
  lid switch now `omarchy-system-lid-close`/`monitor-clamshell`; SUPER+CTRL+F is the
  tiled-fullscreen toggle; SUPER+K/SUPER+BACKSPACE descriptions renamed.
- Dropped upstream-preinstalled binds (ChatGPT, Grok, X, HEY, Herdr, Signal, Omawrite,
  1Password) and the fork's default-opacity scheme: only terminals (0.985/0.96) and the
  opted-in apps are transparent, other windows are opaque; browser/telegram opacity rules
  gone, Telegram still floats.
- Scratchpad (SUPER+S/code:49) now launches `omarchy-agent` when empty (upstream workspace
  rule); special workspace animation changed; fadeSwitch off; QT_QPA_PLATFORMTHEME=gtk3
  exported (QT_STYLE_OVERRIDE=kvantum kept); XF86AudioMicMute no longer repeats.
- Dropped rules: bitwarden webapp rule was commented out in the fork but upstream floats
  the extension window; qemu opacity, hyprshot layer rule (upstream has its own).
- Language list shows upstream's 50 locales (es-MX/en unchanged); xdph.conf, hyprsunset.conf
  untouched.
- Not verified live: a fresh login (startup path through `OMARCHY_PATH` env), push-to-talk
  voxtype, Telegram/WhatsApp/Calendar window rules (only the capacities float tag was
  observed on a live client).
- T3 implemented (route: delegated writer), left unticked until the live checks
  blocked by an accidental screen lock are confirmed after relogin (see Next step).
  Commits: b531b17 PATH, 165e4ce drop 251 bins, 2388d01 gone-upstream, 49903eb
  override headers, 6d83cab WSL ignore prune. Evidence: repo `dot_local/bin`
  333 -> 54 files (12 own + 8 overrides + 34 transitional); `chezmoi diff
  --exclude=scripts` 0 lines after every apply; `command -v` under the new
  uwsm-env PATH resolves 19 dropped bins to ~/.local/share/omarchy-upstream/bin and
  the 8 overrides to ~/.local/bin; fish PATH starts `~/.local/bin`,
  `omarchy-upstream/bin`; wsl `managed` lists the upstream bin/ (535 files) and
  no shell/applications; `hyprctl configerrors` empty; `omarchy-shell shell ping`
  ok; `omarchy-theme-set catppuccin` rc 0; omarchy-version (prints `dev`, upstream
  dev-link semantics), battery-status --shell, hw-laptop, network-wifi-connected,
  powerprofiles-list --active-state, cmd-present, default-editor (nvim),
  update-available, system, i18n run fine. Live session was patched without
  relogin: `hyprctl eval hl.env("PATH", ...)` (new Hyprland-spawned processes get
  the new order, verified with a spawned `echo $PATH`) and `systemctl --user
  set-environment PATH`. NOT done: shell restart + menu open (the session got
  locked by a stray `omarchy-system-lock --help` call during the run; the lock
  refuses restarts).
- T2 done (route: delegated writer). Evidence: `chezmoi apply ~/.local/share/omarchy-upstream`
  fetched and extracted 1571 files (83 MB); `diff -r` plus mode/symlink listing
  vs `git archive up/main` filtered with the same excludes: identical; re-apply
  no-op; `chezmoi diff` 0 lines; shell ping ok, `hyprctl configerrors` empty,
  `omarchy-theme-set catppuccin` rc 0; wsl `managed` drops shell/applications/
  icon/logo; repo unchanged in size (archive not committed).
- T1 done (route: delegated mapper, read-only). Outputs in scratchpad/overlay/
  (bins.tsv, defaults.tsv, hypr.md, configs.md, theming.md,
  extension-points.md, overlay-list.md). Bins: 169 identical, 94 stale,
  20 remap, 11 override (~6 real), 28 gone upstream (12 still referenced),
  11 fork-only. Defaults: 308 identical, 46 gone, 8 stale, 1 fork-only,
  1 override. Overlay: whole-file overrides (launch-webapp,
  theme-set-browser, sudo-passwordless) + own scripts; 5 small patches
  (restart-app, system-lock rbw, powerprofiles-{list,set}, theme-set-glass);
  hook theme-set.d bat; user templates starship/spotify-player; per-theme
  neovim.lua/vscode.json overlays; hypr user files ~250 lines (from ~2400).
  Risks: T5 theme flip must be atomic; upstream envs.lua prepends
  $OMARCHY_PATH/bin to PATH; pin file must record override base hashes;
  exclude themes/*/intros (92 MB).

### T2 design notes (2026-10-20)
- Landing dir: `~/.local/share/omarchy-upstream` (var `omarchy.landing` in the pin
  file). Nothing in it collides with the fork tree in `~/.local/share/omarchy`
  (fork copies there stay chezmoi-managed until T3-T5 drop them). Cut-over =
  repoint `OMARCHY_PATH` (uwsm/env, fish, systemd env, hypr `envs`) to the new dir;
  no file moves, no `.chezmoiremove` of anything inside it, no external path change.
  The fork's non-upstream leftovers (omarchy-skill, pi, nautilus-python, foot,
  gtk, plymouth, sddm) stay in the old dir or move to `~/.config/omarchy`/ours.
  Recommended: keep the permanent separate dir; do not rename back to `omarchy`.
- Pin file `.chezmoidata/omarchy.toml`: `commit`, `landing`, and
  `[omarchy.overrides."<upstream path>"] sha256 + why` for the 8 overrides
  (launch-webapp, theme-set-browser, sudo-passwordless, restart-app,
  system-lock, powerprofiles-list/-set, theme-set-glass), hashes of the upstream
  file at 81fd2d23. Bump `commit` = new URL = new fetch. No archive checksum
  (commit sha is content-addressed; GitHub tarballs are not byte-stable).
- chezmoi 2.73 external behavior (verified in a throwaway source):
  * `include`/`exclude` match archive member paths BEFORE `stripComponents`
    (patterns need a leading `*/`); when both are set non-matching members are
    still extracted, so the entry is exclude-only. Excluded dirs are not created.
    New upstream top-level entries are therefore fetched by default.
  * Real intro videos live at `themes/*/backgrounds/intros` (not `themes/*/intros`).
  * `refreshPeriod = "0"`: downloaded once per URL (cache `~/.cache/chezmoi/external`,
    ~175 MB tarball), re-fetched only with `--refresh-externals=always` or on URL
    change. Any chezmoi command re-extracts the cached tarball (~2 s).
  * `exact` false (default): extra files in the dir survive; fork files can share
    the dir. Local edits to extracted files and deleted files are reverted on
    apply (so every personal change must be an override/hook, as planned).
  * A `.chezmoiremove` entry inside the external dir is a hard error
    ("inconsistent state"): never list such paths.
  * Exec bits and the 4 symlinks of the archive come through unchanged.
  * `.chezmoiignore` applies to external members (used for WSL).
- WSL: the same archive is fetched; `.chezmoiignore` drops `shell/`,
  `applications/`, `icon.*`, `logo.*`. bin/, default/, config/, themes/ stay
  (theming pipeline and CLI helpers need them). Checked with
  `chezmoi -c <wsl copy> managed`.
- Gotcha for every task: a full `chezmoi apply` runs the `.config/nvim` git-repo
  external, whose `git pull --rebase` fails because ~/.config/nvim has local
  changes (lazy-lock.json, lua/utils/kitty-nav.lua) and last ran 2026-05-25;
  `--refresh-externals=never` does not skip it. T2 applied with the target path
  `chezmoi apply ~/.local/share/omarchy-upstream`. Resolve nvim before relying on
  a plain `chezmoi apply` in T3-T5.
- Installed set: 1571 files (~83 MB), identical to `git archive up/main` minus the excludes.
### T3 design notes (2026-10-20)
- OMARCHY_PATH stays on the fork tree. Repointing it to the external now would
  change what the transitional theme bins see (`$OMARCHY_PATH/themes` is the fork's
  symlink to the 23 dotfiles themes; the external ships a different set, so
  omarchy-theme-list/switcher would offer themes the fork pipeline cannot
  render), drop the fork's trimmed `default/i18n/locales.json` override and the
  fork-owned files in the tree (applications/, gtk/glass.css, foot/screensaver.ini,
  config/omarchy/shell.json, pi/, omarchy-skill/, plymouth/, sddm/, themes ->
  dotfiles). Repoint in T4/T5 once defaults and themes converge.
- `~/.local/share/omarchy/bin` (chezmoi `symlink_bin`) now points at
  `../omarchy-upstream/bin` (relative to the link dir). Absolute
  `$OMARCHY_PATH/bin/<x>` calls (agent-usage-update, language, plymouth refresh,
  ...) therefore hit upstream and bypass ~/.local/bin overrides, as upstream
  intends; none of the overrides is called that way.
- PATH: `~/.local/bin` then `~/.local/share/omarchy-upstream/bin` in uwsm env
  (reaches Hyprland, which sets no PATH in the fork's envs.lua, and the systemd
  user manager, which imports uwsm exports; verified by show-environment) and in
  fish (path.fish.tmpl, added last so they sit in front; this is also the WSL
  path). No environment.d PATH: it would duplicate the uwsm one. WSL has no
  other login shell config in the repo.
- Selection rule for dropping a bin: IDENTICAL = byte-equal raw (169, safe). STALE
  and REMAP only when the upstream version's path/env references resolve in the
  current environment (compared fork copy vs upstream refs); kept otherwise.
  Semantic changes accepted ("take upstream"): omarchy-version prints `dev`,
  default-editor/launch-editor read `~/.local/state/omarchy/defaults/editor`
  (falls back to nvim = the fork's EDITOR), launch-about is the fitted/animated
  upstream one, menu-tmux-keybindings looks for `config/tmux` (missing before too).
- Overrides rebuilt on the pinned upstream where the fork copy was stale:
  system-lock (keeps upstream ttfx handling, rbw lock block). restart-app and
  powerprofiles-{list,set} already equal upstream plus the user hunk; launch-webapp,
  theme-set-browser, sudo-passwordless stay frozen copies; theme-set-glass stays
  pipeline-bound (T5). All carry `# Override of upstream bin/<name> at 81fd2d23;
  see .chezmoidata/omarchy.toml`; base hashes unchanged.
- Gone upstream (28): repointed omarchy-capture-text-extraction ->
  omarchy-capture-text (binding, OCR note), omarchy-system-reboot ->
  `omarchy-system reboot` (two kept bins), voxtype README -> omarchy-install-
  dictation-voxtype, omarchy-launch-wifi -> ours `launch-wifi`. Retired: battery
  group (shell battery service calls omarchy-battery-low; timer units + wants link
  removed), ac-present, branch/update git-channel flow, and 14 unreferenced bins.
  Targets are in `.chezmoiremove` (precise paths; none inside the external dir).
- Stray unmanaged files left in ~/.local/bin: omarchy-kitty-tab-picker,
  omarchy-style-corners-hyprland, omarchy-toggle-idle.bak.
- Live-session caveat: processes started before the change (quickshell, Hyprland
  spawn env) hold `$OMARCHY_PATH/bin` first in PATH, which now resolves to upstream
  and shadows the overrides/transitional copies. Hyprland spawn env and the systemd
  manager were patched live; quickshell keeps the old PATH until it restarts.

### Transitional bins (resolved)
- The 26 theme/plymouth fork copies went in T5; the 6 hypr/default ones in T4. Left in
  `~/.local/bin`, package-bound on purpose: omarchy-menu-keybindings, omarchy-windows-vm.

### T6 evidence (2026-10-20)
- `dot_local/bin/executable_upstream-sync` (ours, deployed to `~/.local/bin/upstream-sync`):
  `upstream-sync [--dry-run] [<ref>]` and `upstream-sync --accept-override <path>`. Ref = sha,
  tag or branch (default: `git ls-remote` HEAD); the full sha is what gets pinned.
- History comes from a blobless bare cache clone in `${XDG_CACHE_HOME:-~/.cache}/upstream-sync/omarchy`.
  Vendored scope = the external template's `exclude` array parsed at run time (leading `*/`
  dropped, turned into git pathspecs), so the report cannot drift from what chezmoi extracts.
- Report (stdout, and `odd/upstream-sync/<date>-<short>.md` on a real run): summary counts,
  new/removed bins with their summary, changed bins count, `o.bind`/`o.rebind` diff lines,
  themes, themed templates, shell plugin file counts, migrations added (migrations are not
  vendored, read from git) flagged when they mention hypr / omarchy config / local-bin / theme,
  and override drift: recorded sha256 vs the file at the new sha, with `git diff --stat` + diff
  (80 lines max) or REMOVED upstream.
- Real run: preconditions (network, clean source tree except `.atl/`, empty `chezmoi diff
  --exclude=scripts`) abort; in `--dry-run` they only warn. Then rewrite the pin, `chezmoi apply`
  of the landing dir, delete files upstream removed (the external is not exact, so they would
  linger on PATH), and checks: empty full `chezmoi diff`, `bash -n` on bash scripts of
  `dot_local/bin` (templates via their deployed copy), `omarchy-theme-set <current>` + no `{{`
  under `current/theme`, `hyprctl reload` + `configerrors`, `omarchy-shell shell ping`, shell
  restart only if `shell/` changed and `lock status` says unlocked. No Hyprland session: those
  are SKIP (WSL works the same). Any failure restores the old pin, re-applies it and exits 1.
  Success commits only the pin file + report as `chore(omarchy): sync upstream to <short>`.
- Override hashes are never auto-updated: after porting, `--accept-override <path|bare name>`
  records the hash of the applied landing file (leaves the pin edit uncommitted).
- Tests: `tests/upstream-sync.bats` (23, bats, throwaway upstream + source repos, stubbed
  chezmoi; `tests` added to `.chezmoiignore`): pin parse/rewrite, include/exclude extraction,
  drift detection with two fake shas, accept-override validation, dry-run changes nothing,
  dirty-tree abort, rollback on a failing check. All pass; shellcheck clean.
- Verified: `upstream-sync --dry-run 81fd2d23...` prints "already at pin", rc 0. Dry run against
  upstream HEAD (5264cbbd): 111 commits 2026-08-21..2026-10-20, bins +1/-0/~7, bindings +8/-7
  lines, themes 0, templates 0, shell plugins 5 (28 files), migrations 3 (0 flagged), overrides
  9 tracked / 0 drifted; git status and chezmoi diff unchanged.

### T8 evidence (2026-10-20)
- Commits: cc326ac (licensing, NOTICE, headers, leftovers), 5cc29fe (README). Route: delegated writer.
- README rewritten (112 lines): overlay statement + credit, requirements and pin location, new-machine
  install and prompts, repo contents table, feature units (incl. WSL), override list, `upstream-sync`
  routine, hand-run system scripts, post-install notes, license. Paths/commands verified with ls/command -v.
- LICENSE: MIT (c) 2026 Ricardo Prato, scoped to original work. NOTICE added: Omarchy fetched not
  redistributed; the 10 overrides are Omarchy-derived and stay MIT (c) DHH; notice kept at
  `LICENSES/omarchy-MIT.txt` (moved from `dot_local/share/omarchy/LICENSE`; `LICENSE`, `NOTICE`,
  `LICENSES` added to `.chezmoiignore`).
- Headers: all 10 overrides now carry 3 lines after the shebang (upstream file + `basecamp/omarchy @ 3ac43659`,
  MIT notice -> NOTICE, `# Why:` + pin entry). `omarchy-menu-keybindings` and `omarchy-windows-vm`
  (older upstream copies, 770 / 1524 diff lines vs pin) were added to `.chezmoidata/omarchy.toml` as frozen
  overrides with the current upstream sha256. `bash -n` OK on all `omarchy-*` bins.
- Leftovers: `dot_local/share/omarchy/applications/` (stale upstream copies + orphaned hidden stubs, nothing
  referenced them) and `omarchy-skill/` (upstream ships `default/agents/skills/omarchy`) removed; targets
  in `.chezmoiremove`. Kept: `bin` symlink (stale session envs), only non-upstream item left in that dir.
- Local CLAUDE.md updated to the overlay model (new "Upstream overlay and sync" section: override rule,
  extension points, monthly routine; stale tmux no-op and fork-leftover text fixed).
- Checks: `chezmoi diff --exclude=scripts` showed only the expected changes, empty after apply;
  `upstream-sync --dry-run` rc 0 ("already at pin 3ac43659"). No scheduled reminder created (parent asks the user).

## Summary
- Before: frozen fork, upstream edited in place and path-remapped; every upstream change was a manual merge.
- Now: upstream fetched at a pinned commit (`.chezmoidata/omarchy.toml`) into `~/.local/share/omarchy-upstream`;
  the repo holds personal config, 10 whole-file overrides (pin entry + sha256 + header), user theme/hook overlays
  under `~/.config/omarchy`, personal hypr deltas, and `upstream-sync`.
- Maintain: monthly `upstream-sync --dry-run`, then `upstream-sync`; port any drifted override and run
  `upstream-sync --accept-override <name>`. Never edit the external; add overrides only when no extension point fits.

## Next step
Done; routine: monthly `upstream-sync`.

Open user checks (from T7): SUPER+CTRL+N (Network), SUPER+CTRL+W (Background switcher), SUPER+CTRL+T (Theme menu), SUPER+SHIFT+T (btop), SUPER+SHIFT+S (Screenshot), notifications panel.
- T3 confirmed by the user 2026-10-20: shell restarted with the new PATH (~/.local/bin, then omarchy-upstream/bin), SUPER+SPACE menu / SUPER+ALT+SPACE apps work.
