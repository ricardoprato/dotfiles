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

# -----------------------------------------------------------
# 1. Install packages
# -----------------------------------------------------------
install_packages() {
    info "Installing native pacman packages..."
    sudo pacman -S --needed --noconfirm - < "$DOTFILES_DIR/pkgs-pacman.txt"

    if ! command -v yay &>/dev/null; then
        info "Installing yay..."
        sudo pacman -S --needed --noconfirm git base-devel
        git clone https://aur.archlinux.org/yay.git /tmp/yay-install
        (cd /tmp/yay-install && makepkg -si --noconfirm)
        rm -rf /tmp/yay-install
    fi

    info "Installing AUR packages..."
    yay -S --needed --noconfirm - < "$DOTFILES_DIR/pkgs-aur.txt"
}

# -----------------------------------------------------------
# 2. Stow dotfiles
# -----------------------------------------------------------
stow_dotfiles() {
    info "Linking dotfiles with stow..."

    # configs/ -> ~/.config, ~/.gitconfig, ~/.tmux.conf, etc.
    stow -v -d "$DOTFILES_DIR" -t "$HOME" configs

    # scripts/ -> ~/.local/share/bin
    stow -v -d "$DOTFILES_DIR" -t "$HOME" scripts
}

# -----------------------------------------------------------
# 3. System configs (requires sudo)
# -----------------------------------------------------------
setup_system() {
    info "Applying system configurations..."

    # earlyoom
    sudo cp "$DOTFILES_DIR/system/earlyoom" /etc/default/earlyoom
    info "earlyoom config applied."

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
# 4. Enable services
# -----------------------------------------------------------
enable_services() {
    info "Enabling system services..."

    local system_services=(
        bluetooth
        cups
        earlyoom
        NetworkManager
        sddm
        systemd-resolved
        systemd-timesyncd
        fstrim.timer
    )

    local user_services=(
        hypridle
        hyprpaper
        hyprpolkitagent
        kanata
        pipewire
        pipewire-pulse
        waybar
        wireplumber
    )

    for svc in "${system_services[@]}"; do
        sudo systemctl enable --now "$svc" 2>/dev/null && info "  $svc enabled" || warn "  $svc skipped"
    done

    for svc in "${user_services[@]}"; do
        systemctl --user enable "$svc" 2>/dev/null && info "  $svc (user) enabled" || warn "  $svc (user) skipped"
    done
}

# -----------------------------------------------------------
# 5. Fish shell
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
# Main
# -----------------------------------------------------------
main() {
    echo ""
    echo "========================================="
    echo "  redfoxd's Arch Linux Bootstrap"
    echo "========================================="
    echo ""

    ask "Install packages (pacman + AUR)?"  && install_packages
    ask "Link dotfiles with stow?"          && stow_dotfiles
    ask "Apply system configs?"             && setup_system
    ask "Enable services?"                  && enable_services
    ask "Set fish as default shell?"        && setup_shell

    echo ""
    info "Done! Reboot to apply all changes."
}

main "$@"
