#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

require_command python3

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

themes=()
for theme_dir in "$ROOT"/themes/*/; do
  theme=$(basename "$theme_dir")
  next_theme="$test_tmp/$theme/.local/state/maitri/current/next-theme"
  mkdir -p "$next_theme"
  cp "$theme_dir/colors.toml" "$next_theme/colors.toml"

  HOME="$test_tmp/$theme" MAITRI_PATH="$ROOT" PATH="$ROOT/bin:$PATH" bash "$ROOT/bin/maitri-theme-set-templates"
  MAITRI_PATH="$ROOT" PATH="$ROOT/bin:$PATH" maitri-theme-color --file "$next_theme/colors.toml" --all >"$test_tmp/$theme/palette.tsv"

  for file in helix.toml vscode-theme.json maitri.sublime-color-scheme obsidian.css; do
    [[ -f $next_theme/$file ]] || fail "$theme renders $file"
    ! grep -q '{{' "$next_theme/$file" || fail "$theme leaves no placeholders in $file" "$(grep -n '{{' "$next_theme/$file")"
  done
  themes+=("$theme")
done

(( ${#themes[@]} == 6 )) || fail "six themes are rendered" "${themes[*]}"

python3 - "$test_tmp" "${themes[@]}" <<'PY'
import json, re, sys, tomllib

root, themes = sys.argv[1], sys.argv[2:]
TEXT, LINE = 4.5, 3.0
failed = False


def rgb(color):
    color = color.lstrip("#")
    return tuple(int(color[i:i + 2], 16) for i in (0, 2, 4))


def alpha(color):
    color = color.lstrip("#")
    return int(color[6:8], 16) / 255 if len(color) == 8 else 1.0


def over(color, base):
    a = alpha(color)
    top, bottom = rgb(color), rgb(base)
    return "#%02x%02x%02x" % tuple(round(t * a + b * (1 - a)) for t, b in zip(top, bottom))


def luminance(color):
    def channel(value):
        value /= 255
        return value / 12.92 if value <= 0.03928 else ((value + 0.055) / 1.055) ** 2.4
    r, g, b = rgb(color)
    return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)


def contrast(fg, bg):
    fg = over(fg, bg)
    a, b = sorted((luminance(fg), luminance(bg)), reverse=True)
    return (a + 0.05) / (b + 0.05)


def mix(a, b, amount):
    return "#%02x%02x%02x" % tuple(int(x * (1 - amount) + y * amount + 0.5) for x, y in zip(rgb(a), rgb(b)))


class Check:
    def __init__(self, theme, app, palette):
        self.theme, self.app, self.palette = theme, app, palette
        self.errors = []
        self.low = {TEXT: 99.0, LINE: 99.0}

    def floor(self, label, fg, bg, minimum=TEXT):
        if fg is None or bg is None:
            self.errors.append(f"{label}: missing color ({fg} on {bg})")
            return
        ratio = contrast(fg, bg)
        self.low[minimum] = min(self.low[minimum], ratio)
        if ratio < minimum:
            self.errors.append(f"{label}: {ratio:.2f}:1 ({fg} on {bg}), floor {minimum}:1")

    def expect(self, condition, message):
        if not condition:
            self.errors.append(message)

    def headings(self, colors, bold):
        p = self.palette
        self.expect(colors[0].lower() == p["accent"].lower(), f"H1 is {colors[0]}, not the accent")
        for level, color in enumerate(colors, 1):
            expected = mix(p["accent"], p["foreground"], (level - 1) * 0.13)
            self.expect(color.lower() == expected.lower(), f"H{level} is {color}, expected {expected}")
            self.expect(bold[level - 1], f"H{level} is not bold")

    def report(self):
        global failed
        name = f"{self.theme} {self.app}"
        if self.errors:
            failed = True
            print("\n".join(f"  {e}" for e in self.errors), file=sys.stderr)
            print(f"not ok - {name} meets the contrast floors and the shared mapping", file=sys.stderr)
        else:
            print(f"ok - {name} meets the contrast floors and the shared mapping (text {self.low[TEXT]:.2f}:1, lines {self.low[LINE]:.2f}:1)")


SYNTAX = {
    "string": "yellow",
    "number": "blue",
    "function": "green",
    "type": "cyan",
    "keyword": "magenta",
    "parameter": "orange",
    "property": "orange",
    "comment": "comment",
    "regexp": "red",
    "punctuation": "light_foreground",
}


def helix(theme, p, path):
    c = Check(theme, "helix", p)
    doc = tomllib.load(open(path, "rb"))
    palette = doc.pop("palette")

    def color(value):
        return palette.get(value, value)

    def style(scope):
        value = doc.get(scope)
        return {"fg": value} if isinstance(value, str) else (value or {})

    for key, value in palette.items():
        c.expect(re.fullmatch(r"#[0-9A-Fa-f]{6}", value), f"palette {key} is {value}")

    bg = p["background"]
    cursorline = color(style("ui.cursorline.primary")["bg"])
    lines = {"ui.window", "ui.background.separator", "ui.menu.scroll", "ui.statusline.separator"}
    decorative = {"ui.virtual.indent-guide", "ui.virtual.whitespace"}
    for scope, value in doc.items():
        s = style(scope)
        if "fg" not in s or scope in decorative:
            continue
        fg = color(s["fg"])
        under = color(s["bg"]) if "bg" in s else bg
        minimum = LINE if scope in lines else TEXT
        c.floor(scope, fg, under, minimum)
        if "bg" not in s and not scope.startswith("ui."):
            c.floor(f"{scope} on the cursorline", fg, cursorline, minimum)
            c.floor(f"{scope} in a popup", fg, color(style("ui.popup")["bg"]), minimum)
    c.floor("text in a selection", p["foreground"], color(style("ui.selection")["bg"]))
    c.floor("text in the selected menu row", color(style("ui.menu.selected")["fg"]), color(style("ui.menu.selected")["bg"]))
    for kind in ("error", "warning", "info", "hint"):
        c.floor(f"diagnostic.{kind} underline", color(style(f"diagnostic.{kind}")["underline"]["color"]), bg, LINE)

    expected = {
        "string": "string", "number": "constant.numeric", "function": "function", "type": "type",
        "keyword": "keyword", "parameter": "variable.parameter", "property": "variable.other.member",
        "comment": "comment", "regexp": "string.regexp", "punctuation": "punctuation",
    }
    for role, scope in expected.items():
        c.expect(color(style(scope)["fg"]).lower() == p[SYNTAX[role]].lower(), f"{scope} is not {SYNTAX[role]}")
    c.expect(color(doc["warning"]).lower() == p["orange"].lower(), "warning is not orange")
    c.expect(color(doc["hint"]).lower() == p["hint"].lower(), "hint is not the hint role")
    c.expect(color(style("ui.statusline.normal")["bg"]).lower() == p["accent"].lower(), "normal mode is not the accent")
    c.expect(color(style("ui.selection")["bg"]).lower() == p["selection"].lower(), "selection is not the selection role")

    headings = [style(f"markup.heading.{n}") for n in range(1, 7)]
    c.headings([color(h["fg"]) for h in headings], ["bold" in h.get("modifiers", []) for h in headings])
    c.report()


def vscode(theme, p, path):
    c = Check(theme, "vscode", p)
    doc = json.load(open(path))
    colors = doc["colors"]
    bg = colors["editor.background"]

    c.expect(doc["type"] == p["mode"], f"type is {doc['type']}")
    for key, value in colors.items():
        c.expect(re.fullmatch(r"#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?", value), f"{key} is {value}")
    c.expect("editor.selectionForeground" not in colors, "editor.selectionForeground flattens syntax in selections")

    def on(key, base):
        return over(colors[key], colors.get(base, base))

    surfaces = {p["background"].lower(), p["dark_background"].lower(), p["lighter_background"].lower()}
    for key, value in colors.items():
        if not re.search(r"(border|outline)(top|bottom)?$", key, re.I) or key in ("contrastBorder", "contrastActiveBorder"):
            continue
        if alpha(value) == 0 or value.lower() in surfaces:
            continue
        for base in ("editor.background", "sideBar.background"):
            c.floor(f"{key} on {base}", on(key, base), colors[base], LINE)
    c.floor("menu.separatorBackground", colors["menu.separatorBackground"], colors["menu.background"], LINE)
    for n in range(1, 7):
        c.floor(f"editorIndentGuide.activeBackground{n}", colors[f"editorIndentGuide.activeBackground{n}"], bg, LINE)

    pairs = [
        ("foreground", "editor.background"),
        ("editor.foreground", "editor.background"),
        ("editor.foreground", "editor.lineHighlightBackground"),
        ("editor.foreground", "editor.selectionBackground"),
        ("editorLineNumber.foreground", "editor.background"),
        ("editorLineNumber.activeForeground", "editor.lineHighlightBackground"),
        ("descriptionForeground", "editor.background"),
        ("descriptionForeground", "sideBar.background"),
        ("descriptionForeground", "editorWidget.background"),
        ("editorCodeLens.foreground", "editor.background"),
        ("editorGhostText.foreground", "editor.background"),
        ("editorInlayHint.foreground", "editorInlayHint.background"),
        ("editorInlayHint.parameterForeground", "editorInlayHint.parameterBackground"),
        ("editorInlayHint.typeForeground", "editorInlayHint.typeBackground"),
        ("editorWatermark.foreground", "editor.background"),
        ("textLink.foreground", "editor.background"),
        ("textLink.foreground", "editorHoverWidget.background"),
        ("textPreformat.foreground", "textPreformat.background"),
        ("editorLink.activeForeground", "editor.background"),
        ("breadcrumb.foreground", "breadcrumb.background"),
        ("breadcrumb.focusForeground", "breadcrumb.background"),
        ("activityBar.foreground", "activityBar.background"),
        ("activityBar.inactiveForeground", "activityBar.background"),
        ("activityBarBadge.foreground", "activityBarBadge.background"),
        ("sideBar.foreground", "sideBar.background"),
        ("sideBarTitle.foreground", "sideBar.background"),
        ("sideBarSectionHeader.foreground", "sideBarSectionHeader.background"),
        ("tab.activeForeground", "tab.activeBackground"),
        ("tab.inactiveForeground", "tab.inactiveBackground"),
        ("tab.unfocusedActiveForeground", "tab.unfocusedActiveBackground"),
        ("tab.unfocusedInactiveForeground", "tab.unfocusedInactiveBackground"),
        ("tab.hoverForeground", "tab.hoverBackground"),
        ("titleBar.activeForeground", "titleBar.activeBackground"),
        ("titleBar.inactiveForeground", "titleBar.inactiveBackground"),
        ("statusBar.foreground", "statusBar.background"),
        ("statusBar.debuggingForeground", "statusBar.debuggingBackground"),
        ("statusBarItem.hoverForeground", "statusBarItem.hoverBackground"),
        ("statusBarItem.prominentForeground", "statusBarItem.prominentBackground"),
        ("statusBarItem.prominentHoverForeground", "statusBarItem.prominentHoverBackground"),
        ("statusBarItem.remoteForeground", "statusBarItem.remoteBackground"),
        ("statusBarItem.remoteHoverForeground", "statusBarItem.remoteHoverBackground"),
        ("statusBarItem.errorForeground", "statusBarItem.errorBackground"),
        ("statusBarItem.errorHoverForeground", "statusBarItem.errorHoverBackground"),
        ("statusBarItem.warningForeground", "statusBarItem.warningBackground"),
        ("statusBarItem.warningHoverForeground", "statusBarItem.warningHoverBackground"),
        ("statusBarItem.offlineForeground", "statusBarItem.offlineBackground"),
        ("list.activeSelectionForeground", "list.activeSelectionBackground"),
        ("list.inactiveSelectionForeground", "list.inactiveSelectionBackground"),
        ("list.focusForeground", "list.focusBackground"),
        ("list.hoverForeground", "list.hoverBackground"),
        ("list.highlightForeground", "sideBar.background"),
        ("list.highlightForeground", "list.activeSelectionBackground"),
        ("list.focusHighlightForeground", "list.activeSelectionBackground"),
        ("list.highlightForeground", "list.hoverBackground"),
        ("list.errorForeground", "sideBar.background"),
        ("list.warningForeground", "sideBar.background"),
        ("list.deemphasizedForeground", "sideBar.background"),
        ("button.foreground", "button.background"),
        ("button.foreground", "button.hoverBackground"),
        ("button.secondaryForeground", "button.secondaryBackground"),
        ("button.secondaryForeground", "button.secondaryHoverBackground"),
        ("extensionButton.prominentForeground", "extensionButton.prominentBackground"),
        ("extensionButton.prominentForeground", "extensionButton.prominentHoverBackground"),
        ("badge.foreground", "badge.background"),
        ("panelTitleBadge.foreground", "panelTitleBadge.background"),
        ("input.foreground", "input.background"),
        ("input.placeholderForeground", "input.background"),
        ("inputOption.activeForeground", "inputOption.activeBackground"),
        ("inputValidation.errorForeground", "inputValidation.errorBackground"),
        ("inputValidation.warningForeground", "inputValidation.warningBackground"),
        ("inputValidation.infoForeground", "inputValidation.infoBackground"),
        ("dropdown.foreground", "dropdown.background"),
        ("dropdown.foreground", "dropdown.listBackground"),
        ("editorWidget.foreground", "editorWidget.background"),
        ("editorSuggestWidget.foreground", "editorSuggestWidget.background"),
        ("editorSuggestWidget.selectedForeground", "editorSuggestWidget.selectedBackground"),
        ("editorSuggestWidget.highlightForeground", "editorSuggestWidget.background"),
        ("editorSuggestWidget.focusHighlightForeground", "editorSuggestWidget.selectedBackground"),
        ("editorSuggestWidgetStatus.foreground", "editorSuggestWidget.background"),
        ("editorHoverWidget.foreground", "editorHoverWidget.background"),
        ("editorHoverWidget.highlightForeground", "editorHoverWidget.background"),
        ("quickInput.foreground", "quickInput.background"),
        ("quickInputList.focusForeground", "quickInputList.focusBackground"),
        ("pickerGroup.foreground", "quickInput.background"),
        ("menu.foreground", "menu.background"),
        ("menu.selectionForeground", "menu.selectionBackground"),
        ("menubar.selectionForeground", "menubar.selectionBackground"),
        ("commandCenter.foreground", "commandCenter.background"),
        ("commandCenter.activeForeground", "commandCenter.activeBackground"),
        ("commandCenter.inactiveForeground", "commandCenter.background"),
        ("notifications.foreground", "notifications.background"),
        ("notificationLink.foreground", "notifications.background"),
        ("notificationCenterHeader.foreground", "notificationCenterHeader.background"),
        ("banner.foreground", "banner.background"),
        ("banner.iconForeground", "banner.background"),
        ("keybindingLabel.foreground", "keybindingLabel.background"),
        ("panelTitle.activeForeground", "panel.background"),
        ("panelTitle.inactiveForeground", "panel.background"),
        ("panelSectionHeader.foreground", "panelSectionHeader.background"),
        ("peekViewResult.fileForeground", "peekViewResult.background"),
        ("peekViewResult.lineForeground", "peekViewResult.background"),
        ("peekViewResult.selectionForeground", "peekViewResult.selectionBackground"),
        ("peekViewTitleLabel.foreground", "peekViewTitle.background"),
        ("peekViewTitleDescription.foreground", "peekViewTitle.background"),
        ("debugView.stateLabelForeground", "debugView.stateLabelBackground"),
        ("debugView.exceptionLabelForeground", "debugView.exceptionLabelBackground"),
        ("settings.headerForeground", "editor.background"),
        ("settings.textInputForeground", "settings.textInputBackground"),
        ("diffEditor.unchangedRegionForeground", "diffEditor.unchangedRegionBackground"),
        ("chat.slashCommandForeground", "chat.slashCommandBackground"),
        ("inlineChat.foreground", "inlineChat.background"),
        ("inlineChatInput.placeholderForeground", "inlineChatInput.background"),
        ("terminal.foreground", "terminal.background"),
        ("terminal.foreground", "terminal.selectionBackground"),
    ]
    for key in colors:
        if key.startswith("gitDecoration."):
            pairs.append((key, "sideBar.background"))
        if key.startswith("terminal.ansi") and key not in ("terminal.ansiBlack", "terminal.ansiWhite", "terminal.ansiBrightWhite"):
            pairs.append((key, "terminal.background"))
        if key.startswith(("editorError.f", "editorWarning.f", "editorInfo.f", "editorHint.f")):
            pairs.append((key, "editor.background"))
    for fg, base in pairs:
        c.floor(f"{fg} on {base}", on(fg, base) if alpha(colors[fg]) < 1 else colors[fg], on(base, "editor.background"))
    for key in colors:
        if key.startswith("symbolIcon."):
            c.floor(f"{key} on the suggest widget", colors[key], colors["editorSuggestWidget.background"], LINE)

    surfaces = [bg, colors["editor.lineHighlightBackground"], colors["peekViewEditor.background"]]
    by_name = {}
    for token in doc["tokenColors"]:
        fg = token["settings"].get("foreground")
        if not fg:
            continue
        by_name[token["name"]] = fg
        for surface in surfaces:
            c.floor(f"token {token['name']} on {surface}", fg, surface)
    for key, value in doc["semanticTokenColors"].items():
        fg = value if isinstance(value, str) else value.get("foreground")
        if fg:
            for surface in surfaces:
                c.floor(f"semantic {key} on {surface}", fg, surface)

    tokens = {
        "string": "String", "number": "Constant", "function": "Function", "type": "Type", "keyword": "Keyword",
        "parameter": "Parameter", "property": "Property", "comment": "Comment", "regexp": "Regexp", "punctuation": "Punctuation",
    }
    for role, name in tokens.items():
        c.expect(by_name[name].lower() == p[SYNTAX[role]].lower(), f"token {name} is not {SYNTAX[role]}")
    semantic = doc["semanticTokenColors"]
    for key, role in (("function", "green"), ("method", "green"), ("class", "cyan"), ("property", "orange"), ("number", "blue"), ("string", "yellow"), ("keyword", "magenta")):
        c.expect(semantic[key].lower() == p[role].lower(), f"semantic {key} is not {role}")
    c.expect(semantic["parameter"]["foreground"].lower() == p["orange"].lower(), "semantic parameter is not orange")
    for key, role in (
        ("editorError.foreground", "red"), ("editorWarning.foreground", "orange"), ("editorInfo.foreground", "cyan"),
        ("editorHint.foreground", "hint"), ("textLink.foreground", "link"), ("list.warningForeground", "orange"),
        ("statusBarItem.warningBackground", "orange"), ("editor.selectionBackground", "selection"),
        ("focusBorder", "border_focus"), ("editorGroup.border", "border"), ("panel.border", "border"),
        ("terminal.ansiBrightBlack", "comment"), ("editorGutter.modifiedBackground", "blue"),
    ):
        c.expect(colors[key].lower() == p[role].lower(), f"{key} is {colors[key]}, not {role}")
    for key in ("list.hoverBackground", "list.activeSelectionBackground", "editor.lineHighlightBackground"):
        c.expect(colors[key].lower() != p["selection"].lower(), f"{key} reuses the selection fill")

    headings = [by_name["Heading"]] + [by_name[f"Heading {n}"] for n in range(2, 7)]
    styles = [next(t for t in doc["tokenColors"] if t["name"] == n)["settings"]["fontStyle"] for n in ["Heading"] + [f"Heading {n}" for n in range(2, 7)]]
    c.headings(headings, ["bold" in s for s in styles])
    c.report()


def sublime(theme, p, path):
    c = Check(theme, "sublime", p)
    doc = json.load(open(path))
    g = doc["globals"]
    for key, value in g.items():
        if key.endswith(("_options", "_width", "_style")):
            continue
        c.expect(re.fullmatch(r"#[0-9A-Fa-f]{6}", value), f"{key} is {value}")

    c.floor("foreground", g["foreground"], g["background"])
    c.floor("foreground in a selection", g["foreground"], g["selection"])
    c.floor("gutter_foreground", g["gutter_foreground"], g["gutter"])
    c.floor("gutter_foreground on the current line", g["gutter_foreground"], g["line_highlight"])
    c.floor("gutter_foreground_highlight", g["gutter_foreground_highlight"], g["line_highlight"])
    c.floor("find_highlight_foreground", g["find_highlight_foreground"], g["find_highlight"])
    for key in ("active_guide", "minimap_border", "brackets_foreground", "tags_foreground"):
        c.floor(key, g[key], g["background"], LINE)
    for key in ("line_diff_added", "line_diff_modified", "line_diff_deleted"):
        c.floor(key, g[key], g["gutter"], LINE)
    c.expect(g["line_highlight"].lower() != g["selection"].lower(), "the current line looks selected")
    c.expect(g["selection"].lower() == p["selection"].lower(), "selection is not the selection role")
    c.expect("selection_foreground" not in g, "selection_foreground flattens syntax in selections")

    by_name = {}
    for rule in doc["rules"]:
        by_name[rule["name"]] = rule
        for surface in ("background", "line_highlight"):
            c.floor(f"{rule['name']} on {surface}", rule["foreground"], g[surface])

    names = {
        "string": "String", "number": "Constant", "function": "Function", "type": "Type", "keyword": "Keyword",
        "parameter": "Parameter", "property": "Property", "comment": "Comment", "regexp": "Regexp", "punctuation": "Punctuation",
    }
    for role, name in names.items():
        c.expect(by_name[name]["foreground"].lower() == p[SYNTAX[role]].lower(), f"rule {name} is not {SYNTAX[role]}")
    c.expect(by_name["Deleted"]["foreground"].lower() == p["red"].lower(), "markup.deleted is not red")
    c.expect("background" not in by_name["Invalid"], "invalid paints a background")

    headings = [by_name["Heading"]] + [by_name[f"Heading {n}"] for n in range(2, 7)]
    c.headings([h["foreground"] for h in headings], ["bold" in h.get("font_style", "") for h in headings])
    c.report()


def obsidian(theme, p, path):
    c = Check(theme, "obsidian", p)
    css = open(path).read()
    block = css[css.index("{") + 1:css.index("}")]
    raw = dict(re.findall(r"(--[\w-]+):\s*([^;]+);", block))

    def value(name):
        v = raw[name].strip()
        while (m := re.fullmatch(r"var\((--[\w-]+)\)", v)):
            v = raw[m.group(1)].strip()
        m = re.fullmatch(r"color-mix\(in srgb, (#[0-9A-Fa-f]{6}) (\d+)%, transparent\)", v)
        if m:
            return m.group(1) + "%02x" % round(int(m.group(2)) * 255 / 100)
        return v if re.fullmatch(r"#[0-9A-Fa-f]{6}", v) else None

    primary, secondary, code = value("--background-primary"), value("--background-secondary"), value("--code-background")
    text = ["--text-normal", "--text-muted", "--text-faint", "--text-accent", "--text-error", "--text-warning",
            "--text-success", "--link-color", "--link-external-color", "--bold-color", "--blockquote-color",
            "--list-marker-color", "--icon-color", "--icon-color-active"] + [f"--h{n}-color" for n in range(1, 7)]
    for name in text:
        for base in (primary, secondary):
            c.floor(f"{name} on {base}", value(name), base)
        c.floor(f"{name} on hover", value(name), over(value("--background-modifier-hover"), primary))
    for name in [n for n in raw if n.startswith("--code-") and n != "--code-background"]:
        c.floor(f"{name} on the code background", value(name), code)
    c.floor("--text-normal in a selection", value("--text-normal"), value("--text-selection"))
    c.floor("--text-normal in a highlight", value("--text-normal"), value("--text-highlight-bg"))
    c.floor("--tag-color", value("--tag-color"), value("--tag-background"))
    c.floor("--tag-color on hover", value("--tag-color-hover"), value("--tag-background-hover"))
    c.floor("--text-on-accent", value("--text-on-accent"), value("--interactive-accent"))
    c.floor("--text-on-accent on hover", value("--text-on-accent"), value("--interactive-accent-hover"))
    c.floor("--nav-item-color-active", value("--nav-item-color-active"), value("--nav-item-background-active"))
    c.floor("--text-normal on --interactive-normal", value("--text-normal"), value("--interactive-normal"))
    c.floor("--text-normal on --interactive-hover", value("--text-normal"), value("--interactive-hover"))
    for name in ("--background-modifier-border", "--background-modifier-border-focus", "--divider-color", "--hr-color",
                 "--table-border-color", "--blockquote-border-color", "--checkbox-border-color", "--graph-line"):
        for base in (primary, secondary):
            c.floor(f"{name} on {base}", value(name), base, LINE)

    for selector, color in re.findall(r"([^{}]+)\{[^}]*?(?<![-\w])color:\s*(#[0-9A-Fa-f]{6})", css[css.index("}") + 1:]):
        label = " ".join(selector.split())[:60]
        c.floor(f"{label} on the page", color, primary)
        c.floor(f"{label} in a code block", color, code)

    for role, name in (("yellow", "--code-string"), ("green", "--code-function"), ("magenta", "--code-keyword"),
                       ("orange", "--code-property"), ("blue", "--code-value"), ("comment", "--code-comment"),
                       ("red", "--code-important"), ("light_foreground", "--code-punctuation"), ("link", "--link-color"),
                       ("border", "--background-modifier-border"), ("selection", "--text-selection"), ("orange", "--text-warning")):
        c.expect((value(name) or "").lower() == p[role].lower(), f"{name} is {value(name)}, not {role}")

    weights = [raw.get(f"--h{n}-weight", "").strip() == "700" for n in range(1, 7)]
    c.headings([value(f"--h{n}-color") for n in range(1, 7)], weights)
    c.report()


for theme in themes:
    base = f"{root}/{theme}/.local/state/maitri/current/next-theme"
    palette = dict(line.split("\t", 1) for line in open(f"{root}/{theme}/palette.tsv").read().splitlines())
    helix(theme, palette, f"{base}/helix.toml")
    vscode(theme, palette, f"{base}/vscode-theme.json")
    sublime(theme, palette, f"{base}/maitri.sublime-color-scheme")
    obsidian(theme, palette, f"{base}/obsidian.css")

sys.exit(1 if failed else 0)
PY
