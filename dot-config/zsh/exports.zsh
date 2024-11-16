# Increase Bash history size. Allow 32³ entries; the default is 500.
export HISTSIZE='32768';
export HISTFILE=~/.zsh_history
export HISTFILESIZE="${HISTSIZE}";
export SAVEHIST="${HISTSIZE}"
setopt SHARE_HISTORY

# Omit duplicates and commands that begin with a space from history.
export HISTCONTROL='ignoreboth';

# Don't record some commands
export HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear";

# Don't clear the screen after quitting a manual page.
export MANPAGER='less -X';

export EDITOR="nvim"
export TERMINAL="kitty"

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
# pnpm end

# virtualenv
export VIRTUALENV_HOME="$HOME.local/bin"
export PATH="$VIRTUALENV_HOME:$PATH"
# virtualenv end

# deno
export DENO_INSTALL="$HOME/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"
# deno end
