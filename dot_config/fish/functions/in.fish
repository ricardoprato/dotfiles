function in
    set pkg $argv[1]

    if command pacman -Si "$pkg" > /dev/null 2>&1
        sudo pacman -S "$pkg"
    else 
        $aurhelper -S "$pkg"
    end
end

