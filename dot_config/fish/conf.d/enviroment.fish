# General enviroment variables

set -g fish_greeting
set -gx EDITOR (which nvim)
set -gx VISUAL $EDITOR
set -gx SUDO_EDITOR $EDITOR

if pacman -Qi yay >/dev/null 2>&1
    set aurhelper "yay"
else if pacman -Qi paru >/dev/null 2>&1
    set aurhelper "paru"
end

