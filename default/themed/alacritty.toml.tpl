[colors.primary]
background = "{{ background }}"
foreground = "{{ foreground }}"

[colors.cursor]
text = "{{ background }}"
cursor = "{{ bright_foreground }}"

[colors.vi_mode_cursor]
text = "{{ background }}"
cursor = "{{ bright_foreground }}"

[colors.search.matches]
foreground = "{{ foreground }}"
background = "{{ mix background green 32% }}"

[colors.search.focused_match]
foreground = "{{ background }}"
background = "{{ orange }}"

[colors.footer_bar]
foreground = "{{ background }}"
background = "{{ foreground }}"

[colors.selection]
text = "{{ selection_foreground }}"
background = "{{ selection_background }}"

[colors.normal]
black = "{{ ansi_black }}"
red = "{{ red }}"
green = "{{ green }}"
yellow = "{{ yellow }}"
blue = "{{ blue }}"
magenta = "{{ magenta }}"
cyan = "{{ cyan }}"
white = "{{ ansi_white }}"

[colors.bright]
black = "{{ ansi_bright_black }}"
red = "{{ bright_red }}"
green = "{{ bright_green }}"
yellow = "{{ bright_yellow }}"
blue = "{{ bright_blue }}"
magenta = "{{ bright_magenta }}"
cyan = "{{ bright_cyan }}"
white = "{{ ansi_bright_white }}"
