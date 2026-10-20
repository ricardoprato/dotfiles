# Per-app env vars consolidated here. Static; previously template-driven
# via the now-removed ~/.config/dotfiles/manifest.toml.

# fzf preview command (tries kitty icat for images, bat for the rest).
# --with-shell: fzf runs previews with $SHELL, which is fish inside tmux
# (default-shell); the preview below is POSIX sh syntax, so pin bash.
# KITTY_WINDOW_ID survives inside tmux (TERM does not). In tmux icat must use
# unicode placeholders so the image moves/clears with the pane.
if set -q KITTY_WINDOW_ID; and set -q TMUX
    set -gx FZF_DEFAULT_OPTS "--with-shell 'bash -c' --preview 'case \$(file --mime-type -b {}) in image/*) kitty icat --clear --transfer-mode=memory --unicode-placeholder --stdin=no --place=\${FZF_PREVIEW_COLUMNS}x\${FZF_PREVIEW_LINES}@0x0 {} ;; *) bat --style=numbers --color=always {} ;; esac'"
else if set -q KITTY_WINDOW_ID
    set -gx FZF_DEFAULT_OPTS "--with-shell 'bash -c' --preview 'case \$(file --mime-type -b {}) in image/*) kitty icat --clear --transfer-mode=memory --stdin=no --place=\${FZF_PREVIEW_COLUMNS}x\${FZF_PREVIEW_LINES}@0x0 {} ;; *) bat --style=numbers --color=always {} ;; esac'"
else
    set -gx FZF_DEFAULT_OPTS "--with-shell 'bash -c' --preview 'bat --style=numbers --color=always {}'"
end

# Claude Code downgrades to 256 colors when $TMUX is set unless this is set.
# tmux here passes truecolor (RGB feature), so keep the exact Catppuccin colors.
set -gx CLAUDE_CODE_TMUX_TRUECOLOR 1
