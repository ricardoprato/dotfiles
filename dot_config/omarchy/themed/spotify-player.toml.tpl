# User template (upstream's omarchy-theme-set-templates renders it into
# ~/.local/state/omarchy/current/theme/spotify-player.toml). Defines a single
# theme named "omarchy-current"; app.toml references it via
# theme = "omarchy-current". ~/.config/spotify-player/theme.toml is a symlink to
# the rendered file, so every omarchy-theme-set retints it.

[[themes]]
name = "omarchy-current"

[themes.palette]
background     = "{{ background }}"
foreground     = "{{ foreground }}"
black          = "{{ background }}"
red            = "{{ red }}"
green          = "{{ green }}"
yellow         = "{{ yellow }}"
blue           = "{{ blue }}"
magenta        = "{{ magenta }}"
cyan           = "{{ cyan }}"
white          = "{{ foreground }}"
bright_black   = "{{ muted }}"
bright_red     = "{{ bright_red }}"
bright_green   = "{{ bright_green }}"
bright_yellow  = "{{ bright_yellow }}"
bright_blue    = "{{ bright_blue }}"
bright_magenta = "{{ bright_magenta }}"
bright_cyan    = "{{ bright_cyan }}"
bright_white   = "{{ bright_foreground }}"

[themes.component_style]
block_title                    = { fg = "{{ accent }}",     modifiers = ["Bold"] }
border                         = { fg = "{{ accent }}" }
playback_status                = { fg = "{{ accent }}",     modifiers = ["Bold"] }
playback_track                 = { fg = "{{ foreground }}", modifiers = ["Bold"] }
playback_album                 = { fg = "{{ green }}",     modifiers = ["Italic"] }
playback_metadata              = { fg = "{{ blue }}" }
playback_progress_bar          = { bg = "{{ accent }}",     fg = "{{ background }}" }
playback_progress_bar_unfilled = { fg = "{{ muted }}" }
current_playing                = { fg = "{{ accent }}",     modifiers = ["Bold"] }
page_desc                      = { fg = "{{ accent }}",     modifiers = ["Bold"] }
playlist_desc                  = { fg = "{{ green }}" }
table_header                   = { fg = "{{ accent }}",     modifiers = ["Bold"] }
selection                      = { bg = "{{ selection_background }}", fg = "{{ selection_foreground }}" }
secondary_row                  = { fg = "{{ muted }}" }
lyrics_played                  = { fg = "{{ muted }}" }
lyrics_playing                 = { fg = "{{ accent }}",     modifiers = ["Bold"] }
