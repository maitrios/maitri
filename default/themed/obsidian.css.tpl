/* maitri Theme for Obsidian */

.theme-dark, .theme-light {
  /* Surfaces */
  --background-primary: {{ background }};
  --background-primary-alt: {{ dark_background }};
  --background-secondary: {{ dark_background }};
  --background-secondary-alt: {{ darker_background }};
  --background-modifier-hover: color-mix(in srgb, {{ foreground }} 6%, transparent);
  --background-modifier-active-hover: {{ mix dark_background accent 16% }};
  --background-modifier-border: {{ border }};
  --background-modifier-border-hover: {{ border_focus }};
  --background-modifier-border-focus: {{ border_focus }};
  --background-modifier-form-field: {{ background }};
  --background-modifier-error: {{ red }};
  --background-modifier-error-hover: {{ red }};
  --background-modifier-success: {{ green }};
  --divider-color: {{ border }};
  --hr-color: {{ border }};
  --table-border-color: {{ border }};
  --tab-outline-color: {{ border }};
  --scrollbar-thumb-bg: {{ muted }};
  --scrollbar-active-thumb-bg: {{ border }};

  /* Text */
  --text-normal: {{ foreground }};
  --text-muted: {{ light_foreground }};
  --text-faint: {{ comment }};
  --text-on-accent: {{ background }};
  --text-on-accent-inverted: {{ background }};
  --text-error: {{ red }};
  --text-warning: {{ orange }};
  --text-success: {{ green }};
  --text-accent: {{ accent }};
  --text-accent-hover: {{ mix accent foreground 13% }};
  --text-selection: {{ selection }};
  --text-highlight-bg: {{ selection }};
  --caret-color: {{ bright_foreground }};
  --icon-color: {{ light_foreground }};
  --icon-color-hover: {{ foreground }};
  --icon-color-active: {{ accent }};
  --icon-color-focused: {{ accent }};

  /* Interactive */
  --interactive-normal: {{ dark_background }};
  --interactive-hover: {{ lighter_background }};
  --interactive-accent: {{ accent }};
  --interactive-accent-hover: {{ mix accent foreground 13% }};
  --nav-item-color-active: {{ bright_foreground }};
  --nav-item-background-active: {{ mix dark_background accent 30% }};
  --nav-item-color-selected: {{ bright_foreground }};
  --nav-item-background-selected: {{ mix dark_background accent 30% }};

  /* Headings */
  --h1-color: {{ accent }};
  --h2-color: {{ mix accent foreground 13% }};
  --h3-color: {{ mix accent foreground 26% }};
  --h4-color: {{ mix accent foreground 39% }};
  --h5-color: {{ mix accent foreground 52% }};
  --h6-color: {{ mix accent foreground 65% }};
  --h1-weight: 700;
  --h2-weight: 700;
  --h3-weight: 700;
  --h4-weight: 700;
  --h5-weight: 700;
  --h6-weight: 700;
  --text-title-h1: var(--h1-color);
  --text-title-h2: var(--h2-color);
  --text-title-h3: var(--h3-color);
  --text-title-h4: var(--h4-color);
  --text-title-h5: var(--h5-color);
  --text-title-h6: var(--h6-color);
  --inline-title-color: var(--h1-color);
  --inline-title-weight: 700;

  /* Links */
  --text-link: {{ link }};
  --link-color: {{ link }};
  --link-color-hover: {{ link }};
  --link-external-color: {{ link }};
  --link-external-color-hover: {{ link }};
  --link-unresolved-color: {{ link }};
  --link-decoration: underline;
  --link-external-decoration: underline;

  /* Markdown */
  --bold-color: {{ bright_foreground }};
  --blockquote-border-color: {{ border_focus }};
  --blockquote-color: {{ light_foreground }};
  --blockquote-font-style: italic;
  --list-marker-color: {{ accent }};
  --list-marker-color-hover: {{ accent }};
  --checkbox-color: {{ accent }};
  --checkbox-color-hover: {{ mix accent foreground 13% }};
  --checkbox-border-color: {{ comment }};
  --checkbox-border-color-hover: {{ accent }};
  --checkbox-marker-color: {{ background }};
  --checklist-done-color: {{ comment }};
  --tag-color: {{ accent }};
  --tag-color-hover: {{ accent }};
  --tag-background: {{ mix background accent 10% }};
  --tag-background-hover: {{ mix background accent 16% }};
  --tag-border-color: transparent;

  /* Code */
  --code-background: {{ dark_background }};
  --code-normal: {{ foreground }};
  --code-comment: {{ comment }};
  --code-function: {{ green }};
  --code-important: {{ red }};
  --code-keyword: {{ magenta }};
  --code-operator: {{ magenta }};
  --code-property: {{ orange }};
  --code-punctuation: {{ light_foreground }};
  --code-string: {{ yellow }};
  --code-tag: {{ cyan }};
  --code-value: {{ blue }};

  /* Graph */
  --graph-line: {{ border }};
  --graph-text: {{ foreground }};
  --graph-node: {{ accent }};
  --graph-node-focused: {{ link }};
  --graph-node-unresolved: {{ comment }};
  --graph-node-tag: {{ cyan }};
  --graph-node-attachment: {{ green }};
}

/* Headings */
.cm-header-1, .markdown-rendered h1 { color: var(--h1-color); font-weight: 700; }
.cm-header-2, .markdown-rendered h2 { color: var(--h2-color); font-weight: 700; }
.cm-header-3, .markdown-rendered h3 { color: var(--h3-color); font-weight: 700; }
.cm-header-4, .markdown-rendered h4 { color: var(--h4-color); font-weight: 700; }
.cm-header-5, .markdown-rendered h5 { color: var(--h5-color); font-weight: 700; }
.cm-header-6, .markdown-rendered h6 { color: var(--h6-color); font-weight: 700; }

/* Inline code */
.markdown-rendered :not(pre) > code,
.cm-s-obsidian span.cm-inline-code {
  color: {{ cyan }};
}

/* Syntax in the editor */
.cm-s-obsidian span.cm-comment { color: {{ comment }}; font-style: italic; }
.cm-s-obsidian span.cm-keyword { color: {{ magenta }}; }
.cm-s-obsidian span.cm-operator { color: {{ magenta }}; }
.cm-s-obsidian span.cm-string,
.cm-s-obsidian span.cm-string-2 { color: {{ yellow }}; }
.cm-s-obsidian span.cm-number,
.cm-s-obsidian span.cm-atom { color: {{ blue }}; }
.cm-s-obsidian span.cm-def { color: {{ green }}; }
.cm-s-obsidian span.cm-variable { color: {{ foreground }}; }
.cm-s-obsidian span.cm-variable-2,
.cm-s-obsidian span.cm-property { color: {{ orange }}; }
.cm-s-obsidian span.cm-variable-3,
.cm-s-obsidian span.cm-type { color: {{ cyan }}; font-style: italic; }
.cm-s-obsidian span.cm-builtin { color: {{ cyan }}; }
.cm-s-obsidian span.cm-tag { color: {{ cyan }}; }
.cm-s-obsidian span.cm-attribute { color: {{ green }}; font-style: italic; }
.cm-s-obsidian span.cm-meta,
.cm-s-obsidian span.cm-qualifier { color: {{ magenta }}; }
.cm-s-obsidian span.cm-bracket { color: {{ light_foreground }}; }

/* Syntax in reading view */
.markdown-rendered .token.comment,
.markdown-rendered .token.prolog,
.markdown-rendered .token.doctype,
.markdown-rendered .token.cdata { color: {{ comment }}; font-style: italic; }
.markdown-rendered .token.class-name,
.markdown-rendered .token.builtin { color: {{ cyan }}; font-style: italic; }
.markdown-rendered .token.attr-name { color: {{ green }}; font-style: italic; }
.markdown-rendered .token.parameter { color: {{ orange }}; font-style: italic; }
.markdown-rendered .token.regex { color: {{ red }}; }

/* Links */
.markdown-rendered a,
.cm-s-obsidian span.cm-hmd-internal-link,
.cm-s-obsidian span.cm-link,
.cm-s-obsidian span.cm-url {
  color: var(--link-color);
  text-decoration: underline;
}

/* Blockquotes */
.markdown-rendered blockquote {
  border-left-color: var(--blockquote-border-color);
}

/* Active elements */
.workspace-leaf.mod-active .workspace-leaf-header-title,
.nav-file-title.is-active,
.search-result-file-title {
  color: var(--interactive-accent);
}
