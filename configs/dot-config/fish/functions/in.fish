# Detect the AUR wrapper
if pacman -Qi yay >/dev/null 2>&1
    set aurhelper "yay"
else if pacman -Qi paru >/dev/null 2>&1
    set aurhelper "paru"
end

function in
    set pkg $argv[1]

    if command pacman -Si "$pkg" > /dev/null 2>&1
        sudo pacman -S "$pkg"
    else 
        $aurhelper -S "$pkg"
    end
end

