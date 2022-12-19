#!/bin/sh

###############################################################################
# Install                                                                     #
###############################################################################

echo "Setting up..."

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until `.install` has finished
while true; do
  sudo -n true
  sleep 60
  kill -0 "$$" || exit
done 2>/dev/null &
###############################################################################
# Install                                                                     #
###############################################################################

source ~/.dotfiles/installers/pacman.sh
source ~/.dotfiles/installers/yay.sh
source ~/.dotfiles/installers/pnpm.sh

###############################################################################
# Symlinks                                                                    #
###############################################################################

source ~/.dotfiles/symlinks.sh
