gui:
  theme:
    activeBorderColor:
      - "{{ border_focus }}"
      - bold
    inactiveBorderColor:
      - "{{ border }}"
    searchingActiveBorderColor:
      - "{{ yellow }}"
      - bold
    optionsTextColor:
      - "{{ accent }}"
    selectedLineBgColor:
      - "{{ lighter_background }}"
    inactiveViewSelectedLineBgColor:
      - "{{ mix background lighter_background 50% }}"
    cherryPickedCommitFgColor:
      - "{{ background }}"
    cherryPickedCommitBgColor:
      - "{{ cyan }}"
    markedBaseCommitFgColor:
      - "{{ background }}"
    markedBaseCommitBgColor:
      - "{{ yellow }}"
    unstagedChangesColor:
      - "{{ red }}"
    defaultFgColor:
      - "{{ foreground }}"
