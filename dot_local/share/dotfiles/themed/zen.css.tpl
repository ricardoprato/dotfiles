/* Zen browser UI theme — rendered by the dotfiles theme pipeline.
 * Matches kitty font (JetBrainsMono Nerd Font @ 9pt → ~12px in Wayland) and
 * aligns chrome colors with the active dotfiles palette.
 *
 * Requires about:config -> toolkit.legacyUserProfileCustomizations.stylesheets = true
 * (handled automatically by omarchy-theme-set-zen).
 */

:root {
  --dotfiles-accent: {{ accent }};
  --dotfiles-foreground: {{ foreground }};
  --dotfiles-background: {{ background }};
  --dotfiles-selection-bg: {{ selection_background }};
  --dotfiles-selection-fg: {{ selection_foreground }};

  /* Zen-specific overrides — these are the public design tokens zen reads. */
  --zen-primary-color: {{ accent }} !important;
  --zen-themed-toolbar-bg: {{ background }} !important;
}

/* Match kitty: JetBrains Mono everywhere in the chrome at 12px. */
#main-window,
#navigator-toolbox,
#TabsToolbar,
#PersonalToolbar,
#nav-bar,
.tab-label,
.tab-secondary-label,
menupopup,
panel {
  font-family: "JetBrainsMono Nerd Font", "JetBrains Mono", monospace !important;
  font-size: 12px !important;
}

/* URL bar slightly larger for readability */
#urlbar .urlbar-input,
#urlbar-input {
  font-family: "JetBrainsMono Nerd Font", "JetBrains Mono", monospace !important;
  font-size: 13px !important;
}

/* Selected tab — accent underline + themed background */
.tabbrowser-tab[selected="true"] .tab-content {
  border-bottom: 2px solid var(--dotfiles-accent) !important;
}

.tabbrowser-tab[selected="true"] {
  background-color: color-mix(in srgb, var(--dotfiles-background) 85%, var(--dotfiles-accent) 15%) !important;
}

/* URL bar focus ring */
#urlbar[focused="true"] {
  outline: 1px solid var(--dotfiles-accent) !important;
}

/* Menu popup body */
menupopup, panel {
  --panel-background: var(--dotfiles-background) !important;
  --panel-color: var(--dotfiles-foreground) !important;
}

/* Selection highlight in inputs */
#urlbar .urlbar-input::selection,
textarea::selection,
input::selection {
  background-color: var(--dotfiles-selection-bg) !important;
  color: var(--dotfiles-selection-fg) !important;
}
