function open --description 'xdg-open detached'
    xdg-open $argv >/dev/null 2>&1 &
end
