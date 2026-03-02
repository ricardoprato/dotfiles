#!/bin/bash
# Auto DND when screen sharing via Hyprland socket events

SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
MANUAL_FILE="/tmp/.dnd-manual"

rm -f "$MANUAL_FILE"

get_notification_count() {
    if command -v jq &> /dev/null; then
        dunstctl history 2>/dev/null | jq '[.data[0][] | select(.summary.data | test("DND") | not)] | length' 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

enable_dnd() {
    if [ "$(dunstctl is-paused 2>/dev/null)" = "true" ]; then
        touch "$MANUAL_FILE"
        return
    fi
    rm -f "$MANUAL_FILE"
    dunstctl set-paused true
    notify-send -u low -t 2000 "DND Activado" "Compartiendo pantalla"
}

disable_dnd() {
    [ -f "$MANUAL_FILE" ] && return

    if [ "$(dunstctl is-paused 2>/dev/null)" = "true" ]; then
        dunstctl set-paused false

        local count=$(get_notification_count)
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
