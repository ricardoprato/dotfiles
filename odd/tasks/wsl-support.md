# Feature: WSL2 support

## Objective
Let the same chezmoi source provision an Arch Linux install running under WSL2
as a CLI-only machine, without touching how native (Hyprland) machines render.

## Problem
`packages.base` mixes CLI tooling with the full Hyprland desktop, GPU drivers are
always installed, and every desktop config/script lands in `$HOME`. On WSL2 that
installs hundreds of useless packages, risks breaking the WSLg GPU path, and
leaves dead desktop files.

## Scope
- Manifest: detect WSL, store `platform = "wsl" | "native"` (explicit answer wins).
- Packages: split `base` into `base` (CLI) + `desktop`; split `work` into CLI and
  desktop/VM halves (`work` + `workDesktop`).
- Installer: on `wsl` skip `desktop`, `workDesktop`, `content`, `gaming`, GPU set.
- `.chezmoiignore`: on `wsl` ignore graphical configs, graphical systemd units,
  omarchy desktop scripts/resources.
- Docs: CLAUDE.md feature-unit section.

## Constraints
- Read manifest keys with `dig` (default `native`), so existing machines are unchanged.
- Installer render must stay deterministic (`uniq | sortAlpha`).
- Userland only; installer only adds.
- On WSL, docker engine is not installed (Docker Desktop provides it).

## Acceptance criteria
- Native render of the installer produces the same package set as before.
- WSL render excludes desktop, VM, GUI apps, GPU drivers, docker engine.
- `chezmoi ignored` with `platform=wsl` lists the desktop paths; native list unchanged.

## TDD
Mode: enabled (global config). No test runner exists in this repo; proof is
template rendering via `chezmoi execute-template` / `chezmoi ignored` with
overridden data, compared native-before vs native-after vs wsl.

## Delivery
Strategy: ask-on-risk. Forecast ~250 authored lines (mostly package list moves).
Branch: `main-omarchy` (repo's single working branch per CLAUDE.md).

## Tasks
- [x] T1 Manifest `platform` detection + split package sets + installer gating (route: delegated writer — 3 non-trivial files)
- [x] T2 `.chezmoiignore` WSL gating + ignore `odd/` (route: same writer)
- [x] T3 CLAUDE.md docs (route: same writer)
- [x] T4 Verify native unchanged / wsl reduced (route: parent spot check)

## Progress / evidence
- Native PACMAN_PKGS/AUR_PKGS render byte-identical to baseline (parent spot check re-run).
- Native `chezmoi ignored` = baseline + `odd`.
- WSL render: units base+work, 69 pacman / 3 AUR; no hyprland/mesa/docker/qemu/steam. `bash -n` OK.
- WSL ignored: 190 entries (desktop configs, systemd units, fonts, desktop omarchy-*).
- Known leftovers: omarchy-theme-set prints "command not found" for GUI push handlers on WSL and renders theme files into ~/.config/{hypr,waybar,...}; yazi keymap references ignored yazi-kdeconnect-share.

## Next step
Test on the WSL2 machine: `chezmoi init` then `chezmoi apply`.
