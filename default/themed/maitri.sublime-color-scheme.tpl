{
  "name": "maitri",
  "author": "maitri",
  "variables": {},
  "globals": {
    "background": "{{ background }}",
    "foreground": "{{ foreground }}",
    "caret": "{{ bright_foreground }}",
    "invisibles": "{{ mix background comment 55% }}",
    "line_highlight": "{{ lighter_background }}",
    "selection": "{{ selection }}",
    "inactive_selection": "{{ mix background selection 60% }}",
    "selection_corner_style": "round",
    "misspelling": "{{ red }}",
    "fold_marker": "{{ comment }}",
    "accent": "{{ accent }}",
    "gutter": "{{ background }}",
    "gutter_foreground": "{{ comment }}",
    "gutter_foreground_highlight": "{{ accent }}",
    "line_diff_width": "2",
    "line_diff_added": "{{ green }}",
    "line_diff_modified": "{{ blue }}",
    "line_diff_deleted": "{{ red }}",
    "highlight": "{{ green }}",
    "find_highlight": "{{ orange }}",
    "find_highlight_foreground": "{{ background }}",
    "scroll_highlight": "{{ mix background green 32% }}",
    "scroll_selected_highlight": "{{ orange }}",
    "rulers": "{{ mix background muted 75% }}",
    "guide": "{{ mix background muted 75% }}",
    "active_guide": "{{ border_focus }}",
    "stack_guide": "{{ mix background muted 75% }}",
    "minimap_border": "{{ border }}",
    "brackets_options": "underline",
    "brackets_foreground": "{{ accent }}",
    "tags_options": "stippled_underline",
    "tags_foreground": "{{ accent }}"
  },
  "rules": [
    {
      "name": "Comment",
      "scope": "comment, punctuation.definition.comment, comment.block.documentation",
      "foreground": "{{ comment }}",
      "font_style": "italic"
    },
    {
      "name": "Comment tag",
      "scope": "comment storage.type, comment keyword.other, comment entity.name.type, comment variable.parameter",
      "foreground": "{{ cyan }}",
      "font_style": "italic"
    },
    {
      "name": "Text",
      "scope": "source, text, variable, variable.other.readwrite, meta.embedded",
      "foreground": "{{ foreground }}"
    },
    {
      "name": "Builtin variable",
      "scope": "variable.language, variable.language.this, variable.language.self, variable.language.super, variable.parameter.function.language.special.self.python, support.variable, support.variable.magic.python",
      "foreground": "{{ blue }}",
      "font_style": "italic"
    },
    {
      "name": "Parameter",
      "scope": "variable.parameter, entity.name.variable.parameter, meta.function.parameters variable.other, variable.parameter.function",
      "foreground": "{{ orange }}",
      "font_style": "italic"
    },
    {
      "name": "Property",
      "scope": "variable.other.property, variable.other.object.property, variable.other.member, meta.object-literal.key, support.type.property-name, meta.mapping.key string, entity.name.tag.yaml, keyword.key.toml, support.type.property-name.toml, keyword.other.definition.ini, entity.name.variable.field",
      "foreground": "{{ orange }}"
    },
    {
      "name": "Constant",
      "scope": "constant, constant.numeric, constant.language.boolean, variable.other.constant, variable.other.enummember, entity.name.constant, constant.other.symbol, keyword.other.unit, support.constant",
      "foreground": "{{ blue }}"
    },
    {
      "name": "Builtin constant",
      "scope": "constant.language, constant.language.null, constant.language.undefined, constant.language.nil, constant.language.none",
      "foreground": "{{ blue }}",
      "font_style": "italic"
    },
    {
      "name": "Character",
      "scope": "constant.character, constant.character.escape, constant.other.placeholder, constant.character.format.placeholder, constant.other.character-class.escape",
      "foreground": "{{ magenta }}"
    },
    {
      "name": "String",
      "scope": "string, string.quoted, string.template, punctuation.definition.string, string.unquoted",
      "foreground": "{{ yellow }}"
    },
    {
      "name": "Regexp",
      "scope": "string.regexp, string.regexp punctuation.definition.string, constant.other.character-class.regexp, keyword.operator.quantifier.regexp, keyword.control.anchor.regexp",
      "foreground": "{{ red }}"
    },
    {
      "name": "Interpolation",
      "scope": "punctuation.definition.template-expression, punctuation.section.embedded, punctuation.section.interpolation, punctuation.definition.interpolation, punctuation.special",
      "foreground": "{{ magenta }}"
    },
    {
      "name": "Keyword",
      "scope": "keyword, keyword.control, keyword.operator, keyword.declaration, keyword.other, storage, storage.type, storage.modifier, keyword.control.import, keyword.control.directive, punctuation.definition.directive, punctuation.definition.preprocessor",
      "foreground": "{{ magenta }}"
    },
    {
      "name": "Operator",
      "scope": "keyword.operator.assignment, keyword.operator.arithmetic, keyword.operator.comparison, keyword.operator.logical, keyword.operator.ternary",
      "foreground": "{{ magenta }}"
    },
    {
      "name": "Type",
      "scope": "entity.name.type, entity.name.class, entity.name.struct, entity.name.enum, entity.name.union, entity.name.trait, entity.name.interface, entity.name.type.class, entity.name.type.interface, entity.name.type.enum, entity.other.inherited-class, support.type, support.class, storage.type.primitive, storage.type.built-in, storage.type.numeric, storage.type.string, storage.type.boolean, storage.type.byte, storage.type.rune, storage.type.uintptr, storage.type.error, support.type.primitive, support.type.builtin, entity.name.type.lifetime, storage.type.generic, storage.type.java, storage.type.object.array.java",
      "foreground": "{{ cyan }}",
      "font_style": "italic"
    },
    {
      "name": "Type parameter",
      "scope": "entity.name.type.parameter, entity.name.type.type-parameter",
      "foreground": "{{ magenta }}",
      "font_style": "italic"
    },
    {
      "name": "Module",
      "scope": "entity.name.namespace, entity.name.module, entity.name.package, entity.name.type.module, entity.name.type.namespace, support.module, support.other.namespace, storage.modifier.import, storage.modifier.package",
      "foreground": "{{ cyan }}"
    },
    {
      "name": "Function",
      "scope": "entity.name.function, meta.function-call.generic, variable.function, support.function.any-method, entity.name.function.macro, support.function.macro, entity.name.command, entity.name.function.target",
      "foreground": "{{ green }}"
    },
    {
      "name": "Builtin function",
      "scope": "support.function, support.function.builtin, support.function.magic, keyword.other.special-method",
      "foreground": "{{ cyan }}"
    },
    {
      "name": "Constructor",
      "scope": "entity.name.function.constructor",
      "foreground": "{{ cyan }}"
    },
    {
      "name": "Attribute",
      "scope": "entity.name.function.decorator, punctuation.decorator, storage.type.annotation, punctuation.definition.annotation, entity.name.type.attribute, entity.other.attribute-name",
      "foreground": "{{ green }}",
      "font_style": "italic"
    },
    {
      "name": "Label",
      "scope": "entity.name.label, punctuation.definition.label",
      "foreground": "{{ blue }}",
      "font_style": "italic"
    },
    {
      "name": "Tag",
      "scope": "entity.name.tag, support.class.component, entity.name.tag.html, entity.name.tag.css, entity.name.tag.reference",
      "foreground": "{{ cyan }}"
    },
    {
      "name": "CSS class",
      "scope": "entity.other.attribute-name.class, entity.other.attribute-name.class.css",
      "foreground": "{{ cyan }}",
      "font_style": "italic"
    },
    {
      "name": "CSS id",
      "scope": "entity.other.attribute-name.id, entity.other.attribute-name.id.css",
      "foreground": "{{ blue }}"
    },
    {
      "name": "CSS pseudo",
      "scope": "entity.other.attribute-name.pseudo-class, entity.other.attribute-name.pseudo-element",
      "foreground": "{{ green }}",
      "font_style": "italic"
    },
    {
      "name": "Section",
      "scope": "entity.other.attribute-name.table.toml, support.type.property-name.table.toml, entity.name.section.group-title.ini",
      "foreground": "{{ cyan }}",
      "font_style": "italic"
    },
    {
      "name": "Punctuation",
      "scope": "punctuation, meta.brace, meta.bracket, punctuation.definition.tag, punctuation.separator, punctuation.terminator, punctuation.section, punctuation.definition.block, punctuation.definition.parameters, punctuation.definition.array, punctuation.definition.dictionary, punctuation.accessor, punctuation.separator.key-value",
      "foreground": "{{ light_foreground }}"
    },
    {
      "name": "Invalid",
      "scope": "invalid, invalid.illegal",
      "foreground": "{{ red }}",
      "font_style": "underline"
    },
    {
      "name": "Deprecated",
      "scope": "invalid.deprecated",
      "foreground": "{{ orange }}"
    },
    {
      "name": "Heading",
      "scope": "markup.heading, entity.name.section.markdown, punctuation.definition.heading.markdown, markup.heading.1, heading.1.markdown, markup.heading.1.markdown, heading.1.markdown entity.name.section.markdown, heading.1.markdown punctuation.definition.heading.markdown, markup.heading.1.markdown entity.name.section.markdown, markup.heading.1.markdown punctuation.definition.heading, markup.heading.setext.1.markdown",
      "foreground": "{{ accent }}",
      "font_style": "bold"
    },
    {
      "name": "Heading 2",
      "scope": "markup.heading.2, heading.2.markdown, markup.heading.2.markdown, heading.2.markdown entity.name.section.markdown, heading.2.markdown punctuation.definition.heading.markdown, markup.heading.2.markdown entity.name.section.markdown, markup.heading.2.markdown punctuation.definition.heading, markup.heading.setext.2.markdown",
      "foreground": "{{ mix accent foreground 13% }}",
      "font_style": "bold"
    },
    {
      "name": "Heading 3",
      "scope": "markup.heading.3, heading.3.markdown, markup.heading.3.markdown, heading.3.markdown entity.name.section.markdown, heading.3.markdown punctuation.definition.heading.markdown, markup.heading.3.markdown entity.name.section.markdown, markup.heading.3.markdown punctuation.definition.heading",
      "foreground": "{{ mix accent foreground 26% }}",
      "font_style": "bold"
    },
    {
      "name": "Heading 4",
      "scope": "markup.heading.4, heading.4.markdown, markup.heading.4.markdown, heading.4.markdown entity.name.section.markdown, heading.4.markdown punctuation.definition.heading.markdown, markup.heading.4.markdown entity.name.section.markdown, markup.heading.4.markdown punctuation.definition.heading",
      "foreground": "{{ mix accent foreground 39% }}",
      "font_style": "bold"
    },
    {
      "name": "Heading 5",
      "scope": "markup.heading.5, heading.5.markdown, markup.heading.5.markdown, heading.5.markdown entity.name.section.markdown, heading.5.markdown punctuation.definition.heading.markdown, markup.heading.5.markdown entity.name.section.markdown, markup.heading.5.markdown punctuation.definition.heading",
      "foreground": "{{ mix accent foreground 52% }}",
      "font_style": "bold"
    },
    {
      "name": "Heading 6",
      "scope": "markup.heading.6, heading.6.markdown, markup.heading.6.markdown, heading.6.markdown entity.name.section.markdown, heading.6.markdown punctuation.definition.heading.markdown, markup.heading.6.markdown entity.name.section.markdown, markup.heading.6.markdown punctuation.definition.heading",
      "foreground": "{{ mix accent foreground 65% }}",
      "font_style": "bold"
    },
    {
      "name": "Bold",
      "scope": "markup.bold, punctuation.definition.bold",
      "foreground": "{{ bright_foreground }}",
      "font_style": "bold"
    },
    {
      "name": "Italic",
      "scope": "markup.italic, punctuation.definition.italic",
      "foreground": "{{ foreground }}",
      "font_style": "italic"
    },
    {
      "name": "Bold italic",
      "scope": "markup.bold markup.italic, markup.italic markup.bold",
      "foreground": "{{ bright_foreground }}",
      "font_style": "bold italic"
    },
    {
      "name": "Strikethrough",
      "scope": "markup.strikethrough",
      "foreground": "{{ comment }}"
    },
    {
      "name": "Link text",
      "scope": "string.other.link, string.other.link.title, string.other.link.description, meta.link.inline.description, meta.link.reference.description, markup.underline.link.image, constant.other.reference.link",
      "foreground": "{{ link }}",
      "font_style": "underline"
    },
    {
      "name": "Link url",
      "scope": "markup.underline.link, meta.link.inline markup.underline.link, markup.underline.link.markdown",
      "foreground": "{{ comment }}",
      "font_style": "underline"
    },
    {
      "name": "Inline code",
      "scope": "markup.inline.raw, markup.raw.inline, markup.inline.raw.string.markdown",
      "foreground": "{{ cyan }}"
    },
    {
      "name": "Code block",
      "scope": "markup.raw.block, markup.fenced_code.block, markup.raw.code-fence",
      "foreground": "{{ foreground }}"
    },
    {
      "name": "Code fence",
      "scope": "punctuation.definition.markdown, punctuation.definition.raw.code-fence, fenced_code.block.language, punctuation.definition.raw",
      "foreground": "{{ comment }}"
    },
    {
      "name": "Quote",
      "scope": "markup.quote, punctuation.definition.quote.begin.markdown, punctuation.definition.blockquote",
      "foreground": "{{ light_foreground }}",
      "font_style": "italic"
    },
    {
      "name": "List",
      "scope": "punctuation.definition.list.begin.markdown, punctuation.definition.list_item, markup.list.numbered.bullet, markup.list punctuation.definition.list",
      "foreground": "{{ accent }}"
    },
    {
      "name": "Rule",
      "scope": "meta.separator.markdown, punctuation.definition.thematic-break",
      "foreground": "{{ comment }}"
    },
    {
      "name": "Math",
      "scope": "markup.math, markup.raw.math",
      "foreground": "{{ blue }}"
    },
    {
      "name": "Inserted",
      "scope": "markup.inserted, punctuation.definition.inserted, meta.diff.header.to-file",
      "foreground": "{{ green }}"
    },
    {
      "name": "Deleted",
      "scope": "markup.deleted, punctuation.definition.deleted, meta.diff.header.from-file",
      "foreground": "{{ red }}"
    },
    {
      "name": "Changed",
      "scope": "markup.changed, punctuation.definition.changed",
      "foreground": "{{ blue }}"
    },
    {
      "name": "Diff header",
      "scope": "meta.diff.header, meta.diff.index",
      "foreground": "{{ accent }}",
      "font_style": "bold"
    },
    {
      "name": "Diff range",
      "scope": "meta.diff.range",
      "foreground": "{{ cyan }}"
    }
  ]
}
