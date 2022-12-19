###############################################################################
# apps                                                                        #
###############################################################################

ln -sf $HOME/.dotfiles/apps/nvim/ $HOME/.config
ln -sf $HOME/.dotfiles/apps/htop $HOME/.config

###############################################################################
# zsh                                                                         #
###############################################################################

ln -sf $HOME/.dotfiles/apps/zsh/.zshrc $HOME/

ln -sf $HOME/.dotfiles/system/aliases.zsh $HOME/.oh-my-zsh/lib/aliases.zsh

ln -sf $HOME/.dotfiles/apps/zsh/.p10k.zsh $HOME/

ln -sf $HOME/.dotfiles/apps/zsh/.enviroment.zsh $HOME/
