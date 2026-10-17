[delta]
	syntax-theme = maitri
	minus-style = syntax "{{ mix background red 8% }}"
	minus-emph-style = "{{ foreground }}" "{{ mix background red 30% }}"
	plus-style = syntax "{{ mix background green 8% }}"
	plus-emph-style = "{{ foreground }}" "{{ mix background green 30% }}"
	map-styles = bold purple => syntax "{{ mix background magenta 8% }}", bold cyan => syntax "{{ mix background cyan 8% }}"
	line-numbers-minus-style = "{{ red }}"
	line-numbers-plus-style = "{{ green }}"
	line-numbers-zero-style = "{{ comment }}"
	line-numbers-left-style = "{{ border }}"
	line-numbers-right-style = "{{ border }}"
	file-style = bold "{{ accent }}"
	file-decoration-style = "{{ border }}" ul
	hunk-header-style = file line-number syntax
	hunk-header-decoration-style = "{{ border }}" box
	hunk-header-file-style = "{{ accent }}"
	hunk-header-line-number-style = "{{ cyan }}"
	commit-decoration-style = "{{ border }}" box
	blame-palette = "{{ background }} {{ lighter_background }}"
	whitespace-error-style = reverse "{{ red }}"
	inline-hint-style = "{{ comment }}"
