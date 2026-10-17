@define-color foreground {{ foreground }};
@define-color background {{ background }};
@define-color accent {{ accent }};
@define-color border {{ border }};
@define-color border_focus {{ border_focus }};
@define-color comment {{ comment }};
@define-color card_bg {{ lighter_background }};
@define-color card_hover {{ mix lighter_background foreground 6% }};
@define-color selection {{ selection }};
@define-color text_dark {{ background }};
@define-color accent_hover {{ mix accent foreground 20% }};
@define-color selected_tab {{ accent }};
@define-color text {{ foreground }};

* {
  all: unset;
  font-family: JetBrains Mono NF;
  color: @foreground;
  font-weight: bold;
  font-size: 16px;
}

.window {
  background: alpha(@background, 0.95);
  border: solid 2px @accent;
  margin: 4px;
  padding: 18px;
}

tabs {
    padding: 0.5rem 1rem;
}

tabs > tab {
    margin-right: 1rem;
}

.tab-label {
    color: @text;
    transition: all 0.2s ease;
}

tabs > tab:checked > .tab-label, tabs > tab:active > .tab-label {
    text-decoration: underline currentColor;
    color: @selected_tab;
}

tabs > tab:focus > .tab-label {
    color: @foreground;
}

.page {
    padding: 1rem;
}

.image-label {
    font-size: 12px;
    padding: 0.25rem;
}

flowboxchild > .card, button > .card {
    transition: all 0.2s ease;
    border: solid 2px @border;
    border-radius: 5px;
    background-color: @card_bg;
    padding: 5px;
}

flowboxchild:hover > .card, button:hover > .card {
    border-color: @border_focus;
    background-color: @card_hover;
}

flowboxchild:active > .card, flowboxchild:selected > .card, button:active > .card, button:selected > .card {
    border-color: @accent;
    background-color: @selection;
}

flowboxchild:focus > .card, button:focus > .card {
    border-color: @accent;
}

.image {
    border-radius: 5px;
}

.region-button {
    padding: 0.5rem 1rem;
    border-radius: 5px;
    background-color: @accent;
    color: @text_dark;
    transition: all 0.2s ease;
}

.region-button > label {
    color: @text_dark;
}

.region-button:not(:disabled):hover {
    background-color: @accent_hover;
    color: @text_dark;
}

.region-button:not(:disabled):focus {
    outline: solid 2px @border_focus;
    outline-offset: 2px;
}

.region-button:disabled {
    background-color: @card_bg;
    border: solid 1px @border;
    color: @comment;
}

.region-button:disabled > label {
    color: @comment;
}
