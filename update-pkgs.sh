#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

pacman -Qe --quiet | grep -v "$(pacman -Qm --quiet)" | sort > "$DOTFILES_DIR/pkgs-pacman.txt"
pacman -Qm --quiet | sort > "$DOTFILES_DIR/pkgs-aur.txt"

echo "Updated: $(wc -l < "$DOTFILES_DIR/pkgs-pacman.txt") native, $(wc -l < "$DOTFILES_DIR/pkgs-aur.txt") AUR"
