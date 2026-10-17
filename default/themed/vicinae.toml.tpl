# maitri Vicinae theme, generated from the active theme's colors.toml.
# The double-brace placeholders are filled by maitri-theme-set-templates; the
# AT-AT markers (variant/inherits) are filled by maitri-theme-set-vicinae.
#
# Every UI surface (rows, hover, selection, borders, separators, scrollbars,
# inputs, muted text) is set explicitly instead of being auto-derived.
# Lines use border (3:1 against the background) and border_focus; rows and
# text highlights use selection, with foreground text on it, never accent.
# Hovered rows are a light foreground wash so the cursor row stays distinct.
# De-emphasized text is comment, never muted.
[meta]
name = "maitri"
description = "maitri theme (generated from the active maitri palette)"
variant = "@@variant@@"
inherits = "@@inherits@@"

[colors.core]
accent = "{{ accent }}"
accent_foreground = "{{ background }}"
background = "{{ background }}"
foreground = "{{ foreground }}"
secondary_background = "{{ lighter_background }}"
border = "{{ border }}"

[colors.main_window]
border = "{{ border }}"
footer = { background = "{{ lighter_background }}" }

[colors.settings_window]
border = "{{ border }}"

[colors.accents]
blue = "{{ blue }}"
green = "{{ green }}"
magenta = "{{ magenta }}"
orange = "{{ orange }}"
purple = "{{ magenta }}"
red = "{{ red }}"
yellow = "{{ yellow }}"
cyan = "{{ cyan }}"

[colors.shortcut]
border = "{{ border }}"

[colors.tooltip]
background = "{{ background }}"
foreground = "{{ foreground }}"
border = "{{ border }}"

[colors.text]
default = "{{ foreground }}"
muted = "{{ comment }}"
danger = "{{ red }}"
success = "{{ green }}"
placeholder = "{{ comment }}"
selection = { background = "{{ selection }}", foreground = "{{ foreground }}" }

[colors.text.links]
default = "{{ link }}"
visited = "{{ mix link foreground 35% }}"

[colors.input]
background = "{{ lighter_background }}"
border = "{{ border }}"
border_focus = "{{ border_focus }}"
border_error = "{{ red }}"

[colors.button.primary]
background = "{{ lighter_background }}"
foreground = "{{ foreground }}"
hover = { background = "{{ mix lighter_background foreground 6% }}", foreground = "{{ foreground }}" }
focus = { outline = "{{ border_focus }}" }

[colors.list.item.hover]
background = "{{ mix background foreground 6% }}"
foreground = "{{ foreground }}"
secondary_foreground = "{{ comment }}"

[colors.list.item.selection]
background = "{{ selection }}"
foreground = "{{ bright_foreground }}"
secondary_background = "{{ selection }}"
secondary_foreground = "{{ foreground }}"

[colors.grid.item]
background = "{{ lighter_background }}"
hover = { outline = "{{ border_focus }}" }
selection = { outline = "{{ accent }}" }

[colors.scrollbars]
background = "{{ border }}"
secondary_background = "{{ border }}"

[colors.loading]
bar = "{{ accent }}"
spinner = "{{ accent }}"
