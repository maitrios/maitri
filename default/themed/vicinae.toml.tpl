# maitri Vicinae theme, generated from the active theme's colors.toml.
# The double-brace placeholders are filled by maitri-theme-set-templates; the
# AT-AT markers (variant/inherits) are filled by maitri-theme-set-vicinae.
#
# Every UI surface (rows, hover, selection, borders, separators, scrollbars,
# inputs, muted text) is set explicitly instead of being auto-derived.
# Structural colors map to {{ selection }}, a visibly distinct shade in every
# maitri palette, light or dark, so lines and borders stay legible.
# De-emphasized text maps to the dark_foreground key, never muted: muted is the
# ANSI color8 / divider shade and sits at 1.5-3.9:1 against the background in the
# shipped palettes, well under the 4.5:1 needed to read it.
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
secondary_background = "{{ selection }}"
border = "{{ selection }}"

[colors.accents]
blue = "{{ blue }}"
green = "{{ green }}"
magenta = "{{ magenta }}"
orange = "{{ orange }}"
purple = "{{ magenta }}"
red = "{{ red }}"
yellow = "{{ yellow }}"
cyan = "{{ cyan }}"

[colors.text]
default = "{{ foreground }}"
muted = "{{ dark_foreground }}"
danger = "{{ red }}"
success = "{{ green }}"
placeholder = "{{ dark_foreground }}"
selection = { background = "{{ accent }}", foreground = "{{ background }}" }

[colors.text.links]
default = "{{ accent }}"
visited = "{{ magenta }}"

# Input field borders use {{ accent }}: the input fill is secondary_background,
# so a matching border would leave fields as featureless rectangles.
[colors.input]
border = "{{ accent }}"
border_focus = "{{ accent }}"
border_error = "{{ red }}"

[colors.button.primary]
background = "{{ selection }}"
foreground = "{{ foreground }}"
focus = { outline = "{{ accent }}" }

[colors.list.item.hover]
background = "{{ selection }}"
foreground = "{{ foreground }}"
secondary_foreground = "{{ dark_foreground }}"

[colors.list.item.selection]
background = "{{ selection }}"
foreground = "{{ bright_foreground }}"
secondary_background = "{{ selection }}"
secondary_foreground = "{{ bright_foreground }}"

[colors.grid.item]
background = "{{ selection }}"
hover = { outline = "{{ accent }}" }
selection = { outline = "{{ accent }}" }

[colors.scrollbars]
background = "{{ selection }}"

[colors.loading]
bar = "{{ accent }}"
spinner = "{{ accent }}"
