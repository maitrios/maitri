<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>name</key>
  <string>maitri</string>
  <key>settings</key>
  <array>
    <dict>
      <key>settings</key>
      <dict>
        <key>background</key>
        <string>{{ background }}</string>
        <key>foreground</key>
        <string>{{ foreground }}</string>
        <key>caret</key>
        <string>{{ bright_foreground }}</string>
        <key>invisibles</key>
        <string>{{ mix background comment 55% }}</string>
        <key>lineHighlight</key>
        <string>{{ lighter_background }}</string>
        <key>selection</key>
        <string>{{ selection }}</string>
        <key>selectionBorder</key>
        <string>{{ selection }}</string>
        <key>inactiveSelection</key>
        <string>{{ mix background selection 60% }}</string>
        <key>misspelling</key>
        <string>{{ red }}</string>
        <key>accent</key>
        <string>{{ accent }}</string>
        <key>gutter</key>
        <string>{{ background }}</string>
        <key>gutterForeground</key>
        <string>{{ comment }}</string>
        <key>findHighlight</key>
        <string>{{ orange }}</string>
        <key>findHighlightForeground</key>
        <string>{{ background }}</string>
        <key>highlight</key>
        <string>{{ green }}</string>
        <key>guide</key>
        <string>{{ mix background muted 75% }}</string>
        <key>activeGuide</key>
        <string>{{ border_focus }}</string>
        <key>stackGuide</key>
        <string>{{ mix background muted 75% }}</string>
        <key>bracketsForeground</key>
        <string>{{ accent }}</string>
        <key>bracketsOptions</key>
        <string>underline</string>
        <key>tagsForeground</key>
        <string>{{ accent }}</string>
        <key>tagsOptions</key>
        <string>stippled_underline</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Comment</string>
      <key>scope</key>
      <string>comment, punctuation.definition.comment, comment.block.documentation</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ comment }}</string>
        <key>fontStyle</key>
        <string>italic</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Comment tag</string>
      <key>scope</key>
      <string>comment storage.type, comment keyword.other, comment entity.name.type, comment variable.parameter</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ cyan }}</string>
        <key>fontStyle</key>
        <string>italic</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Text</string>
      <key>scope</key>
      <string>source, text, variable, variable.other.readwrite, meta.embedded</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ foreground }}</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Builtin variable</string>
      <key>scope</key>
      <string>variable.language, variable.language.this, variable.language.self, variable.language.super, variable.parameter.function.language.special.self.python, support.variable, support.variable.magic.python</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ blue }}</string>
        <key>fontStyle</key>
        <string>italic</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Parameter</string>
      <key>scope</key>
      <string>variable.parameter, entity.name.variable.parameter, meta.function.parameters variable.other, variable.parameter.function</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ orange }}</string>
        <key>fontStyle</key>
        <string>italic</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Property</string>
      <key>scope</key>
      <string>variable.other.property, variable.other.object.property, variable.other.member, meta.object-literal.key, support.type.property-name, meta.mapping.key string, entity.name.tag.yaml, keyword.key.toml, support.type.property-name.toml, keyword.other.definition.ini, entity.name.variable.field</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ orange }}</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Constant</string>
      <key>scope</key>
      <string>constant, constant.numeric, constant.language.boolean, variable.other.constant, variable.other.enummember, entity.name.constant, constant.other.symbol, keyword.other.unit, support.constant</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ blue }}</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Builtin constant</string>
      <key>scope</key>
      <string>constant.language, constant.language.null, constant.language.undefined, constant.language.nil, constant.language.none</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ blue }}</string>
        <key>fontStyle</key>
        <string>italic</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Character</string>
      <key>scope</key>
      <string>constant.character, constant.character.escape, constant.other.placeholder, constant.character.format.placeholder, constant.other.character-class.escape</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ magenta }}</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>String</string>
      <key>scope</key>
      <string>string, string.quoted, string.template, punctuation.definition.string, string.unquoted</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ yellow }}</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Regexp</string>
      <key>scope</key>
      <string>string.regexp, string.regexp punctuation.definition.string, constant.other.character-class.regexp, keyword.operator.quantifier.regexp, keyword.control.anchor.regexp</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ red }}</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Interpolation</string>
      <key>scope</key>
      <string>punctuation.definition.template-expression, punctuation.section.embedded, punctuation.section.interpolation, punctuation.definition.interpolation, punctuation.special</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ magenta }}</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Keyword</string>
      <key>scope</key>
      <string>keyword, keyword.control, keyword.operator, keyword.declaration, keyword.other, storage, storage.type, storage.modifier, keyword.control.import, keyword.control.directive, punctuation.definition.directive, punctuation.definition.preprocessor</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ magenta }}</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Operator</string>
      <key>scope</key>
      <string>keyword.operator.assignment, keyword.operator.arithmetic, keyword.operator.comparison, keyword.operator.logical, keyword.operator.ternary</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ magenta }}</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Type</string>
      <key>scope</key>
      <string>entity.name.type, entity.name.class, entity.name.struct, entity.name.enum, entity.name.union, entity.name.trait, entity.name.interface, entity.name.type.class, entity.name.type.interface, entity.name.type.enum, entity.other.inherited-class, support.type, support.class, storage.type.primitive, storage.type.built-in, storage.type.numeric, storage.type.string, storage.type.boolean, storage.type.byte, storage.type.rune, storage.type.uintptr, storage.type.error, support.type.primitive, support.type.builtin, entity.name.type.lifetime, storage.type.generic, storage.type.java, storage.type.object.array.java</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ cyan }}</string>
        <key>fontStyle</key>
        <string>italic</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Type parameter</string>
      <key>scope</key>
      <string>entity.name.type.parameter, entity.name.type.type-parameter</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ magenta }}</string>
        <key>fontStyle</key>
        <string>italic</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Module</string>
      <key>scope</key>
      <string>entity.name.namespace, entity.name.module, entity.name.package, entity.name.type.module, entity.name.type.namespace, support.module, support.other.namespace, storage.modifier.import, storage.modifier.package</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ cyan }}</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Function</string>
      <key>scope</key>
      <string>entity.name.function, meta.function-call.generic, variable.function, support.function.any-method, entity.name.function.macro, support.function.macro, entity.name.command, entity.name.function.target</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ green }}</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Builtin function</string>
      <key>scope</key>
      <string>support.function, support.function.builtin, support.function.magic, keyword.other.special-method</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ cyan }}</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Constructor</string>
      <key>scope</key>
      <string>entity.name.function.constructor</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ cyan }}</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Attribute</string>
      <key>scope</key>
      <string>entity.name.function.decorator, punctuation.decorator, storage.type.annotation, punctuation.definition.annotation, entity.name.type.attribute, entity.other.attribute-name</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ green }}</string>
        <key>fontStyle</key>
        <string>italic</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Label</string>
      <key>scope</key>
      <string>entity.name.label, punctuation.definition.label</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ blue }}</string>
        <key>fontStyle</key>
        <string>italic</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Tag</string>
      <key>scope</key>
      <string>entity.name.tag, support.class.component, entity.name.tag.html, entity.name.tag.css, entity.name.tag.reference</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ cyan }}</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>CSS class</string>
      <key>scope</key>
      <string>entity.other.attribute-name.class, entity.other.attribute-name.class.css</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ cyan }}</string>
        <key>fontStyle</key>
        <string>italic</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>CSS id</string>
      <key>scope</key>
      <string>entity.other.attribute-name.id, entity.other.attribute-name.id.css</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ blue }}</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>CSS pseudo</string>
      <key>scope</key>
      <string>entity.other.attribute-name.pseudo-class, entity.other.attribute-name.pseudo-element</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ green }}</string>
        <key>fontStyle</key>
        <string>italic</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Section</string>
      <key>scope</key>
      <string>entity.other.attribute-name.table.toml, support.type.property-name.table.toml, entity.name.section.group-title.ini</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ cyan }}</string>
        <key>fontStyle</key>
        <string>italic</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Punctuation</string>
      <key>scope</key>
      <string>punctuation, meta.brace, meta.bracket, punctuation.definition.tag, punctuation.separator, punctuation.terminator, punctuation.section, punctuation.definition.block, punctuation.definition.parameters, punctuation.definition.array, punctuation.definition.dictionary, punctuation.accessor, punctuation.separator.key-value</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ light_foreground }}</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Invalid</string>
      <key>scope</key>
      <string>invalid, invalid.illegal</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ red }}</string>
        <key>fontStyle</key>
        <string>underline</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Deprecated</string>
      <key>scope</key>
      <string>invalid.deprecated</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ orange }}</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Heading</string>
      <key>scope</key>
      <string>markup.heading, entity.name.section.markdown, punctuation.definition.heading.markdown, markup.heading.1, heading.1.markdown, markup.heading.1.markdown, heading.1.markdown entity.name.section.markdown, heading.1.markdown punctuation.definition.heading.markdown, markup.heading.1.markdown entity.name.section.markdown, markup.heading.1.markdown punctuation.definition.heading, markup.heading.setext.1.markdown</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ accent }}</string>
        <key>fontStyle</key>
        <string>bold</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Heading 2</string>
      <key>scope</key>
      <string>markup.heading.2, heading.2.markdown, markup.heading.2.markdown, heading.2.markdown entity.name.section.markdown, heading.2.markdown punctuation.definition.heading.markdown, markup.heading.2.markdown entity.name.section.markdown, markup.heading.2.markdown punctuation.definition.heading, markup.heading.setext.2.markdown</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ mix accent foreground 13% }}</string>
        <key>fontStyle</key>
        <string>bold</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Heading 3</string>
      <key>scope</key>
      <string>markup.heading.3, heading.3.markdown, markup.heading.3.markdown, heading.3.markdown entity.name.section.markdown, heading.3.markdown punctuation.definition.heading.markdown, markup.heading.3.markdown entity.name.section.markdown, markup.heading.3.markdown punctuation.definition.heading</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ mix accent foreground 26% }}</string>
        <key>fontStyle</key>
        <string>bold</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Heading 4</string>
      <key>scope</key>
      <string>markup.heading.4, heading.4.markdown, markup.heading.4.markdown, heading.4.markdown entity.name.section.markdown, heading.4.markdown punctuation.definition.heading.markdown, markup.heading.4.markdown entity.name.section.markdown, markup.heading.4.markdown punctuation.definition.heading</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ mix accent foreground 39% }}</string>
        <key>fontStyle</key>
        <string>bold</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Heading 5</string>
      <key>scope</key>
      <string>markup.heading.5, heading.5.markdown, markup.heading.5.markdown, heading.5.markdown entity.name.section.markdown, heading.5.markdown punctuation.definition.heading.markdown, markup.heading.5.markdown entity.name.section.markdown, markup.heading.5.markdown punctuation.definition.heading</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ mix accent foreground 52% }}</string>
        <key>fontStyle</key>
        <string>bold</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Heading 6</string>
      <key>scope</key>
      <string>markup.heading.6, heading.6.markdown, markup.heading.6.markdown, heading.6.markdown entity.name.section.markdown, heading.6.markdown punctuation.definition.heading.markdown, markup.heading.6.markdown entity.name.section.markdown, markup.heading.6.markdown punctuation.definition.heading</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ mix accent foreground 65% }}</string>
        <key>fontStyle</key>
        <string>bold</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Bold</string>
      <key>scope</key>
      <string>markup.bold, punctuation.definition.bold</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ bright_foreground }}</string>
        <key>fontStyle</key>
        <string>bold</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Italic</string>
      <key>scope</key>
      <string>markup.italic, punctuation.definition.italic</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ foreground }}</string>
        <key>fontStyle</key>
        <string>italic</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Bold italic</string>
      <key>scope</key>
      <string>markup.bold markup.italic, markup.italic markup.bold</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ bright_foreground }}</string>
        <key>fontStyle</key>
        <string>bold italic</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Strikethrough</string>
      <key>scope</key>
      <string>markup.strikethrough</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ comment }}</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Link text</string>
      <key>scope</key>
      <string>string.other.link, string.other.link.title, string.other.link.description, meta.link.inline.description, meta.link.reference.description, markup.underline.link.image, constant.other.reference.link</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ link }}</string>
        <key>fontStyle</key>
        <string>underline</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Link url</string>
      <key>scope</key>
      <string>markup.underline.link, meta.link.inline markup.underline.link, markup.underline.link.markdown</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ comment }}</string>
        <key>fontStyle</key>
        <string>underline</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Inline code</string>
      <key>scope</key>
      <string>markup.inline.raw, markup.raw.inline, markup.inline.raw.string.markdown</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ cyan }}</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Code block</string>
      <key>scope</key>
      <string>markup.raw.block, markup.fenced_code.block, markup.raw.code-fence</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ foreground }}</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Code fence</string>
      <key>scope</key>
      <string>punctuation.definition.markdown, punctuation.definition.raw.code-fence, fenced_code.block.language, punctuation.definition.raw</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ comment }}</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Quote</string>
      <key>scope</key>
      <string>markup.quote, punctuation.definition.quote.begin.markdown, punctuation.definition.blockquote</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ light_foreground }}</string>
        <key>fontStyle</key>
        <string>italic</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>List</string>
      <key>scope</key>
      <string>punctuation.definition.list.begin.markdown, punctuation.definition.list_item, markup.list.numbered.bullet, markup.list punctuation.definition.list</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ accent }}</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Rule</string>
      <key>scope</key>
      <string>meta.separator.markdown, punctuation.definition.thematic-break</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ comment }}</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Math</string>
      <key>scope</key>
      <string>markup.math, markup.raw.math</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ blue }}</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Inserted</string>
      <key>scope</key>
      <string>markup.inserted, punctuation.definition.inserted, meta.diff.header.to-file</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ green }}</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Deleted</string>
      <key>scope</key>
      <string>markup.deleted, punctuation.definition.deleted, meta.diff.header.from-file</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ red }}</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Changed</string>
      <key>scope</key>
      <string>markup.changed, punctuation.definition.changed</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ blue }}</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Diff header</string>
      <key>scope</key>
      <string>meta.diff.header, meta.diff.index</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ accent }}</string>
        <key>fontStyle</key>
        <string>bold</string>
      </dict>
    </dict>
    <dict>
      <key>name</key>
      <string>Diff range</string>
      <key>scope</key>
      <string>meta.diff.range</string>
      <key>settings</key>
      <dict>
        <key>foreground</key>
        <string>{{ cyan }}</string>
      </dict>
    </dict>
  </array>
</dict>
</plist>
