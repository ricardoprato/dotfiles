# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH=$HOME/.oh-my-zsh

# Load antigen
. $HOME/.dotfiles/apps/antigen/init.zsh

# Case sensitive matches only
CASE_SENSITIVE="true"

# Source and load all things used manually,
# I prefer the explicitness here over a loop

# Reload
source $ZSH/oh-my-zsh.sh

DISABLE_AUTO_UPDATE="true"

ENABLE_CORRECTION="true"

plugins=(
  git
  zsh-syntax-highlighting
  zsh-autosuggestions
)

. $HOME/.dotfiles/system/init.zsh

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# pnpm
export PNPM_HOME="/home/redfoxd/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
# pnpm end

# virtualenv
export VIRTUALENV_HOME="/home/redfoxd/.local/bin"
export PATH="$VIRTUALENV_HOME:$PATH"
# virtualenv end
