#!/bin/bash

# Alt+Tab con preservacion de fullscreen para Hyprland
FS=$(hyprctl activewindow -j | jq -r '.fullscreen')

if [ "$FS" -eq 0 ] 2>/dev/null; then
    hyprctl --batch "dispatch cyclenext ; dispatch bringactivetotop"
else
    # fullscreen=1 (maximize) → dispatcher arg 1 | fullscreen=2 (real) → dispatcher arg 0
    FS_ARG=$(( 2 - FS ))
    hyprctl --batch "dispatch fullscreen $FS_ARG ; dispatch cyclenext ; dispatch fullscreen $FS_ARG"
fi
