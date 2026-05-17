# Per-app env vars consolidated here. Static; previously template-driven
# via the now-removed ~/.config/dotfiles/manifest.toml.

# fzf preview command (tries kitty icat for images, bat for the rest).
if test "$TERM" = "xterm-kitty"
    set -gx FZF_DEFAULT_OPTS "--preview 'case (file --mime-type -b {}) in image/*) kitty icat --clear --transfer-mode=memory --stdin=no --place={fzf-preview}@0x0 {} ;; *) bat --style=numbers --color=always {} ;; esac'"
else
    set -gx FZF_DEFAULT_OPTS "--preview 'bat --style=numbers --color=always {}'"
end
