###############################################################################
# Aliases                                                                     #
###############################################################################

alias dev="cd ~/dev"
alias cat="bat"
alias zshrc="nvim ~/.dotfiles/.zshrc"

# Whenever I forget one of many zsh aliases
alias alz="alias | fzf"

# List all files colorized in long format
alias l="exa -l"
# List only directories
alias lsd="ls -lF ${colorflag} | grep --color=never '^d'"
# List only hidden files
alias lsh="ls -ld .?*"
# List files
alias ls="exa"
# List everythinh
alias la="exa -la"