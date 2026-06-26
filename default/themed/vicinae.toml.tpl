# maitri Vicinae theme, generated from the active theme's colors.toml.
# The double-brace placeholders are filled by maitri-theme-set-templates; the
# AT-AT markers (variant/inherits) are filled by maitri-theme-set-vicinae.
# Only the reliably mappable core colors are set here; secondary_background and
# border are intentionally left for Vicinae to derive from core + the base
# theme, so light and dark palettes both stay legible.
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

[colors.accents]
red = "{{ color1 }}"
green = "{{ color2 }}"
yellow = "{{ color3 }}"
blue = "{{ color4 }}"
magenta = "{{ color5 }}"
cyan = "{{ color6 }}"
orange = "{{ color3 }}"
purple = "{{ color5 }}"
