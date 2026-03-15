#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${GREEN}[*]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
hint()  { echo -e "${CYAN}[~]${NC} $1"; }

# Detect profile
PROFILE="desktop"
if command -v chezmoi &>/dev/null; then
    PROFILE="$(chezmoi execute-template '{{ .profile }}' 2>/dev/null || echo "desktop")"
fi
info "Profile: $PROFILE"

# Helper: extract package names from a list file (skip comments/blanks)
read_list() {
    [[ -f "$1" ]] && grep -v '^#' "$1" | grep -v '^$' | sort || true
}

# Get currently installed packages
native_installed="$(pacman -Qe --quiet | grep -v "$(pacman -Qm --quiet)" | sort)"
aur_installed="$(pacman -Qm --quiet | sort)"

# Read existing shared lists
shared_pacman="$(read_list "$DOTFILES_DIR/pkgs-pacman.txt")"
shared_aur="$(read_list "$DOTFILES_DIR/pkgs-aur.txt")"

# Read existing profile-specific list
case "$PROFILE" in
    desktop)
        profile_pacman="$(read_list "$DOTFILES_DIR/pkgs-pacman-desktop.txt")"
        profile_aur="$(read_list "$DOTFILES_DIR/pkgs-aur-desktop.txt")"
        ;;
    wsl)
        profile_pacman="$(read_list "$DOTFILES_DIR/pkgs-pacman-wsl.txt")"
        profile_aur="$(read_list "$DOTFILES_DIR/pkgs-aur-wsl.txt")"
        ;;
    blackarch)
        profile_pacman="$(read_list "$DOTFILES_DIR/pkgs-blackarch.txt")"
        profile_aur=""
        ;;
esac

# All known packages for this profile = shared + profile-specific
all_known_pacman="$(echo -e "$shared_pacman\n$profile_pacman" | sort -u)"
all_known_aur="$(echo -e "$shared_aur\n$profile_aur" | sort -u)"

# Find new packages (installed but not in any list)
new_pacman="$(comm -23 <(echo "$native_installed") <(echo "$all_known_pacman"))"
new_aur="$(comm -23 <(echo "$aur_installed") <(echo "$all_known_aur"))"

# Find removed packages (in lists but no longer installed)
removed_pacman="$(comm -23 <(echo "$all_known_pacman") <(echo "$native_installed"))"
removed_aur="$(comm -23 <(echo "$all_known_aur") <(echo "$aur_installed"))"

# --- Report ---
echo ""
if [[ -n "$new_pacman" ]]; then
    warn "New native packages (not in any list):"
    echo "$new_pacman" | sed 's/^/  + /'
fi
if [[ -n "$new_aur" ]]; then
    warn "New AUR packages (not in any list):"
    echo "$new_aur" | sed 's/^/  + /'
fi
if [[ -n "$removed_pacman" ]]; then
    warn "Removed native packages (in list but not installed):"
    echo "$removed_pacman" | sed 's/^/  - /'
fi
if [[ -n "$removed_aur" ]]; then
    warn "Removed AUR packages (in list but not installed):"
    echo "$removed_aur" | sed 's/^/  - /'
fi

pacman_changed=false
if [[ -n "$new_pacman" || -n "$new_aur" || -n "$removed_pacman" || -n "$removed_aur" ]]; then
    pacman_changed=true
fi

if $pacman_changed; then
    echo ""
    hint "Where should NEW packages go?"
    hint "  1) shared   — all profiles"
    hint "  2) profile  — only $PROFILE"
    hint "  3) skip     — don't add new packages"
    read -rp "Choice [1/2/3]: " choice

    # --- Update shared lists: remove uninstalled packages ---
    # Only remove from shared if not installed AND not in the other profile's list
    updated_shared_pacman="$(comm -12 <(echo "$shared_pacman") <(echo "$native_installed"))"
    updated_shared_aur="$(comm -12 <(echo "$shared_aur") <(echo "$aur_installed"))"

    # --- Update profile-specific list: remove uninstalled packages ---
    updated_profile_pacman="$(comm -12 <(echo "$profile_pacman") <(echo "$native_installed"))"
    updated_profile_aur="$(comm -12 <(echo "$profile_aur") <(echo "$aur_installed"))"

    case "$choice" in
        1)
            # Add new packages to shared
            updated_shared_pacman="$(echo -e "$updated_shared_pacman\n$new_pacman" | grep -v '^$' | sort -u)"
            updated_shared_aur="$(echo -e "$updated_shared_aur\n$new_aur" | grep -v '^$' | sort -u)"
            ;;
        2)
            # Add new packages to profile-specific
            updated_profile_pacman="$(echo -e "$updated_profile_pacman\n$new_pacman" | grep -v '^$' | sort -u)"
            updated_profile_aur="$(echo -e "$updated_profile_aur\n$new_aur" | grep -v '^$' | sort -u)"
            ;;
        3)
            info "Skipping new packages."
            ;;
        *)
            warn "Invalid choice. Skipping new packages."
            ;;
    esac

    # --- Write files ---
    echo "$updated_shared_pacman" > "$DOTFILES_DIR/pkgs-pacman.txt"
    echo "$updated_shared_aur" > "$DOTFILES_DIR/pkgs-aur.txt"

    case "$PROFILE" in
        desktop)
            echo "$updated_profile_pacman" > "$DOTFILES_DIR/pkgs-pacman-desktop.txt"
            echo "$updated_profile_aur" > "$DOTFILES_DIR/pkgs-aur-desktop.txt"
            ;;
        wsl)
            echo "$updated_profile_pacman" > "$DOTFILES_DIR/pkgs-pacman-wsl.txt"
            echo "$updated_profile_aur" > "$DOTFILES_DIR/pkgs-aur-wsl.txt"
            ;;
        blackarch)
            echo "$updated_profile_pacman" > "$DOTFILES_DIR/pkgs-blackarch.txt"
            ;;
    esac
fi

# --- Extra package managers ---

get_flatpak_installed() {
    flatpak list --app --columns=application | sort
}

get_cargo_installed() {
    cargo install --list | grep -E '^\S' | cut -d' ' -f1 | sort
}

get_pnpm_installed() {
    pnpm list -g --depth=0 --json | jq -r '.[].dependencies // {} | keys[]' | sort
}

sync_extra_list() {
    local name="$1"       # "flatpak", "cargo", "pnpm"
    local cmd="$2"        # comando para verificar existencia
    local get_fn="$3"     # función para obtener instalados
    local list_file="$DOTFILES_DIR/pkgs-${name}.txt"

    # Guard: skip si el comando no existe
    command -v "$cmd" &>/dev/null || return 0

    # Guard: skip flatpak en WSL
    if [[ "$name" == "flatpak" && "$PROFILE" == "wsl" ]]; then
        return 0
    fi

    local installed
    installed="$($get_fn)"
    local listed
    listed="$(read_list "$list_file")"

    local new removed
    new="$(comm -23 <(echo "$installed") <(echo "$listed"))"
    removed="$(comm -23 <(echo "$listed") <(echo "$installed"))"

    if [[ -z "$new" && -z "$removed" ]]; then
        return 0
    fi

    # Reportar cambios
    if [[ -n "$new" ]]; then
        warn "New $name packages:"
        echo "$new" | sed 's/^/  + /'
    fi
    if [[ -n "$removed" ]]; then
        warn "Removed $name packages:"
        echo "$removed" | sed 's/^/  - /'
    fi

    # Auto-actualizar lista
    local updated
    updated="$(comm -12 <(echo "$listed") <(echo "$installed"))"
    updated="$(echo -e "$updated\n$new" | grep -v '^$' | sort -u)"
    echo "$updated" > "$list_file"
    info "Updated pkgs-${name}.txt ($(echo "$updated" | wc -l) packages)"
}

echo ""
info "--- Extra package managers ---"
sync_extra_list "flatpak" "flatpak" "get_flatpak_installed"
sync_extra_list "cargo" "cargo" "get_cargo_installed"
sync_extra_list "pnpm" "pnpm" "get_pnpm_installed"

# --- Summary ---
echo ""
info "Updated package lists:"
if $pacman_changed; then
    echo "  pkgs-pacman.txt          $(wc -l < "$DOTFILES_DIR/pkgs-pacman.txt") packages"
    echo "  pkgs-aur.txt             $(wc -l < "$DOTFILES_DIR/pkgs-aur.txt") packages"
    case "$PROFILE" in
        desktop)
            echo "  pkgs-pacman-desktop.txt  $(wc -l < "$DOTFILES_DIR/pkgs-pacman-desktop.txt") packages"
            echo "  pkgs-aur-desktop.txt     $(wc -l < "$DOTFILES_DIR/pkgs-aur-desktop.txt") packages"
            ;;
        wsl)
            echo "  pkgs-pacman-wsl.txt      $(wc -l < "$DOTFILES_DIR/pkgs-pacman-wsl.txt") packages"
            echo "  pkgs-aur-wsl.txt         $(wc -l < "$DOTFILES_DIR/pkgs-aur-wsl.txt") packages"
            ;;
        blackarch)
            echo "  pkgs-blackarch.txt       $(wc -l < "$DOTFILES_DIR/pkgs-blackarch.txt") packages"
            ;;
    esac
fi
for mgr in flatpak cargo pnpm; do
    local_f="$DOTFILES_DIR/pkgs-${mgr}.txt"
    if [[ -f "$local_f" ]] && command -v "$mgr" &>/dev/null; then
        echo "  pkgs-${mgr}.txt          $(wc -l < "$local_f") packages"
    fi
done
