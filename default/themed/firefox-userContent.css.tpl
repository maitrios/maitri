/* maitri Theme for Firefox and Zen pages */

@-moz-document url("about:home"), url("about:newtab"), url("about:privatebrowsing") {
  :root {
    color-scheme: {{ mode }} !important;
    --newtab-background-color: {{ background }} !important;
    --newtab-background-color-secondary: {{ dark_background }} !important;
    --newtab-text-primary-color: {{ foreground }} !important;
    --newtab-text-secondary-color: {{ comment }} !important;
    --newtab-primary-action-background: {{ accent }} !important;
    --newtab-primary-element-text-color: {{ background }} !important;
    --newtab-element-hover-color: {{ mix background foreground 6% }} !important;
    --newtab-element-active-color: {{ mix background foreground 12% }} !important;
    --newtab-border-color: {{ border }} !important;
    --newtab-wordmark-color: {{ foreground }} !important;
    --newtab-textbox-background-color: {{ dark_background }} !important;
    --newtab-textbox-focus-color: {{ border_focus }} !important;
    --color-accent-primary: {{ accent }} !important;
    --focus-outline-color: {{ accent }} !important;
    --link-color: {{ link }} !important;
  }

  body {
    background-color: {{ background }} !important;
    color: {{ foreground }} !important;
  }
}

/* Only the light and dark reader themes follow maitri; sepia, gray, contrast
   and custom keep whatever the reader picked. */
@-moz-document url-prefix("about:reader") {
  body:is(.light, .dark) {
    color-scheme: {{ mode }} !important;
    --main-background: {{ background }} !important;
    --main-foreground: {{ foreground }} !important;
    --primary-color: {{ accent }} !important;
    --outline-focus-color: {{ accent }} !important;
    --link-foreground: {{ link }} !important;
    --visited-link-foreground: {{ mix link foreground 35% }} !important;
    --text-selected-background: {{ selection }} !important;
    --text-selected-foreground: {{ foreground }} !important;
    --link-selected-background: {{ selection }} !important;
    --link-selected-foreground: {{ foreground }} !important;
    --selected-background: {{ selection }} !important;
    --icon-fill: {{ light_foreground }} !important;
    --toolbar-border: {{ border }} !important;
    --toolbar-button-background-hover: {{ mix background foreground 10% }} !important;
    --toolbar-button-background-active: {{ mix background foreground 16% }} !important;
    --popup-background: {{ dark_background }} !important;
    --popup-foreground: {{ foreground }} !important;
    --popup-border: {{ border }} !important;
    --popup-line: {{ border }} !important;
    --tooltip-background: {{ dark_background }} !important;
    --tooltip-foreground: {{ foreground }} !important;
    background-color: {{ background }} !important;
    color: {{ foreground }} !important;
  }

  body:is(.light, .dark) :is(.header > h1, .moz-reader-content h1) {
    color: {{ accent }} !important;
    font-weight: bold !important;
  }

  body:is(.light, .dark) .moz-reader-content h2 {
    color: {{ mix accent foreground 13% }} !important;
    font-weight: bold !important;
  }

  body:is(.light, .dark) .moz-reader-content h3 {
    color: {{ mix accent foreground 26% }} !important;
    font-weight: bold !important;
  }

  body:is(.light, .dark) .moz-reader-content h4 {
    color: {{ mix accent foreground 39% }} !important;
    font-weight: bold !important;
  }

  body:is(.light, .dark) .moz-reader-content h5 {
    color: {{ mix accent foreground 52% }} !important;
    font-weight: bold !important;
  }

  body:is(.light, .dark) .moz-reader-content h6 {
    color: {{ mix accent foreground 65% }} !important;
    font-weight: bold !important;
  }

  body:is(.light, .dark) .moz-reader-content a:link {
    color: {{ link }} !important;
  }

  body:is(.light, .dark) .moz-reader-content a:visited {
    color: {{ mix link foreground 35% }} !important;
  }

  body:is(.light, .dark) :is(.credits, .meta-data, .reader-estimated-time, .domain, figcaption, .wp-caption-text) {
    color: {{ comment }} !important;
  }

  body:is(.light, .dark) .moz-reader-content code {
    color: {{ cyan }} !important;
  }

  body:is(.light, .dark) .moz-reader-content pre {
    background-color: {{ dark_background }} !important;
    border: 1px solid {{ border }} !important;
  }

  body:is(.light, .dark) .moz-reader-content pre code {
    color: {{ foreground }} !important;
  }

  body:is(.light, .dark) .moz-reader-content blockquote {
    color: {{ light_foreground }} !important;
    font-style: italic !important;
    border-inline-start-color: {{ border }} !important;
  }

  body:is(.light, .dark) .moz-reader-content hr {
    border-color: {{ border }} !important;
  }
}

@-moz-document url-prefix("view-source:") {
  :root {
    color-scheme: {{ mode }} !important;
    background-color: {{ background }} !important;
  }

  #viewsource {
    background-color: {{ background }} !important;
    color: {{ light_foreground }} !important;
  }

  #viewsource span[id]::before {
    color: {{ comment }} !important;
  }

  #viewsource :is(.start-tag, .end-tag) {
    color: {{ cyan }} !important;
  }

  #viewsource .attribute-name {
    color: {{ green }} !important;
    font-style: italic !important;
  }

  #viewsource .attribute-value {
    color: {{ yellow }} !important;
  }

  #viewsource .comment {
    color: {{ comment }} !important;
    font-style: italic !important;
  }

  #viewsource :is(.doctype, .markupdeclaration, .pi) {
    color: {{ magenta }} !important;
  }

  #viewsource :is(.entity, .cdata) {
    color: {{ magenta }} !important;
  }

  #viewsource .text {
    color: {{ foreground }} !important;
  }

  #viewsource .error {
    color: {{ red }} !important;
    background-color: transparent !important;
    text-decoration-color: {{ red }} !important;
  }

  ::selection {
    background-color: {{ selection }} !important;
    color: {{ foreground }} !important;
  }
}
