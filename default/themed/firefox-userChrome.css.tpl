/* maitri Theme for Firefox and Zen */

/* Variables Firefox has since renamed are also set under their older names,
   which Zen and Firefox ESR still read. */
:root, .smartbar {
  color-scheme: {{ mode }} !important;
  --toolbar-color-scheme: {{ mode }} !important;

  --toolbox-background-color: {{ dark_background }} !important;
  --toolbox-background-color-inactive: {{ dark_background }} !important;
  --toolbox-text-color: {{ foreground }} !important;
  --toolbox-text-color-inactive: {{ light_foreground }} !important;
  --lwt-accent-color: {{ dark_background }} !important;
  --lwt-accent-color-inactive: {{ dark_background }} !important;
  --lwt-text-color: {{ foreground }} !important;

  --toolbar-background-color: {{ background }} !important;
  --toolbar-bgcolor: {{ background }} !important;
  --toolbar-text-color: {{ foreground }} !important;
  --toolbar-color: {{ foreground }} !important;
  --toolbarbutton-icon-fill: {{ light_foreground }} !important;
  --toolbarbutton-icon-fill-attention: {{ accent }} !important;
  --toolbarbutton-hover-background: {{ mix background foreground 10% }} !important;
  --toolbarbutton-active-background: {{ mix background foreground 16% }} !important;
  --button-background-color-ghost-hover: {{ mix background foreground 10% }} !important;
  --button-background-color-ghost-active: {{ mix background foreground 16% }} !important;
  --chrome-content-separator-color: {{ border }} !important;
  --tabs-navbar-separator-color: {{ border }} !important;

  --tab-background-color-selected: {{ background }} !important;
  --tab-selected-bgcolor: {{ background }} !important;
  --tab-text-color-selected: {{ foreground }} !important;
  --tab-selected-textcolor: {{ foreground }} !important;
  --tab-text-color: {{ light_foreground }} !important;
  --tab-background-color-hover: {{ mix dark_background foreground 8% }} !important;
  --tab-hover-background-color: {{ mix dark_background foreground 8% }} !important;
  --tab-text-color-hover: {{ foreground }} !important;
  --tab-border-color-selected: {{ border_focus }} !important;
  --tab-loading-fill: {{ accent }} !important;
  --tab-attention-dot-color: {{ accent }} !important;
  --tab-dragover-outline-color: {{ border_focus }} !important;

  --toolbar-field-background-color: {{ lighter_background }} !important;
  --toolbar-field-text-color: {{ foreground }} !important;
  --toolbar-field-color: {{ foreground }} !important;
  --toolbar-field-border-color: {{ border }} !important;
  --toolbar-field-background-color-focus: {{ dark_background }} !important;
  --toolbar-field-focus-background-color: {{ dark_background }} !important;
  --toolbar-field-text-color-focus: {{ foreground }} !important;
  --toolbar-field-focus-color: {{ foreground }} !important;
  --toolbar-field-border-color-focus: {{ border_focus }} !important;
  --toolbar-field-focus-border-color: {{ border_focus }} !important;
  --lwt-toolbar-field-highlight: {{ selection }} !important;
  --lwt-toolbar-field-highlight-text: {{ foreground }} !important;

  --urlbarview-background-color-selected: {{ mix dark_background accent 22% }} !important;
  --urlbarView-highlight-background: {{ mix dark_background accent 22% }} !important;
  --urlbarview-text-color-selected: {{ foreground }} !important;
  --urlbarView-highlight-color: {{ foreground }} !important;
  --urlbarview-background-color-hover: {{ lighter_background }} !important;
  --urlbarView-hover-background: {{ lighter_background }} !important;
  --urlbarview-text-color-hover: {{ foreground }} !important;
  --urlbarView-url-color: {{ link }} !important;
  --urlbar-popup-url-color: {{ link }} !important;
  --urlbarview-text-color-action: {{ light_foreground }} !important;
  --urlbarView-action-color: {{ light_foreground }} !important;
  --urlbarview-text-color-secondary: {{ light_foreground }} !important;
  --urlbarView-secondary-text-color: {{ light_foreground }} !important;
  --urlbarview-separator-color: {{ border }} !important;

  --panel-background-color: {{ dark_background }} !important;
  --arrowpanel-background: {{ dark_background }} !important;
  --panel-text-color: {{ foreground }} !important;
  --arrowpanel-color: {{ foreground }} !important;
  --panel-border-color: {{ border }} !important;
  --arrowpanel-border-color: {{ border }} !important;
  --panel-separator-color: {{ border }} !important;
  --panel-item-hover-bgcolor: {{ mix dark_background foreground 6% }} !important;
  --arrowpanel-dimmed: {{ mix dark_background foreground 6% }} !important;
  --panel-item-active-bgcolor: {{ mix dark_background accent 30% }} !important;
  --arrowpanel-dimmed-further: {{ mix dark_background accent 30% }} !important;
  --panel-description-color: {{ comment }} !important;

  --sidebar-background-color: {{ dark_background }} !important;
  --sidebar-text-color: {{ foreground }} !important;
  --sidebar-border-color: {{ border }} !important;
  --sidebar-divider-color: {{ border }} !important;

  --color-accent-primary: {{ accent }} !important;
  --color-accent-primary-hover: {{ mix accent foreground 13% }} !important;
  --color-accent-primary-active: {{ mix accent foreground 26% }} !important;
  --color-accent-primary-selected: {{ mix dark_background accent 30% }} !important;
  --button-text-color-primary: {{ background }} !important;
  --button-text-color-primary-hover: {{ background }} !important;
  --button-text-color-primary-active: {{ background }} !important;
  --focus-outline-color: {{ accent }} !important;
  --link-color: {{ link }} !important;
  --link-color-hover: {{ mix link foreground 20% }} !important;
  --link-color-active: {{ mix link foreground 35% }} !important;
  --icon-color-critical: {{ red }} !important;
  --icon-color-warning: {{ orange }} !important;
  --icon-color-information: {{ hint }} !important;
  --icon-color-success: {{ green }} !important;
  --text-color-error: {{ red }} !important;

  --newtab-background-color: {{ background }} !important;
  --newtab-background-color-secondary: {{ dark_background }} !important;
  --newtab-text-primary-color: {{ foreground }} !important;

  --zen-primary-color: {{ accent }} !important;
  --toolbox-textcolor: {{ foreground }} !important;
  --toolbox-textcolor-inactive: {{ light_foreground }} !important;
  --zen-colors-primary: {{ mix dark_background accent 30% }} !important;
  --zen-colors-secondary: {{ lighter_background }} !important;
  --zen-colors-tertiary: {{ dark_background }} !important;
  --zen-colors-hover-bg: {{ mix dark_background foreground 8% }} !important;
  --zen-colors-primary-foreground: {{ foreground }} !important;
  --zen-colors-border: {{ border }} !important;
  --zen-colors-border-contrast: {{ border_focus }} !important;
  --zen-colors-input-bg: {{ lighter_background }} !important;
  --zen-input-border-color: {{ border }} !important;
  --zen-dialog-background: {{ dark_background }} !important;
  --zen-in-content-dialog-background: {{ dark_background }} !important;
  --zen-urlbar-background: {{ lighter_background }} !important;
  --zen-main-browser-background: {{ dark_background }} !important;
  --zen-main-browser-background-toolbar: {{ dark_background }} !important;
  --zen-main-browser-background-old: {{ dark_background }} !important;
  --zen-main-browser-background-toolbar-old: {{ dark_background }} !important;
  --zen-themed-toolbar-bg: {{ dark_background }} !important;
  --zen-themed-toolbar-bg-transparent: {{ dark_background }} !important;
  --zen-toolbar-element-bg: {{ mix dark_background foreground 8% }} !important;
  --zen-toolbar-element-bg-hover: {{ mix dark_background foreground 12% }} !important;
}

/* Context menus redefine these on the popup itself, so the :root values never reach them. */
:is(menupopup, panel) {
  --panel-background-color: {{ dark_background }} !important;
  --panel-text-color: {{ foreground }} !important;
  --panel-border-color: {{ border }} !important;
}

/* Zen sets these inline on each space from the space's own gradient. */
zen-workspace {
  color-scheme: {{ mode }} !important;
  --toolbox-textcolor: {{ foreground }} !important;
  --zen-primary-color: {{ accent }} !important;
}

::selection {
  background-color: {{ selection }} !important;
  color: {{ foreground }} !important;
}
