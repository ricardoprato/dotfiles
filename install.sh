#!/bin/sh

###############################################################################
# Install                                                                     #
###############################################################################

echo "Setting up..."

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing `sudo` time stamp until `.install` has finished
while true
  sudo -n true
  sleep 60
  kill -0 "$fish_pid" || exit
end 2>/dev/null &

###############################################################################
# Install                                                                     #
###############################################################################

source ~/.dotfiles/apps/starship/install.sh

###############################################################################
# Symlinks                                                                    #
###############################################################################

source ~/.dotfiles/symlinks.sh
