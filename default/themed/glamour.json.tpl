{
  "document": {
    "block_prefix": "\n",
    "block_suffix": "\n",
    "color": "{{ border }}",
    "margin": 2
  },
  "block_quote": {
    "indent": 1,
    "indent_token": "│ ",
    "italic": true
  },
  "paragraph": {
    "color": "{{ foreground }}"
  },
  "list": {
    "level_indent": 2,
    "color": "{{ foreground }}"
  },
  "heading": {
    "block_suffix": "\n",
    "color": "{{ accent }}",
    "bold": true
  },
  "h1": {
    "prefix": "# ",
    "color": "{{ accent }}",
    "bold": true
  },
  "h2": {
    "prefix": "## ",
    "color": "{{ mix accent foreground 13% }}",
    "bold": true
  },
  "h3": {
    "prefix": "### ",
    "color": "{{ mix accent foreground 26% }}",
    "bold": true
  },
  "h4": {
    "prefix": "#### ",
    "color": "{{ mix accent foreground 39% }}",
    "bold": true
  },
  "h5": {
    "prefix": "##### ",
    "color": "{{ mix accent foreground 52% }}",
    "bold": true
  },
  "h6": {
    "prefix": "###### ",
    "color": "{{ mix accent foreground 65% }}",
    "bold": true
  },
  "text": {},
  "strikethrough": {
    "color": "{{ comment }}",
    "crossed_out": true
  },
  "emph": {
    "italic": true
  },
  "strong": {
    "color": "{{ bright_foreground }}",
    "bold": true
  },
  "hr": {
    "color": "{{ border }}",
    "format": "\n--------\n"
  },
  "item": {
    "block_prefix": "• "
  },
  "enumeration": {
    "block_prefix": ". "
  },
  "task": {
    "ticked": "[✓] ",
    "unticked": "[ ] "
  },
  "link": {
    "color": "{{ link }}",
    "underline": true
  },
  "link_text": {
    "color": "{{ link }}",
    "bold": true
  },
  "image": {
    "color": "{{ link }}",
    "underline": true
  },
  "image_text": {
    "prefix": "Image: ",
    "suffix": " →",
    "color": "{{ comment }}"
  },
  "code": {
    "prefix": " ",
    "suffix": " ",
    "color": "{{ readable cyan lighter_background }}",
    "background_color": "{{ lighter_background }}"
  },
  "code_block": {
    "color": "{{ foreground }}",
    "margin": 2,
    "chroma": {
      "text": {
        "color": "{{ foreground }}"
      },
      "error": {
        "color": "{{ readable red darker_background muted 10% }}"
      },
      "comment": {
        "color": "{{ readable comment darker_background muted 10% }}",
        "italic": true
      },
      "comment_preproc": {
        "color": "{{ readable magenta darker_background muted 10% }}"
      },
      "keyword": {
        "color": "{{ readable magenta darker_background muted 10% }}"
      },
      "keyword_reserved": {
        "color": "{{ readable magenta darker_background muted 10% }}"
      },
      "keyword_namespace": {
        "color": "{{ readable magenta darker_background muted 10% }}"
      },
      "keyword_type": {
        "color": "{{ readable cyan darker_background muted 10% }}",
        "italic": true
      },
      "operator": {
        "color": "{{ readable magenta darker_background muted 10% }}"
      },
      "punctuation": {
        "color": "{{ readable light_foreground darker_background muted 10% }}"
      },
      "name": {
        "color": "{{ foreground }}"
      },
      "name_builtin": {
        "color": "{{ readable cyan darker_background muted 10% }}"
      },
      "name_tag": {
        "color": "{{ readable cyan darker_background muted 10% }}"
      },
      "name_attribute": {
        "color": "{{ readable green darker_background muted 10% }}",
        "italic": true
      },
      "name_class": {
        "color": "{{ readable cyan darker_background muted 10% }}",
        "italic": true
      },
      "name_constant": {
        "color": "{{ readable blue darker_background muted 10% }}"
      },
      "name_decorator": {
        "color": "{{ readable green darker_background muted 10% }}",
        "italic": true
      },
      "name_exception": {
        "color": "{{ readable cyan darker_background muted 10% }}",
        "italic": true
      },
      "name_function": {
        "color": "{{ readable green darker_background muted 10% }}"
      },
      "name_other": {
        "color": "{{ foreground }}"
      },
      "literal": {
        "color": "{{ readable blue darker_background muted 10% }}"
      },
      "literal_number": {
        "color": "{{ readable blue darker_background muted 10% }}"
      },
      "literal_date": {
        "color": "{{ readable blue darker_background muted 10% }}"
      },
      "literal_string": {
        "color": "{{ readable yellow darker_background muted 10% }}"
      },
      "literal_string_escape": {
        "color": "{{ readable magenta darker_background muted 10% }}"
      },
      "generic_deleted": {
        "color": "{{ readable red darker_background muted 10% }}"
      },
      "generic_emph": {
        "italic": true
      },
      "generic_inserted": {
        "color": "{{ readable green darker_background muted 10% }}"
      },
      "generic_strong": {
        "bold": true
      },
      "generic_subheading": {
        "color": "{{ readable blue darker_background muted 10% }}"
      },
      "background": {
        "background_color": "{{ background }}"
      }
    }
  },
  "table": {
    "color": "{{ foreground }}"
  },
  "definition_list": {
    "color": "{{ foreground }}"
  },
  "definition_term": {
    "bold": true
  },
  "definition_description": {
    "block_prefix": "\n🠶 "
  },
  "html_block": {
    "color": "{{ comment }}"
  },
  "html_span": {
    "color": "{{ comment }}"
  }
}
