#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[*]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[x]${NC} $1"; }

ask() {
    read -rp "$1 [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

# Detect profile from chezmoi data
PROFILE="desktop"
if command -v chezmoi &>/dev/null; then
    PROFILE="$(chezmoi execute-template '{{ .profile }}' 2>/dev/null || echo "desktop")"
fi
info "Profile: $PROFILE"

# Helper: install from package list, skipping comments and blank lines
install_from_list() {
    local list="$1"
    if [[ -f "$list" ]]; then
        grep -v '^#' "$list" | grep -v '^$'
    fi
}

# -----------------------------------------------------------
# 1. Install packages
# -----------------------------------------------------------
install_packages() {
    info "Installing base pacman packages..."
    install_from_list "$DOTFILES_DIR/pkgs-pacman.txt" | \
        sudo pacman -S --needed --noconfirm -

    case "$PROFILE" in
        desktop)
            info "Installing desktop-only pacman packages..."
            install_from_list "$DOTFILES_DIR/pkgs-pacman-desktop.txt" | \
                sudo pacman -S --needed --noconfirm -
            ;;
        wsl)
            info "Installing WSL-specific pacman packages..."
            install_from_list "$DOTFILES_DIR/pkgs-pacman-wsl.txt" | \
                sudo pacman -S --needed --noconfirm -
            ;;
    esac

    if ! command -v yay &>/dev/null; then
        info "Installing yay..."
        sudo pacman -S --needed --noconfirm git base-devel
        git clone https://aur.archlinux.org/yay.git /tmp/yay-install
        (cd /tmp/yay-install && makepkg -si --noconfirm)
        rm -rf /tmp/yay-install
    fi

    info "Installing base AUR packages..."
    install_from_list "$DOTFILES_DIR/pkgs-aur.txt" | \
        yay -S --needed --noconfirm -

    case "$PROFILE" in
        desktop)
            info "Installing desktop-only AUR packages..."
            install_from_list "$DOTFILES_DIR/pkgs-aur-desktop.txt" | \
                yay -S --needed --noconfirm -
            ;;
        wsl)
            info "Installing WSL-specific AUR packages..."
            install_from_list "$DOTFILES_DIR/pkgs-aur-wsl.txt" | \
                yay -S --needed --noconfirm -
            ;;
    esac
}

# -----------------------------------------------------------
# BlackArch Repository Setup
# -----------------------------------------------------------
setup_blackarch() {
    if ! pacman -Sl blackarch &>/dev/null; then
        info "Installing BlackArch repository..."
        local tmpdir
        tmpdir="$(mktemp -d)"
        curl -fsSL https://blackarch.org/strap.sh -o "$tmpdir/strap.sh"
        chmod +x "$tmpdir/strap.sh"
        sudo "$tmpdir/strap.sh"
        rm -rf "$tmpdir"
        sudo pacman -Syy
    else
        warn "BlackArch repository already configured."
    fi

    info "Installing BlackArch tools..."
    install_from_list "$DOTFILES_DIR/pkgs-blackarch.txt" | \
        sudo pacman -S --needed --noconfirm -
}

# -----------------------------------------------------------
# 2. System configs (requires sudo)
# -----------------------------------------------------------
setup_system() {
    info "Applying system configurations..."

    if [[ "$PROFILE" == "desktop" ]]; then
        # earlyoom
        sudo cp "$DOTFILES_DIR/system/earlyoom" /etc/default/earlyoom
        info "earlyoom config applied."
    fi

    # swappiness
    sudo cp "$DOTFILES_DIR/system/99-swappiness.conf" /etc/sysctl.d/99-swappiness.conf
    sudo sysctl --load=/etc/sysctl.d/99-swappiness.conf
    info "Swappiness set to 10."

    # Swap file (8 GB on NVMe)
    if [[ ! -f /swapfile ]]; then
        if ask "Create 8 GB swap file?"; then
            info "Creating swap file..."
            sudo dd if=/dev/zero of=/swapfile bs=1M count=8192 status=progress
            sudo chmod 600 /swapfile
            sudo mkswap /swapfile
            sudo swapon -p 10 /swapfile
            if ! grep -q '/swapfile' /etc/fstab; then
                echo '/swapfile none swap sw,pri=10 0 0' | sudo tee -a /etc/fstab
            fi
            info "Swap file created and enabled."
        fi
    else
        warn "Swap file already exists, skipping."
    fi
}

# -----------------------------------------------------------
# 3. Enable services
# -----------------------------------------------------------
enable_services() {
    info "Enabling system services..."

    local system_services=()
    local user_services=()

    case "$PROFILE" in
        desktop)
            system_services=(
                NetworkManager
                sddm
                systemd-resolved
                systemd-timesyncd
                fstrim.timer
                bluetooth
                cups
                earlyoom
            )
            user_services=(
                hypridle
                hyprpaper
                hyprpolkitagent
                kanata
                pipewire
                pipewire-pulse
                waybar
                wireplumber
            )
            ;;
        wsl)
            system_services=(
                systemd-resolved
                systemd-timesyncd
            )
            ;;
        blackarch)
            system_services=(
                NetworkManager
                sddm
                systemd-resolved
                systemd-timesyncd
                fstrim.timer
            )
            user_services=(
                hypridle
                hyprpaper
                hyprpolkitagent
                kanata
                pipewire
                pipewire-pulse
                waybar
                wireplumber
            )
            ;;
    esac

    for svc in "${system_services[@]}"; do
        sudo systemctl enable --now "$svc" 2>/dev/null && info "  $svc enabled" || warn "  $svc skipped"
    done

    for svc in "${user_services[@]}"; do
        systemctl --user enable "$svc" 2>/dev/null && info "  $svc (user) enabled" || warn "  $svc (user) skipped"
    done
}

# -----------------------------------------------------------
# 4. Fish shell
# -----------------------------------------------------------
setup_shell() {
    if [[ "$SHELL" != *"fish"* ]]; then
        if ask "Set fish as default shell?"; then
            chsh -s "$(which fish)"
            info "Default shell changed to fish. Re-login to apply."
        fi
    else
        info "Fish is already the default shell."
    fi
}

# -----------------------------------------------------------
# 5. Extra package managers (flatpak/cargo/pnpm)
# -----------------------------------------------------------
install_extras() {
    # Flatpak (solo si existe y no es WSL)
    if command -v flatpak &>/dev/null && [[ "$PROFILE" != "wsl" ]]; then
        local flatpak_list="$DOTFILES_DIR/pkgs-flatpak.txt"
        if [[ -f "$flatpak_list" ]] && [[ -s "$flatpak_list" ]]; then
            info "Installing Flatpak apps..."
            while IFS= read -r app; do
                flatpak install -y flathub "$app" 2>/dev/null || warn "  $app failed"
            done < <(install_from_list "$flatpak_list")
        fi
    fi

    # Cargo
    if command -v cargo &>/dev/null; then
        local cargo_list="$DOTFILES_DIR/pkgs-cargo.txt"
        if [[ -f "$cargo_list" ]] && [[ -s "$cargo_list" ]]; then
            info "Installing Cargo crates..."
            while IFS= read -r crate; do
                cargo install "$crate" 2>/dev/null || warn "  $crate failed"
            done < <(install_from_list "$cargo_list")
        fi
    fi

    # PNPM
    if command -v pnpm &>/dev/null; then
        local pnpm_list="$DOTFILES_DIR/pkgs-pnpm.txt"
        if [[ -f "$pnpm_list" ]] && [[ -s "$pnpm_list" ]]; then
            info "Installing PNPM globals..."
            install_from_list "$pnpm_list" | \
                xargs pnpm add -g 2>/dev/null || warn "  pnpm install failed"
        fi
    fi
}

# -----------------------------------------------------------
# Main
# -----------------------------------------------------------
main() {
    echo ""
    echo "========================================="
    case "$PROFILE" in
        blackarch) echo "  redfoxd's BlackArch VM Bootstrap" ;;
        wsl)       echo "  redfoxd's Arch WSL Bootstrap" ;;
        *)         echo "  redfoxd's Arch Linux Bootstrap" ;;
    esac
    echo "========================================="
    echo ""

    ask "Install packages (pacman + AUR)?"  && install_packages
    if [[ "$PROFILE" == "blackarch" ]]; then
        ask "Setup BlackArch repo & tools?"  && setup_blackarch
    fi
    if [[ "$PROFILE" != "wsl" ]]; then
        ask "Apply system configs?"         && setup_system
    fi
    ask "Enable services?"                  && enable_services
    ask "Install extras (flatpak/cargo/pnpm)?" && install_extras
    ask "Set fish as default shell?"        && setup_shell

    echo ""
    info "Done! Reboot to apply all changes."
}

main "$@"
