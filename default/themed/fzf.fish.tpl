if set -q MAITRI_FZF_COLORS
    set -gx FZF_DEFAULT_OPTS (string replace -- "$MAITRI_FZF_COLORS" "" "$FZF_DEFAULT_OPTS" | string trim)
end
set -gx MAITRI_FZF_COLORS "--color=fg:{{ foreground }},bg:-1,hl:{{ accent }},fg+:{{ bright_foreground }},bg+:{{ lighter_background }},hl+:{{ accent }},gutter:{{ background }},selected-fg:{{ foreground }},selected-bg:{{ selection }},selected-hl:{{ mix accent foreground 39% }},query:{{ foreground }},disabled:{{ comment }},ghost:{{ comment }},info:{{ comment }},prompt:{{ accent }},pointer:{{ accent }},marker:{{ green }},spinner:{{ accent }},header:{{ light_foreground }},border:{{ border }},separator:{{ border }},scrollbar:{{ border }},label:{{ accent }},preview-border:{{ border }},preview-label:{{ accent }}"
set -gx FZF_DEFAULT_OPTS (string trim -- "$FZF_DEFAULT_OPTS $MAITRI_FZF_COLORS")
