if status is-interactive
    ###############################################################################
    # Abreviaciones (Abbreviations)                                               #
    ###############################################################################

    # Cuando olvido uno de los muchos alias de zsh
    abbr alz "alias | fzf"

    # Abreviaciones útiles
    abbr l 'eza -lh --icons=auto' # lista larga
    abbr ls 'eza -1 --icons=auto' # lista corta
    abbr ll 'eza -lha --icons=auto --sort=name --group-directories-first' # lista larga todo
    abbr ld 'eza -lhD --icons=auto' # lista larga dirs
    abbr un '$aurhelper -Rns' # desinstalar paquete
    abbr up '$aurhelper -Syu' # actualizar sistema/paquete/aur
    abbr pl '$aurhelper -Qs' # listar paquete instalado
    abbr pa '$aurhelper -Ss' # listar paquete disponible
    abbr pc '$aurhelper -Sc' # eliminar caché no utilizada
    abbr po '$aurhelper -Qtdq | $aurhelper -Rns -' # eliminar paquetes no utilizados, también intenta > $aurhelper -Qqd | $aurhelper -Rsu --print -
    abbr lzd 'lazydocker'
    abbr vc 'code --disable-gpu' # editor de código gui
    abbr cat 'bat'
    abbr nvim-kickstart 'NVIM_APPNAME=kickstart nvim'

    # Atajos útiles para cambiar de directorio
    abbr .. 'cd ..'
    abbr ... 'cd ../..'
    abbr .3 'cd ../../..'
    abbr .4 'cd ../../../..'
    abbr .5 'cd ../../../../..'

    # Kitty en SSH
    if test "$TERM" = "xterm-kitty"
        abbr ssh 'kitty +kitten ssh'
    end
end
