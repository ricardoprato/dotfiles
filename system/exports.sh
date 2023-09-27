# Increase Bash history size. Allow 32³ entries; the default is 500.
export HISTSIZE='32768';
export HISTFILESIZE="${HISTSIZE}";
export HISTFILE=~/.zsh_history

# Omit duplicates and commands that begin with a space from history.
export HISTCONTROL='ignoreboth';

# Don't record some commands
export HISTIGNORE="&:[ ]*:exit:ls:bg:fg:history:clear";

# Don't clear the screen after quitting a manual page.
export MANPAGER='less -X';

# pnpm
export PNPM_HOME="/home/redfoxd/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
# pnpm end

# virtualenv
export VIRTUALENV_HOME="/home/redfoxd/.local/bin"
export PATH="$VIRTUALENV_HOME:$PATH"
# virtualenv end

# fnm
export PATH=/home/$USER/.fnm:$PATH
eval "$(fnm env --use-on-cd --version-file-strategy=recursive)"
# fnm end

# deno
export DENO_INSTALL="/home/redfoxd/.deno"
export PATH="$DENO_INSTALL/bin:$PATH"
# deno end

