# Rendered to ~/.config/spotify-player/theme.toml by omarchy-theme-set-templates.
# Defines a single theme named "omarchy-current"; app.toml references it via
# theme = "omarchy-current". Re-rendered on every omarchy-theme-set, so this
# entry always tracks the active palette.

[[themes]]
name = "omarchy-current"

[themes.palette]
background     = "{{ background }}"
foreground     = "{{ foreground }}"
black          = "{{ color0 }}"
red            = "{{ color1 }}"
green          = "{{ color2 }}"
yellow         = "{{ color3 }}"
blue           = "{{ color4 }}"
magenta        = "{{ color5 }}"
cyan           = "{{ color6 }}"
white          = "{{ color7 }}"
bright_black   = "{{ color8 }}"
bright_red     = "{{ color9 }}"
bright_green   = "{{ color10 }}"
bright_yellow  = "{{ color11 }}"
bright_blue    = "{{ color12 }}"
bright_magenta = "{{ color13 }}"
bright_cyan    = "{{ color14 }}"
bright_white   = "{{ color15 }}"

[themes.component_style]
block_title                    = { fg = "{{ accent }}",     modifiers = ["Bold"] }
border                         = { fg = "{{ accent }}" }
playback_status                = { fg = "{{ accent }}",     modifiers = ["Bold"] }
playback_track                 = { fg = "{{ foreground }}", modifiers = ["Bold"] }
playback_album                 = { fg = "{{ color2 }}",     modifiers = ["Italic"] }
playback_metadata              = { fg = "{{ color4 }}" }
playback_progress_bar          = { bg = "{{ accent }}",     fg = "{{ background }}" }
playback_progress_bar_unfilled = { fg = "{{ color8 }}" }
current_playing                = { fg = "{{ accent }}",     modifiers = ["Bold"] }
page_desc                      = { fg = "{{ accent }}",     modifiers = ["Bold"] }
playlist_desc                  = { fg = "{{ color2 }}" }
table_header                   = { fg = "{{ accent }}",     modifiers = ["Bold"] }
selection                      = { bg = "{{ selection_background }}", fg = "{{ selection_foreground }}" }
secondary_row                  = { fg = "{{ color8 }}" }
lyrics_played                  = { fg = "{{ color8 }}" }
lyrics_playing                 = { fg = "{{ accent }}",     modifiers = ["Bold"] }
