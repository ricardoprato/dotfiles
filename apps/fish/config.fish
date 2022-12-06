alias ls 'lsd'
alias la 'lsd -a'
alias ll 'lsd -l'
alias l 'lsd -l'
alias nv 'nvim'
alias dev 'cd ~/dev'
alias open 'explorer.exe .'
alias gc 'gitmoji -c'
alias fishconfig 'nvim ~/.config/fish/config.fish'
alias df 'cd ~/.dotfiles/ && nvim'

starship init fish | source

# pnpm
set -gx PNPM_HOME "/home/redfoxd/.local/share/pnpm"
set -gx PATH "$PNPM_HOME" $PATH
# pnpm end
