{
  "name": "maitri",
  "author": "maitri",
  "variables": {},
  "globals": {
    "background": "{{ background }}",
    "foreground": "{{ foreground }}",
    "caret": "{{ bright_foreground }}",
    "line_highlight": "{{ lighter_background }}",
    "selection": "{{ selection }}",
    "selection_foreground": "{{ bright_foreground }}",
    "gutter": "{{ background }}",
    "gutter_foreground": "{{ dark_foreground }}",
    "accent": "{{ accent }}"
  },
  "rules": [
    { "scope": "comment", "foreground": "{{ dark_foreground }}", "font_style": "italic" },
    { "scope": "string", "foreground": "{{ green }}" },
    { "scope": "constant.numeric", "foreground": "{{ yellow }}" },
    { "scope": "constant.language", "foreground": "{{ yellow }}" },
    { "scope": "keyword", "foreground": "{{ magenta }}" },
    { "scope": "storage.type", "foreground": "{{ blue }}" },
    { "scope": "entity.name.function", "foreground": "{{ blue }}" },
    { "scope": "variable", "foreground": "{{ foreground }}" },
    { "scope": "entity.name.tag", "foreground": "{{ red }}" },
    { "scope": "support.type, support.class", "foreground": "{{ cyan }}" }
  ]
}
