#!/usr/bin/env bash
# One-shot state markers for the vendored upstream omarchy.
#
# first-run-user: upstream's Hyprland autostart runs omarchy-provision-first-run
# on every login until this marker exists. That flow (enable user units, GNOME
# theme, speaker tuning, setup hooks) targets a fresh package install; this
# machine is provisioned by chezmoi, so mark it done.
set -euo pipefail
mkdir -p "$HOME/.local/state/omarchy/done"
touch "$HOME/.local/state/omarchy/done/first-run-user"
