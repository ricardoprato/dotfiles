#!/bin/bash
# Simple Wallbash toggle with Catppuccin fallback
# Cycles: Catppuccin -> Wallbash Auto -> Wallbash Dark -> Wallbash Light -> Catppuccin

STATE_FILE="$HOME/.cache/wallbash-mode"
CATPPUCCIN_COLORS="$HOME/.config/hypr/themes/colors-catppuccin.conf"
COLORS_CONF="$HOME/.config/hypr/themes/colors.conf"

# Modes: 0=catppuccin, 1=auto, 2=dark, 3=light
get_mode() {
    cat "$STATE_FILE" 2>/dev/null || echo "0"
}

set_mode() {
    echo "$1" > "$STATE_FILE"
}

# Apply Catppuccin Mocha colors
apply_catppuccin() {
    cp "$CATPPUCCIN_COLORS" "$COLORS_CONF"

    # Apply GTK/Qt settings
    gsettings set org.gnome.desktop.interface gtk-theme 'catppuccin-mocha-mauve-standard+default'
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

    # Update hyprland borders
    hyprctl keyword general:col.active_border "rgba(cba6f7ff) rgba(f5c2e7ff) 45deg"
    hyprctl keyword general:col.inactive_border "rgba(313244cc) rgba(45475acc) 45deg"

    notify-send -u low -t 2000 "Tema" "Catppuccin Mocha"
}

# Apply Wallbash colors from current wallpaper
apply_wallbash() {
    local mode="$1"
    local wallpaper=$(hyprctl hyprpaper listloaded 2>/dev/null | head -1)

    if [ -z "$wallpaper" ]; then
        # Try swww
        wallpaper=$(swww query 2>/dev/null | grep -oP 'image: \K.*' | head -1)
    fi

    if [ -z "$wallpaper" ] || [ ! -f "$wallpaper" ]; then
        notify-send -u normal "Wallbash" "No se encontró wallpaper"
        return 1
    fi

    # Extract dominant colors using ImageMagick
    if ! command -v magick &>/dev/null && ! command -v convert &>/dev/null; then
        notify-send -u normal "Wallbash" "Necesitas ImageMagick: sudo pacman -S imagemagick"
        return 1
    fi

    # Get colors from wallpaper
    local colors=$(magick "$wallpaper" -resize 50x50! -colors 5 -unique-colors txt:- 2>/dev/null | grep -oP '#[0-9A-Fa-f]{6}' | head -5)

    if [ -z "$colors" ]; then
        colors=$(convert "$wallpaper" -resize 50x50! -colors 5 -unique-colors txt:- 2>/dev/null | grep -oP '#[0-9A-Fa-f]{6}' | head -5)
    fi

    if [ -z "$colors" ]; then
        notify-send -u normal "Wallbash" "No se pudieron extraer colores"
        return 1
    fi

    # Parse colors
    local primary=$(echo "$colors" | sed -n '1p')
    local secondary=$(echo "$colors" | sed -n '2p')
    local accent=$(echo "$colors" | sed -n '3p')

    # Convert to rgba format for hyprland
    local primary_rgba="rgba(${primary:1}ff)"
    local secondary_rgba="rgba(${secondary:1}ff)"
    local accent_rgba="rgba(${accent:1}cc)"

    # Apply to hyprland
    hyprctl keyword general:col.active_border "$primary_rgba $secondary_rgba 45deg"
    hyprctl keyword general:col.inactive_border "$accent_rgba rgba(45475acc) 45deg"

    # Generate colors.conf
    cat > "$COLORS_CONF" << EOF
# Wallbash generated colors from wallpaper
exec = gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'

general {
    col.active_border = $primary_rgba $secondary_rgba 45deg
    col.inactive_border = $accent_rgba rgba(45475acc) 45deg
}

group {
    col.border_active = $primary_rgba $secondary_rgba 45deg
    col.border_inactive = $accent_rgba rgba(45475acc) 45deg
}
EOF

    local mode_name=""
    case $mode in
        1) mode_name="Auto" ;;
        2) mode_name="Dark" ;;
        3) mode_name="Light" ;;
    esac

    notify-send -u low -t 2000 "Wallbash $mode_name" "Colores extraídos del wallpaper"
}

# Main toggle logic
current=$(get_mode)
next=$(( (current + 1) % 4 ))
set_mode "$next"

case $next in
    0)
        apply_catppuccin
        ;;
    1|2|3)
        apply_wallbash "$next"
        ;;
esac
