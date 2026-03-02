#!/bin/bash

# Hyprland Gamemode Toggle Script
# Toggles between normal and gaming performance mode

GAMEMODE_FILE="$HOME/.cache/hypr-gamemode"
GAMEMODE_CONF="$HOME/.config/hypr/gamemode.conf"

notify() {
    notify-send -a "Hyprland" -u low -t 2000 "$1" "$2"
}

enable_gamemode() {
    # Disable blur
    hyprctl keyword decoration:blur:enabled false
    hyprctl keyword decoration:shadow:enabled false

    # Disable animations
    hyprctl keyword animations:enabled false

    # Performance settings
    hyprctl keyword misc:vfr 0
    hyprctl keyword misc:vrr 2
    hyprctl keyword misc:no_direct_scanout false

    # Mark as enabled
    echo "enabled" > "$GAMEMODE_FILE"

    notify "Gaming Mode" "Activado - Rendimiento máximo"
    pkill -RTMIN+9 waybar  # Refresh waybar icon
}

disable_gamemode() {
    # Re-enable blur
    hyprctl keyword decoration:blur:enabled true
    hyprctl keyword decoration:shadow:enabled true

    # Re-enable animations
    hyprctl keyword animations:enabled true

    # Normal settings
    hyprctl keyword misc:vfr 1
    hyprctl keyword misc:vrr 1
    hyprctl keyword misc:no_direct_scanout true

    # Mark as disabled
    rm -f "$GAMEMODE_FILE"

    notify "Gaming Mode" "Desactivado - Modo normal"
    pkill -RTMIN+9 waybar  # Refresh waybar icon
}

get_status() {
    if [[ -f "$GAMEMODE_FILE" ]]; then
        echo "enabled"
    else
        echo "disabled"
    fi
}

# Waybar output
waybar_output() {
    if [[ -f "$GAMEMODE_FILE" ]]; then
        echo '{"text": "󰊴", "tooltip": "Gaming Mode: ON", "class": "gaming-on"}'
    else
        echo '{"text": "󰊴", "tooltip": "Gaming Mode: OFF", "class": "gaming-off"}'
    fi
}

case "$1" in
    --status)
        get_status
        ;;
    --waybar)
        waybar_output
        ;;
    --on)
        enable_gamemode
        ;;
    --off)
        disable_gamemode
        ;;
    *)
        # Toggle
        if [[ -f "$GAMEMODE_FILE" ]]; then
            disable_gamemode
        else
            enable_gamemode
        fi
        ;;
esac
