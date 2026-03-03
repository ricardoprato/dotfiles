#!/bin/bash
# Auto DND when screen sharing via Hyprland socket events

SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
AUTO_FILE="/tmp/.dnd-auto"

rm -f "$AUTO_FILE"

refresh_waybar() {
    pkill -RTMIN+10 waybar 2>/dev/null
}

get_notification_count() {
    dunstctl count waiting 2>/dev/null || echo "0"
}

enable_dnd() {
    # If DND is already on (user toggled it manually), don't interfere
    if [ "$(dunstctl is-paused 2>/dev/null)" = "true" ]; then
        return
    fi
    touch "$AUTO_FILE"
    dunstctl set-paused true
    refresh_waybar
    notify-send -u low -t 2000 "DND Activado" "Compartiendo pantalla"
}

disable_dnd() {
    # Only disable if we were the ones who enabled it
    [ ! -f "$AUTO_FILE" ] && return
    rm -f "$AUTO_FILE"

    if [ "$(dunstctl is-paused 2>/dev/null)" = "true" ]; then
        dunstctl set-paused false
        refresh_waybar

        local count
        count=$(get_notification_count)
        [ "$count" -gt 0 ] 2>/dev/null && notify-send -t 3000 "DND Desactivado" "$count pendientes"
    fi
}

# Monitor Hyprland socket for screencast events only
socat -U - UNIX-CONNECT:"$SOCKET" 2>/dev/null | while read -r line; do
    if [[ "$line" == screencast* ]]; then
        state="${line#*>>}"
        state="${state%%,*}"

        [ "$state" = "1" ] && enable_dnd
        [ "$state" = "0" ] && disable_dnd
    fi
done
