function n --description 'nvim wrapper: open . if no args'
    if test (count $argv) -eq 0
        command nvim .
    else
        command nvim $argv
    end
end
