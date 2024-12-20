###############################################################################
# Aliases                                                                     #
###############################################################################

# Whenever I forget one of many zsh aliases
alias alz="alias | fzf"

# Helpful aliases
alias  l='eza -lh  --icons=auto' # long list
alias ls='eza -1   --icons=auto' # short list
alias ll='eza -lha --icons=auto --sort=name --group-directories-first' # long list all
alias ld='eza -lhD --icons=auto' # long list dirs
alias un='$aurhelper -Rns' # uninstall package
alias up='$aurhelper -Syu' # update system/package/aur
alias pl='$aurhelper -Qs' # list installed package
alias pa='$aurhelper -Ss' # list availabe package
alias pc='$aurhelper -Sc' # remove unused cache
alias po='$aurhelper -Qtdq | $aurhelper -Rns -' # remove unused packages, also try > $aurhelper -Qqd | $aurhelper -Rsu --print -
alias lzd="lazydocker"
alias vc='code --disable-gpu' # gui code editor
alias cat="bat"
alias nvim-kickstart="NVIM_APPNAME=kickstart nvim"

# Handy change dir shortcuts
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias .5='cd ../../../../..'


# Kitty on SSH
[ "$TERM" = "xterm-kitty" ] && alias ssh="kitty +kitten ssh"
