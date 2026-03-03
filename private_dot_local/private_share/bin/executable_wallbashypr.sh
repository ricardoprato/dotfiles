#!/bin/bash
# Post-processing after wallbash hyprland color update

source "$(dirname "$(realpath "$0")")/globalcontrol.sh"

# GTK theme names
THEME_GTK="catppuccin-mocha-mauve-standard+default"  # theme mode (mode 0)
WALLBASH_GTK="Wallbash-Gtk"  # wallbash modes (1-3)

# Reload Hyprland config first (applies border colors from Wall-Dcol.conf)
hyprctl reload

# Determine color-scheme and GTK theme from wallbash mode
enableWallDcol=$(grep '^enableWallDcol' "$hydeConfDir/hyde.conf" 2>/dev/null | cut -d'"' -f2)
dcol_mode="${dcol_mode:-dark}"

case "${enableWallDcol}" in
    0) color_scheme="prefer-dark";  gtk_theme="$THEME_GTK" ;;
    1) color_scheme="prefer-${dcol_mode}"; gtk_theme="$WALLBASH_GTK" ;;
    2) color_scheme="prefer-dark";  gtk_theme="$WALLBASH_GTK" ;;
    3) color_scheme="prefer-light"; gtk_theme="$WALLBASH_GTK" ;;
    *) color_scheme="prefer-dark";  gtk_theme="$THEME_GTK" ;;
esac

# Small delay to ensure hyprctl reload exec commands finish
sleep 0.3

# Apply to GTK apps via gsettings
gsettings set org.gnome.desktop.interface color-scheme "$color_scheme"
gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"

# Update GTK settings.ini
settings_file="$HOME/.config/gtk-3.0/settings.ini"
if [ -f "$settings_file" ]; then
    sed -i "s/^gtk-theme-name=.*/gtk-theme-name=${gtk_theme}/" "$settings_file"
    if [ "$color_scheme" = "prefer-dark" ]; then
        sed -i 's/gtk-application-prefer-dark-theme=false/gtk-application-prefer-dark-theme=true/' "$settings_file"
    else
        sed -i 's/gtk-application-prefer-dark-theme=true/gtk-application-prefer-dark-theme=false/' "$settings_file"
    fi
fi

# Update GTK4 symlink to point to active theme
gtk4_theme_dir="$HOME/.local/share/themes/${gtk_theme}/gtk-4.0"
if [ -d "$gtk4_theme_dir" ]; then
    rm -rf "$HOME/.config/gtk-4.0"
    ln -sf "$gtk4_theme_dir" "$HOME/.config/gtk-4.0"
fi
