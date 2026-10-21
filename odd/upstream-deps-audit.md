# Upstream external-command audit

Pin: `3ac43659` (basecamp/omarchy). Scope: every executable in `bin/` plus the
shell scripts and QML under `shell/` of the applied external. Regenerate the
command list with `upstream-sync --audit-deps` (offline, whole-tree, same
extractor `upstream-sync` runs on new/changed bins at every sync). Packages
come from upstream's `install/omarchy-{base,other}.packages` and `pacman -Si`,
`yay -Si` and the AUR RPC on this machine.

Why this exists: upstream installs some tools from its own package repo, which
this CachyOS fork never uses; a script that starts depending on one fails
silently here (seen with `ttfx` and `omasnap`).

Extractor limits: it reads the first word of each command position, wrappers
(`exec`, `sudo`, `systemd-run`, `uwsm-app --`, `timeout`, ...) and
`command -v` / `omarchy-cmd-present|missing` / `which` probes. It does not look
inside `bash -c '...'` strings or multi-line `xargs` arguments, and the word
list below includes a few false positives (last table).

## Added to packages.toml

| command | package | source | used by | guarded? | action |
|---|---|---|---|---|---|
| `localsend` | `localsend` | repo (CachyOS `cachyos` 1.17.0-4; not in Arch extra, AUR `localsend-bin` on plain Arch) | `omarchy-menu-share` (SUPER+CTRL+S Share menu: `systemd-run ... localsend --headless send`, Receive via `uwsm-app -- localsend`) | no | added to `[packages.desktop].pacman` |
| `omasnap` | `omasnap-bin` | AUR (Omarchy-only upstream, `omasnap` in omarchy repo) | `omarchy-capture-screenshot`, `omarchy-clipboard-open` | no | added earlier (`[packages.desktop].aur`, commit 29afc14) |

`ttfx` (screensaver) was handled before this audit; it is installed and builds
with `--nocheck` in the installer. Nothing else needs special build flags.

## Opt-in (optional features, not installed)

| command | package | source | used by | guarded? | action |
|---|---|---|---|---|---|
| `alacritty` | `alacritty` | repo | `omarchy-refresh-applications` | yes | opt-in; config is present, binary is a documented manual install |
| `chromium` | `ungoogled-chromium-bin` (upstream wants `chromium`) | repo/AUR | `omarchy-install-service-1password`, `omarchy-remove-browser` | yes | opt-in; Zen/Chrome are the browsers here |
| `brave-origin` | `brave-origin-bin` | AUR | `omarchy-theme-set-browser` (our override) | yes | opt-in |
| `lutris` | `lutris` | repo | `omarchy-install-gaming-lutris` | install helper | opt-in (gaming unit candidate) |
| `opam` | `opam` | repo | `omarchy-install-dev-env`, `omarchy-remove-dev-env` | install helper | opt-in |
| `dropbox-cli` | `dropbox` (AUR) | AUR | dropbox service helpers, `shell/plugins/panels/dropbox` | service helper | opt-in |
| `hermes` | `hermes-agent` | repo (cachyos)/AUR | `omarchy-install-hermes-cli` | yes | opt-in |
| `openclaw` | `openclaw` | AUR | openclaw install/launch/onboard bins | install helper | opt-in |
| `voxtype` | `voxtype-bin` / `voxtype` | AUR | `omarchy-dictation-voxtype` + install/remove | yes | opt-in (dictation) |
| `superwhisper` | `superwhisper-bin` | Omarchy-only | `omarchy-dictation-superwhisper` + install | install helper | opt-in; not on Arch/AUR |
| `omazed` | `omazed` | AUR | `omarchy-install-editor-zed` | install helper | opt-in (with `zed`) |
| `once` | n/a | Omarchy-only | `omarchy-install-service-once` | install helper | opt-in; no Arch package |
| `snapper` | `snapper` | repo | `omarchy-snapshot` | yes | opt-in; this machine does not use snapper snapshots |
| `ufw` | `ufw` | repo | sunshine/sshd setup helpers | yes | opt-in (firewall) |
| `pamu2fcfg` | `pam-u2f` | repo | `omarchy-setup-security-fido2` | setup helper | opt-in (FIDO2 login) |
| `xfreerdp3` | `freerdp` | repo | `omarchy-windows-vm` (we keep the frozen older one) | no | opt-in with the Windows VM feature |
| `hostname` | `inetutils` | repo (core) | `omarchy-setup-security-sshd`, herdr machine theme | no | opt-in; only a setup helper and a dropped feature use it |
| `ydotool` | `ydotool` | repo | `omarchy-dev-install-ydoo` | yes | skip: Omarchy developer tooling |

## Skipped

| command | package | source | used by | guarded? | action |
|---|---|---|---|---|---|
| `tailscale` | `tailscale` | repo | tailscale send/receive/service bins, shell panel | no | skip: dropped deliberately (CLAUDE.md) |
| `herdr` | `herdr` | Omarchy-only | herdr keybindings/restart/theme bins | no | skip: dropped deliberately |
| `owe` | `owe` | AUR | `omarchy-theme-bg-boot-intro`, `omarchy-theme-set`, `shell/services/BackgroundIntro.qml` | no | skip: dropped deliberately (OWE) |
| `btrfs` | `btrfs-progs` | repo (core) | hibernation setup/remove, factory reset | no | skip: system plumbing; filesystem tooling belongs to the installer |
| `limine-update`, `limine-mkinitcpio`, `limine-snapper-sync`, `limine-snapper-restore` | `limine-*-hook`, `limine-snapper-sync` | repo (cachyos) | hibernation, plymouth, provision, snapshot, refresh-limine | no | skip: bootloader (CLAUDE.md scope rule) |
| `plymouth-set-default-theme` | `plymouth` | repo | `omarchy-plymouth-set` | no | skip: boot splash is installer territory |
| `updatedb` | `plocate` | repo | `omarchy-pkg-aur-install` | no | skip: Omarchy package-install plumbing |
| `asdcontrol` | none found | Omarchy-only | `omarchy-brightness-display-apple` | no | skip: Apple display hardware |
| `asusctl`, `supergfxctl` | `asusctl`, `supergfxctl` | repo / AUR | ASUS ROG keyboard theme, hybrid GPU | yes | skip: other hardware |

## Extractor noise (not commands)

`commit`, `fail` (functions from a sourced file, `omarchy-bar`, `omarchy-dock`),
`eDP`, `FIGFont`, `Font` (case labels / figlet args), `height`, `width`
(`omarchy-launch-about`), `owner` (`omarchy-hw-platform`), `sub`
(awk body in `omarchy-audio-output-sink`).

## Result

`upstream-sync --audit-deps` lists 42 names at this pin: 2 real unguarded
desktop dependencies (`localsend`, `omasnap`), both now in `packages.toml`; 16
opt-in features; the rest are skipped for the reasons above, plus the noise
rows. The extractor reports on every sync from now on (section "New external
commands missing on this machine" at the top of the report).
