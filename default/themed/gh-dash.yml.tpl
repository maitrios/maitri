theme:
  colors:
    text:
      primary: "{{ foreground }}"
      secondary: "{{ accent }}"
      inverted: "{{ background }}"
      faint: "{{ comment }}"
      warning: "{{ orange }}"
      success: "{{ green }}"
      error: "{{ red }}"
      actor: "{{ accent }}"
    background:
      selected: "{{ lighter_background }}"
    border:
      primary: "{{ border_focus }}"
      secondary: "{{ border }}"
      faint: "{{ mix background lighter_background 50% }}"
    icon:
      newcontributor: "{{ green }}"
      contributor: "{{ blue }}"
      collaborator: "{{ cyan }}"
      member: "{{ magenta }}"
      owner: "{{ yellow }}"
      unknownrole: "{{ comment }}"
