#!/bin/bash
# Post-processing after wallbash hyprland color update

source "$(dirname "$(realpath "$0")")/globalcontrol.sh"

# Determine color-scheme from wallbash mode
enableWallDcol=$(grep '^enableWallDcol' "$hydeConfDir/hyde.conf" 2>/dev/null | cut -d'"' -f2)
dcol_mode="${dcol_mode:-dark}"

case "${enableWallDcol}" in
    0) color_scheme="prefer-dark" ;;  # theme mode — follow theme
    1) color_scheme="prefer-${dcol_mode}" ;;  # auto — follow wallpaper
    2) color_scheme="prefer-dark" ;;  # force dark
    3) color_scheme="prefer-light" ;; # force light
    *) color_scheme="prefer-dark" ;;
esac

# Apply to GTK apps via gsettings
gsettings set org.gnome.desktop.interface color-scheme "$color_scheme"

# Update GTK settings.ini
for settings_file in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"; do
    if [ -f "$settings_file" ]; then
        if [ "$color_scheme" = "prefer-dark" ]; then
            sed -i 's/gtk-application-prefer-dark-theme=false/gtk-application-prefer-dark-theme=true/' "$settings_file"
        else
            sed -i 's/gtk-application-prefer-dark-theme=true/gtk-application-prefer-dark-theme=false/' "$settings_file"
        fi
    fi
done

# Reload Hyprland config
hyprctl reload
