{
  "name": "maitri",
  "displayName": "maitri",
  "theme": {
    "background": {
      "default": "{{ background }}",
      "success": "{{ green }}",
      "notice": "{{ yellow }}",
      "warning": "{{ orange }}",
      "danger": "{{ red }}",
      "surprise": "{{ accent }}",
      "info": "{{ blue }}"
    },
    "foreground": {
      "default": "{{ foreground }}",
      "success": "{{ background }}",
      "notice": "{{ background }}",
      "warning": "{{ background }}",
      "danger": "{{ background }}",
      "surprise": "{{ background }}",
      "info": "{{ background }}"
    },
    "highlight": {
      "default": "{{ comment }}",
      "xxs": "rgba({{ foreground_rgb }}, 0.04)",
      "xs": "rgba({{ foreground_rgb }}, 0.08)",
      "sm": "{{ border }}",
      "md": "{{ border }}",
      "lg": "{{ border_focus }}",
      "xl": "{{ comment }}"
    },
    "styles": {
      "appHeader": {
        "background": { "default": "{{ dark_background }}" }
      },
      "sidebar": {
        "background": {
          "default": "{{ dark_background }}",
          "success": "{{ green }}",
          "notice": "{{ yellow }}",
          "warning": "{{ orange }}",
          "danger": "{{ red }}",
          "surprise": "{{ accent }}",
          "info": "{{ blue }}"
        }
      },
      "pane": {
        "background": { "default": "{{ background }}" }
      },
      "dialog": {
        "background": { "default": "{{ dark_background }}" }
      },
      "transparentOverlay": {
        "background": { "default": "rgba({{ darker_background_rgb }}, 0.8)" }
      },
      "link": {
        "foreground": { "default": "{{ link }}" }
      },
      "editor": {
        "background": {
          "default": "{{ background }}",
          "success": "{{ orange }}",
          "notice": "{{ yellow }}",
          "warning": "{{ orange }}",
          "danger": "{{ red }}",
          "surprise": "{{ blue }}",
          "info": "{{ cyan }}"
        }
      }
    }
  }
}
