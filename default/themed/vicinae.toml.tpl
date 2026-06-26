# maitri Vicinae theme, generated from the active theme's colors.toml.
# The double-brace placeholders are filled by maitri-theme-set-templates; the
# AT-AT markers (variant/inherits) are filled by maitri-theme-set-vicinae.
#
# This template mirrors the full key structure of Vicinae's bundled "dracula"
# theme so every UI surface (rows, hover, selection, borders, separators,
# scrollbars, inputs, muted text) is set explicitly instead of being
# auto-derived. Structural colors map to {{ selection_background }} (a visibly
# distinct shade in every maitri palette, light or dark) so lines and borders
# stay legible on both dark and light themes. color0/color8 are deliberately
# avoided for structural UI: on light themes color0 == background and color8 is
# near-white, which would make borders/lines invisible.
[meta]
name = "maitri"
description = "maitri theme (generated from the active maitri palette)"
variant = "@@variant@@"
inherits = "@@inherits@@"

[colors.core]
accent = "{{ accent }}"
accent_foreground = "{{ background }}"
background = "#D9{{ background_strip }}"  # ~85% alpha (ARGB) → frosted glass over the Hyprland blur
foreground = "{{ foreground }}"
secondary_background = "{{ selection_background }}"
border = "{{ selection_background }}"

[colors.accents]
blue = "{{ color4 }}"
green = "{{ color2 }}"
magenta = "{{ color5 }}"
orange = "{{ color3 }}"
purple = "{{ color5 }}"
red = "{{ color1 }}"
yellow = "{{ color3 }}"
cyan = "{{ color6 }}"

[colors.text]
default = "{{ foreground }}"
muted = "{{ color7 }}"
danger = "{{ color1 }}"
success = "{{ color2 }}"
placeholder = "{{ color7 }}"
selection = { background = "{{ accent }}", foreground = "{{ background }}" }

[colors.text.links]
default = "{{ accent }}"
visited = "{{ color5 }}"

# Input field borders use {{ accent }} (not {{ selection_background }}): the input
# box fill is secondary_background == selection_background, so a selection_background
# border is invisible and fields read as featureless rectangles. color8 is unsafe here
# (== near-white on light themes like daybreak). accent is distinct from the fill on
# both dark and light palettes, so fields stay clearly delineated.
[colors.input]
border = "{{ accent }}"
border_focus = "{{ accent }}"
border_error = "{{ color1 }}"

[colors.button.primary]
background = "{{ selection_background }}"
foreground = "{{ foreground }}"
focus = { outline = "{{ accent }}" }

[colors.list.item.hover]
background = "{{ selection_background }}"
foreground = "{{ foreground }}"
secondary_foreground = "{{ color7 }}"

[colors.list.item.selection]
background = "{{ selection_background }}"
foreground = "{{ selection_foreground }}"
secondary_background = "{{ selection_background }}"
secondary_foreground = "{{ selection_foreground }}"

[colors.grid.item]
background = "{{ selection_background }}"
hover = { outline = "{{ accent }}" }
selection = { outline = "{{ accent }}" }

[colors.scrollbars]
background = "{{ selection_background }}"

[colors.loading]
bar = "{{ accent }}"
spinner = "{{ accent }}"
