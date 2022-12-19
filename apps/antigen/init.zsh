###############################################################################
# Antigen                                                                     #
###############################################################################
source $HOME/antigen.zsh

antigen bundle Aloxaf/fzf-tab
antigen use oh-my-zsh
antigen bundle git
antigen bundle git-extras
antigen bundle npm
antigen bundle zsh-users/zsh-autosuggestions
antigen bundle zsh-users/zsh-completions
antigen bundle zsh-users/zsh-syntax-highlighting
antigen theme romkatv/powerlevel10k 
antigen bundle MichaelAquilina/zsh-autoswitch-virtualenv
antigen apply
