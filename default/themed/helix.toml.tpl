# Syntax
"attribute" = { fg = "green", modifiers = ["italic"] }

"type" = { fg = "cyan", modifiers = ["italic"] }
"type.builtin" = { fg = "cyan", modifiers = ["italic"] }
"type.parameter" = { fg = "magenta", modifiers = ["italic"] }
"type.enum.variant" = "blue"

"constructor" = "cyan"

"constant" = "blue"
"constant.builtin" = { fg = "blue", modifiers = ["italic"] }
"constant.builtin.boolean" = "blue"
"constant.character" = "magenta"
"constant.character.escape" = "magenta"
"constant.numeric" = "blue"

"string" = "yellow"
"string.regexp" = "red"
"string.special" = "magenta"
"string.special.path" = "yellow"
"string.special.symbol" = "blue"
"string.special.url" = { fg = "link", modifiers = ["underlined"] }

"comment" = { fg = "comment", modifiers = ["italic"] }
"comment.block.documentation" = { fg = "comment", modifiers = ["italic"] }

"variable" = "foreground"
"variable.builtin" = { fg = "blue", modifiers = ["italic"] }
"variable.parameter" = { fg = "orange", modifiers = ["italic"] }
"variable.other.member" = "orange"

"label" = { fg = "blue", modifiers = ["italic"] }

"punctuation" = "light_foreground"
"punctuation.delimiter" = "light_foreground"
"punctuation.bracket" = "light_foreground"
"punctuation.special" = "magenta"

"keyword" = "magenta"
"keyword.directive" = "magenta"

"operator" = "magenta"

"function" = "green"
"function.builtin" = "cyan"
"function.macro" = "green"
"function.method" = "green"
"function.special" = "magenta"

"tag" = "cyan"
"tag.builtin" = "cyan"

"namespace" = "cyan"
"special" = "magenta"

# Markup
"markup.heading.marker" = { fg = "heading1", modifiers = ["bold"] }
"markup.heading.1" = { fg = "heading1", modifiers = ["bold"] }
"markup.heading.2" = { fg = "heading2", modifiers = ["bold"] }
"markup.heading.3" = { fg = "heading3", modifiers = ["bold"] }
"markup.heading.4" = { fg = "heading4", modifiers = ["bold"] }
"markup.heading.5" = { fg = "heading5", modifiers = ["bold"] }
"markup.heading.6" = { fg = "heading6", modifiers = ["bold"] }
"markup.list" = "accent"
"markup.list.checked" = "accent"
"markup.list.unchecked" = "comment"
"markup.bold" = { fg = "bright_foreground", modifiers = ["bold"] }
"markup.italic" = { fg = "foreground", modifiers = ["italic"] }
"markup.strikethrough" = { fg = "comment", modifiers = ["crossed_out"] }
"markup.link.url" = { fg = "comment", modifiers = ["underlined"] }
"markup.link.text" = { fg = "link", modifiers = ["underlined"] }
"markup.link.label" = { fg = "link", modifiers = ["underlined"] }
"markup.quote" = { fg = "light_foreground", modifiers = ["italic"] }
"markup.raw" = "cyan"
"markup.raw.block" = "foreground"

# Diff
"diff.plus" = "green"
"diff.minus" = "red"
"diff.delta" = "blue"
"diff.delta.moved" = "cyan"

# Left transparent so the terminal background, which is the theme background, shows through
"ui.background" = { }
"ui.background.separator" = "border"

"ui.linenr" = "comment"
"ui.linenr.selected" = { fg = "accent", modifiers = ["bold"] }
"ui.gutter" = { }
"ui.gutter.selected" = { bg = "cursorline" }

"ui.statusline" = { fg = "light_foreground", bg = "surface" }
"ui.statusline.inactive" = { fg = "comment", bg = "surface" }
"ui.statusline.separator" = { fg = "border", bg = "surface" }
"ui.statusline.normal" = { fg = "background", bg = "accent", modifiers = ["bold"] }
"ui.statusline.insert" = { fg = "background", bg = "green", modifiers = ["bold"] }
"ui.statusline.select" = { fg = "background", bg = "link", modifiers = ["bold"] }

"ui.bufferline" = { fg = "comment", bg = "surface" }
"ui.bufferline.active" = { fg = "bright_foreground", bg = "background", modifiers = ["bold"], underline = { color = "accent", style = "line" } }
"ui.bufferline.background" = { bg = "surface" }

"ui.popup" = { fg = "foreground", bg = "surface" }
"ui.popup.info" = { fg = "foreground", bg = "surface" }
"ui.window" = "border"
"ui.help" = { fg = "foreground", bg = "surface" }
"ui.picker.header" = { fg = "accent", modifiers = ["bold"] }

"ui.text" = "foreground"
"ui.text.focus" = { fg = "bright_foreground", bg = "menu_selected", modifiers = ["bold"] }
"ui.text.inactive" = "comment"
"ui.text.info" = "foreground"
"ui.text.directory" = "accent"

"ui.virtual" = "comment"
"ui.virtual.ruler" = { bg = "surface" }
"ui.virtual.indent-guide" = "guide"
"ui.virtual.whitespace" = "nontext"
"ui.virtual.wrap" = "comment"
"ui.virtual.inlay-hint" = { fg = "comment", bg = "inlay", modifiers = ["italic"] }
"ui.virtual.jump-label" = { fg = "orange", modifiers = ["bold"] }

"ui.selection" = { bg = "selection" }
"ui.selection.primary" = { bg = "selection" }

"ui.cursor" = { fg = "background", bg = "cursor" }
"ui.cursor.primary" = { fg = "background", bg = "cursor" }
"ui.cursor.primary.normal" = { fg = "background", bg = "cursor" }
"ui.cursor.primary.insert" = { fg = "background", bg = "green" }
"ui.cursor.primary.select" = { fg = "background", bg = "link" }
"ui.cursor.match" = { fg = "accent", bg = "reference", modifiers = ["bold"] }

"ui.cursorline.primary" = { bg = "cursorline" }
"ui.cursorcolumn.primary" = { bg = "cursorline" }

"ui.highlight" = { bg = "reference", modifiers = ["bold"] }

"ui.menu" = { fg = "foreground", bg = "surface" }
"ui.menu.selected" = { fg = "bright_foreground", bg = "menu_selected", modifiers = ["bold"] }
"ui.menu.scroll" = { fg = "border", bg = "surface" }

"ui.debug.breakpoint" = "red"
"ui.debug.active" = "orange"

"diagnostic.error" = { underline = { color = "red", style = "curl" } }
"diagnostic.warning" = { underline = { color = "orange", style = "curl" } }
"diagnostic.info" = { underline = { color = "cyan", style = "curl" } }
"diagnostic.hint" = { underline = { color = "hint", style = "curl" } }
"diagnostic.unnecessary" = { fg = "comment" }
"diagnostic.deprecated" = { modifiers = ["crossed_out"] }

error = "red"
warning = "orange"
info = "cyan"
hint = "hint"

[palette]
background = "{{ background }}"
surface = "{{ dark_background }}"
cursorline = "{{ lighter_background }}"
foreground = "{{ foreground }}"
light_foreground = "{{ light_foreground }}"
bright_foreground = "{{ bright_foreground }}"
comment = "{{ comment }}"
cursor = "{{ bright_foreground }}"
accent = "{{ accent }}"
selection = "{{ selection }}"
guide = "{{ mix background muted 75% }}"
border = "{{ border }}"
hint = "{{ hint }}"
link = "{{ link }}"
red = "{{ red }}"
green = "{{ green }}"
yellow = "{{ yellow }}"
blue = "{{ blue }}"
magenta = "{{ magenta }}"
cyan = "{{ cyan }}"
orange = "{{ orange }}"
reference = "{{ mix background accent 16% }}"
menu_selected = "{{ mix dark_background accent 30% }}"
inlay = "{{ mix background lighter_background 60% }}"
nontext = "{{ mix background comment 55% }}"
heading1 = "{{ accent }}"
heading2 = "{{ mix accent foreground 13% }}"
heading3 = "{{ mix accent foreground 26% }}"
heading4 = "{{ mix accent foreground 39% }}"
heading5 = "{{ mix accent foreground 52% }}"
heading6 = "{{ mix accent foreground 65% }}"
