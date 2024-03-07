ZIM_HOME=${HOME}/.zim
ZDOTDIR=${HOME}
# Download zimfw plugin manager if missing.
if [[ ! -e ${ZIM_HOME}/zimfw.zsh ]]; then
  curl -fsSL --create-dirs -o ${ZIM_HOME}/zimfw.zsh \
      https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
fi

# Install missing modules, and update ${ZIM_HOME}/init.zsh if missing or outdated.
if [[ ! ${ZIM_HOME}/init.zsh -nt ${ZDOTDIR:-${HOME}}/.zimrc ]]; then
  source ${ZIM_HOME}/zimfw.zsh init -q
fi

# Initialize modules.
source ${ZIM_HOME}/init.zsh

source $HOME/.config/zsh/aliases.zsh
source $HOME/.config/zsh/exports.zsh
source $HOME/.config/zsh/functions.sh
source $HOME/.config/zsh/enviroment.zsh
source $HOME/.config/zsh/keybindings.zsh

#Display Pokemon
pokemon-colorscripts --no-title -r
source /usr/share/nvm/init-nvm.sh

eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
