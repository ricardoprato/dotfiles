###############################################################################
# apps                                                                        #
###############################################################################

rm -rf $HOME/.config/htop
mkdir -p $HOME/.config/htop
ln -sf $HOME/.dotfiles/apps/htop/ $HOME/.config/htop/

rm -rf $HOME/.config/nvim
ln -sf $HOME/.dotfiles/apps/nvim $HOME/.config/nvim

###############################################################################
# zsh                                                                         #
###############################################################################

rm -rf $HOME/.zshrc
ln -sf $HOME/.dotfiles/apps/zsh/.zshrc $HOME/.zshrc

rm -rf $HOME/.oh-my-zsh/lib/aliases.zsh
ln -sf $HOME/.dotfiles/system/aliases.zsh $HOME/.oh-my-zsh/lib/aliases.zsh

rm -rf $HOME/.p10k.zsh
ln -sf $HOME/.dotfiles/apps/zsh/.p10k.zsh $HOME/

rm -rf $HOME/.enviroment.zsh
ln -sf $HOME/.dotfiles/apps/zsh/.enviroment.zsh $HOME/
