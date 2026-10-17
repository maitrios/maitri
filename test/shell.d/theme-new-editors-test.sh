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

  for file in zed.json jetbrains.icls emacs-theme.el; do
    [[ -f $next_theme/$file ]] || fail "$theme renders $file"
    ! grep -q '{{' "$next_theme/$file" || fail "$theme leaves no placeholders in $file" "$(grep -n '{{' "$next_theme/$file")"
  done
  themes+=("$theme")
done

(( ${#themes[@]} > 0 )) || fail "themes are rendered"

python3 - "$test_tmp" "${themes[@]}" <<'PY'
import json, re, sys
import xml.etree.ElementTree as ET

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
    return "#%02x%02x%02x" % tuple(round(t * a + b * (1 - a)) for t, b in zip(rgb(color), rgb(base)))


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


def same(a, b):
    return a is not None and b is not None and a.lstrip("#").lower() == b.lstrip("#").lower()


SYNTAX = {
    "string": "yellow", "number": "blue", "constant": "blue", "function": "green", "type": "cyan",
    "keyword": "magenta", "operator": "magenta", "parameter": "orange", "property": "orange",
    "attribute": "green", "regexp": "red", "comment": "comment", "punctuation": "light_foreground",
    "tag": "cyan", "escape": "magenta",
}


class Check:
    def __init__(self, theme, app, palette):
        self.theme, self.app, self.p = theme, app, palette
        self.errors = []
        self.low = {TEXT: 99.0, LINE: 99.0}

    def floor(self, label, fg, bg, minimum=TEXT):
        if fg is None or bg is None:
            self.errors.append(f"{label}: missing color ({fg} on {bg})")
            return
        fg, bg = "#" + fg.lstrip("#"), "#" + bg.lstrip("#")
        ratio = contrast(fg, bg)
        self.low[minimum] = min(self.low[minimum], ratio)
        if ratio < minimum:
            self.errors.append(f"{label}: {ratio:.2f}:1 ({fg} on {bg}), floor {minimum}:1")

    def role(self, label, got, role):
        if not same(got, self.p[role]):
            self.errors.append(f"{label} is {got}, expected {role} {self.p[role]}")

    def expect(self, condition, message):
        if not condition:
            self.errors.append(message)

    def headings(self, colors, bold):
        for level, color in enumerate(colors, 1):
            expected = mix(self.p["accent"], self.p["foreground"], (level - 1) * 0.13)
            self.expect(same(color, expected), f"H{level} is {color}, expected {expected}")
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


def zed(theme, p, path):
    c = Check(theme, "zed", p)
    doc = json.load(open(path))
    entry = doc["themes"][0]
    s = entry["style"]
    c.expect(entry["name"] == "maitri", "the Zed theme is not named maitri")
    c.expect(entry["appearance"] == p["mode"], f"appearance is {entry['appearance']}, not {p['mode']}")
    for key, value in s.items():
        if isinstance(value, str):
            c.expect(re.fullmatch(r"#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?", value), f"{key} is {value}")

    surfaces = ["background", "surface.background", "elevated_surface.background", "editor.background",
                "editor.active_line.background", "tab.active_background", "tab.inactive_background",
                "panel.background", "status_bar.background", "title_bar.background", "element.background",
                "element.hover", "ghost_element.hover"]
    statuses = ["error", "warning", "info", "hint", "success", "created", "modified", "deleted",
                "conflict", "renamed", "ignored", "hidden", "unreachable", "predictive"]
    text = ["text", "text.muted", "text.placeholder", "text.disabled", "text.accent", "icon", "icon.muted",
            "icon.placeholder", "icon.disabled", "icon.accent", "link_text.hover", "editor.foreground",
            "editor.line_number", "editor.active_line_number", "terminal.foreground"]
    text += statuses + [k for k in s if k.startswith("version_control.")]
    for key in text:
        for surface in surfaces:
            c.floor(f"{key} on {surface}", s[key], s[surface])
    for key in ["text", "text.muted", "text.accent", "icon", "icon.muted", "icon.accent"]:
        for row in ["element.selected", "element.active", "ghost_element.selected", "ghost_element.active"]:
            c.floor(f"{key} on {row}", s[key], s[row])
    for status in statuses:
        c.floor(f"{status} on {status}.background", s[status], s[f"{status}.background"])
        c.floor(f"{status}.border", s[f"{status}.border"], s["editor.background"], LINE)
    c.floor("text in a search match", s["editor.foreground"], s["search.match_background"])
    c.floor("text in a selection", s["editor.foreground"], s["players"][0]["selection"])
    c.floor("text on a document highlight", s["editor.foreground"], s["editor.document_highlight.read_background"])
    lines = ["border", "border.variant", "border.focused", "border.selected", "border.disabled",
             "panel.focused_border", "pane.focused_border", "pane_group.border", "editor.active_wrap_guide",
             "editor.indent_guide_active", "panel.indent_guide_active"]
    for key in lines:
        for surface in ["background", "editor.background", "panel.background"]:
            c.floor(f"{key} on {surface}", s[key], s[surface], LINE)

    syntax = s["syntax"]
    for key, style in syntax.items():
        for surface in ["editor.background", "editor.active_line.background", "elevated_surface.background"]:
            c.floor(f"syntax {key} on {surface}", style["color"], s[surface])
        if "font_style" in style:
            c.expect(style["font_style"] in {"normal", "italic", "oblique"}, f"syntax {key} font_style {style['font_style']}")
    expected = {
        "string": "string", "number": "number", "constant": "constant", "function": "function", "type": "type",
        "keyword": "keyword", "operator": "operator", "parameter": "variable.parameter", "property": "property",
        "attribute": "attribute", "regexp": "string.regex", "comment": "comment", "punctuation": "punctuation",
        "tag": "tag", "escape": "string.escape",
    }
    for role, key in expected.items():
        c.role(f"syntax {key}", syntax[key]["color"], SYNTAX[role])
    c.expect(syntax["type"].get("font_style") == "italic", "types are not italic")
    c.expect(syntax["comment"].get("font_style") == "italic", "comments are not italic")
    c.expect(syntax["variable.parameter"].get("font_style") == "italic", "parameters are not italic")
    c.role("link_text", syntax["link_text"]["color"], "link")
    c.role("title", syntax["title"]["color"], "accent")
    c.expect(syntax["title"].get("font_weight", 0) >= 700, "headings are not bold")
    c.role("hint", s["hint"], "hint")
    c.role("warning", s["warning"], "orange")
    c.role("error", s["error"], "red")
    c.role("border", s["border"], "border")
    c.role("focused border", s["border.focused"], "border_focus")
    c.role("selection", s["players"][0]["selection"], "selection")
    c.role("line numbers", s["editor.line_number"], "comment")
    c.report()


def jetbrains(theme, p, path):
    c = Check(theme, "jetbrains", p)
    scheme = ET.parse(path).getroot()
    c.expect(scheme.get("name") == "maitri", "the scheme is not named maitri")
    colors = {o.get("name"): o.get("value") for o in scheme.find("colors")}
    attrs = {}
    for option in scheme.find("attributes"):
        value = option.find("value")
        attrs[option.get("name")] = {o.get("name"): o.get("value") for o in value} if value is not None else {}
    for name, value in colors.items():
        c.expect(value == "" or re.fullmatch(r"[0-9A-Fa-f]{6}", value), f"color {name} is {value}")
    for name, values in attrs.items():
        for key in ("FOREGROUND", "BACKGROUND", "EFFECT_COLOR", "ERROR_STRIPE_COLOR"):
            if key in values:
                c.expect(re.fullmatch(r"[0-9A-Fa-f]{6}", values[key]), f"{name} {key} is {values[key]}")
        c.expect(values.get("FONT_TYPE", "0") in {"0", "1", "2", "3"}, f"{name} FONT_TYPE is {values.get('FONT_TYPE')}")
        c.expect(values.get("EFFECT_TYPE", "0") in {"0", "1", "2", "3", "4", "5"}, f"{name} EFFECT_TYPE is {values.get('EFFECT_TYPE')}")

    bg, fg = attrs["TEXT"]["BACKGROUND"], attrs["TEXT"]["FOREGROUND"]
    row = colors["CARET_ROW_COLOR"]
    for name, values in attrs.items():
        if "FOREGROUND" in values:
            if "BACKGROUND" in values:
                under = [values["BACKGROUND"]]
            elif name.startswith(("CONSOLE_", "LOG_")):
                under = [colors["CONSOLE_BACKGROUND_KEY"]]
            else:
                under = [bg, row, colors["LOOKUP_COLOR"]]
            for surface in under:
                c.floor(f"{name} on {surface}", values["FOREGROUND"], surface)
        elif "BACKGROUND" in values:
            c.floor(f"text on {name}", fg, values["BACKGROUND"])
        if "EFFECT_COLOR" in values:
            c.floor(f"{name} effect", values["EFFECT_COLOR"], bg, LINE)
    c.floor("braces on MATCHED_BRACE_ATTRIBUTES", attrs["DEFAULT_BRACES"]["FOREGROUND"], attrs["MATCHED_BRACE_ATTRIBUTES"]["BACKGROUND"])
    c.floor("line numbers", colors["LINE_NUMBERS_COLOR"], colors["GUTTER_BACKGROUND"])
    c.floor("the caret row's line number", colors["LINE_NUMBER_ON_CARET_ROW_COLOR"], row)
    for surface in ("SELECTION_BACKGROUND", "LOOKUP_COLOR", "DOCUMENTATION_COLOR", "INFORMATION_HINT", "NOTIFICATION_BACKGROUND"):
        c.floor(f"text on {surface}", fg, colors[surface])
    for name in ("TEARLINE_COLOR", "SELECTED_TEARLINE_COLOR", "METHOD_SEPARATORS_COLOR", "SELECTED_INDENT_GUIDE",
                 "ADDED_LINES_COLOR", "MODIFIED_LINES_COLOR", "DELETED_LINES_COLOR", "CARET_COLOR"):
        c.floor(name, colors[name], bg, LINE)
    for name in [n for n in colors if n.startswith("FILESTATUS_")]:
        c.floor(name, colors[name], bg)
    c.expect(colors["SELECTION_FOREGROUND"] == "", "selection overrides the syntax colours")

    expected = {
        "string": "DEFAULT_STRING", "number": "DEFAULT_NUMBER", "constant": "DEFAULT_CONSTANT",
        "function": "DEFAULT_FUNCTION_DECLARATION", "type": "DEFAULT_CLASS_NAME", "keyword": "DEFAULT_KEYWORD",
        "operator": "DEFAULT_OPERATION_SIGN", "parameter": "DEFAULT_PARAMETER", "property": "DEFAULT_INSTANCE_FIELD",
        "attribute": "DEFAULT_METADATA", "comment": "DEFAULT_LINE_COMMENT", "punctuation": "DEFAULT_COMMA",
        "tag": "DEFAULT_TAG", "escape": "DEFAULT_VALID_STRING_ESCAPE",
    }
    for role, name in expected.items():
        c.role(name, attrs[name]["FOREGROUND"], SYNTAX[role])
    for name in ("DEFAULT_LINE_COMMENT", "DEFAULT_BLOCK_COMMENT", "DEFAULT_PARAMETER"):
        c.expect(attrs[name].get("FONT_TYPE") == "2", f"{name} is not italic")
    c.role("ERRORS_ATTRIBUTES", attrs["ERRORS_ATTRIBUTES"]["EFFECT_COLOR"], "red")
    c.role("WARNING_ATTRIBUTES", attrs["WARNING_ATTRIBUTES"]["EFFECT_COLOR"], "orange")
    c.role("WEAK_WARNING_ATTRIBUTES", attrs["WEAK_WARNING_ATTRIBUTES"]["EFFECT_COLOR"], "hint")
    c.role("HYPERLINK_ATTRIBUTES", attrs["HYPERLINK_ATTRIBUTES"]["FOREGROUND"], "link")
    c.role("SELECTION_BACKGROUND", colors["SELECTION_BACKGROUND"], "selection")
    c.role("TEARLINE_COLOR", colors["TEARLINE_COLOR"], "border")
    c.role("SELECTED_TEARLINE_COLOR", colors["SELECTED_TEARLINE_COLOR"], "border_focus")
    c.role("LINE_NUMBERS_COLOR", colors["LINE_NUMBERS_COLOR"], "comment")
    headings = [attrs[f"MARKDOWN_HEADER_LEVEL_{n}"] for n in range(1, 7)]
    c.headings(["#" + h["FOREGROUND"] for h in headings], [h.get("FONT_TYPE") in {"1", "3"} for h in headings])
    c.report()


def sexp_balanced(text):
    depth, i, n = 0, 0, len(text)
    while i < n:
        ch = text[i]
        if ch == ";":
            while i < n and text[i] != "\n":
                i += 1
        elif ch == '"':
            i += 1
            while i < n and text[i] != '"':
                i += 2 if text[i] == "\\" else 1
        elif ch == "(":
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth < 0:
                return False
        i += 1
    return depth == 0


LINES = {"vertical-border", "window-divider", "window-divider-first-pixel", "window-divider-last-pixel", "corfu-border"}
DECORATIVE = {"cursor", "fill-column-indicator", "trailing-whitespace"}


def emacs(theme, p, path):
    c = Check(theme, "emacs", p)
    source = open(path).read()
    c.expect(sexp_balanced(source), "maitri-theme.el has unbalanced parentheses or strings")
    c.expect("(deftheme maitri" in source and "(provide-theme 'maitri)" in source, "maitri-theme.el does not define the maitri theme")
    faces = {}
    for name, spec in re.findall(r"^ '\(([\w-]+) \(\(t \((.*)\)\)\)\)\)?$", source, re.M):
        face = {}
        for key in ("foreground", "background", "inherit", "weight", "slant"):
            m = re.search(rf':{key} ("?)([^\s")]+)\1', spec)
            if m:
                face[key] = m.group(2)
        face["lines"] = re.findall(r':color "(#[0-9A-Fa-f]{6})"', spec)
        faces[name] = face
    c.expect(len(faces) > 100, f"only {len(faces)} faces parsed from maitri-theme.el")

    def resolve(name, key):
        face = faces.get(name, {})
        if key in face:
            return face[key]
        return resolve(face["inherit"], key) if "inherit" in face else None

    default_fg, default_bg = faces["default"]["foreground"], faces["default"]["background"]
    hl_line, mode_line = faces["hl-line"]["background"], faces["mode-line"]["background"]
    selected = faces["vertico-current"]["background"]
    for name, face in faces.items():
        fg, bg = resolve(name, "foreground"), face.get("background")
        if name in DECORATIVE or (fg and bg and same(fg, bg)):
            continue
        if name in LINES:
            for surface in (default_bg, mode_line):
                c.floor(f"{name} on {surface}", fg or bg, surface, LINE)
        elif fg and bg:
            c.floor(f"{name}", fg, bg)
        elif fg:
            for surface in (default_bg, hl_line):
                c.floor(f"{name} on {surface}", fg, surface)
        elif bg:
            c.floor(f"text on {name}", default_fg, bg)
        for line in face["lines"]:
            c.floor(f"{name} line", line, default_bg, LINE)
            if name.startswith("mode-line") or name == "help-key-binding":
                c.floor(f"{name} line on its own fill", line, mode_line, LINE)
    for name in ("mode-line-buffer-id", "mode-line-emphasis", "minibuffer-prompt", "help-key-binding"):
        c.floor(f"{name} in the mode line", resolve(name, "foreground"), mode_line)
    for name in ("completions-common-part", "completions-first-difference", "completions-annotations",
                 "orderless-match-face-0", "orderless-match-face-1", "orderless-match-face-2", "orderless-match-face-3",
                 "company-tooltip-common"):
        c.floor(f"{name} on the selected candidate", resolve(name, "foreground"), selected)
    c.floor("braces on show-paren-match", faces["font-lock-bracket-face"]["foreground"], faces["show-paren-match"]["background"])

    expected = {
        "string": "font-lock-string-face", "number": "font-lock-number-face", "constant": "font-lock-constant-face",
        "function": "font-lock-function-name-face", "type": "font-lock-type-face", "keyword": "font-lock-keyword-face",
        "operator": "font-lock-operator-face", "property": "font-lock-property-name-face",
        "regexp": "font-lock-regexp-face", "comment": "font-lock-comment-face",
        "punctuation": "font-lock-punctuation-face", "escape": "font-lock-escape-face",
    }
    for role, name in expected.items():
        c.role(name, faces[name]["foreground"], SYNTAX[role])
    c.expect(faces["font-lock-type-face"].get("slant") == "italic", "types are not italic")
    c.expect(faces["font-lock-comment-face"].get("slant") == "italic", "comments are not italic")
    c.role("region", faces["region"]["background"], "selection")
    c.role("link", faces["link"]["foreground"], "link")
    c.role("warning", faces["warning"]["foreground"], "orange")
    c.role("error", faces["error"]["foreground"], "red")
    c.role("vertical-border", faces["vertical-border"]["foreground"], "border")
    c.role("line-number", faces["line-number"]["foreground"], "comment")
    c.expect(same(faces["flymake-note"]["lines"][0], p["hint"]), "flymake notes are not the hint role")
    c.expect(same(faces["mode-line"]["lines"][0], p["border_focus"]), "the active mode line is not framed in border_focus")
    for tree in ("outline", "org-level", "markdown-header-face", "shr-h"):
        levels = [f"{tree}-{n}" if tree != "shr-h" else f"shr-h{n}" for n in range(1, 7)]
        c.headings([resolve(n, "foreground") for n in levels], [resolve(n, "weight") == "bold" for n in levels])
    c.report()


for theme in themes:
    palette = dict(line.rstrip("\n").split("\t", 1) for line in open(f"{root}/{theme}/palette.tsv"))
    rendered = f"{root}/{theme}/.local/state/maitri/current/next-theme"
    zed(theme, palette, f"{rendered}/zed.json")
    jetbrains(theme, palette, f"{rendered}/jetbrains.icls")
    emacs(theme, palette, f"{rendered}/emacs-theme.el")

sys.exit(1 if failed else 0)
PY

pass "Zed, JetBrains and Emacs render for every theme with readable contrast and the shared mapping"

if command -v emacs >/dev/null 2>&1; then
  for theme in "${themes[@]}"; do
    rendered="$test_tmp/$theme/.local/state/maitri/current/next-theme"
    mkdir -p "$test_tmp/$theme/emacs-themes"
    cp "$rendered/emacs-theme.el" "$test_tmp/$theme/emacs-themes/maitri-theme.el"
    expected=$(awk -F'\t' '$1 == "background" { print tolower($2) }' "$test_tmp/$theme/palette.tsv")
    got=$(HOME="$test_tmp/$theme" emacs -Q --batch \
      --eval "(add-to-list 'custom-theme-load-path \"$test_tmp/$theme/emacs-themes\")" \
      --eval "(load-theme 'maitri t)" \
      --eval "(princ (downcase (face-attribute 'default :background)))" 2>&1) ||
      fail "Emacs loads the $theme maitri theme" "$got"
    [[ $got == "$expected" ]] || fail "Emacs applies the $theme maitri theme" "default background is $got, expected $expected"
  done
  pass "Emacs loads maitri-theme.el for every theme"
else
  skip "Emacs loads maitri-theme.el for every theme (emacs is not installed)"
fi

sandbox="$test_tmp/sandbox-bin"
apps="$test_tmp/app-bin"
mkdir -p "$sandbox" "$apps"
for tool in awk cp dirname mkdir sed; do
  ln -s "$(command -v "$tool")" "$sandbox/$tool"
done
for app in zeditor emacs; do
  printf '#!/bin/bash\n' >"$apps/$app"
  chmod +x "$apps/$app"
done

run_hook() {
  local home="$1" hook="$2" path="$3"

  HOME="$home" MAITRI_PATH="$ROOT" PATH="$ROOT/bin:$path" "$BASH" "$ROOT/bin/$hook" 2>>"$home/hook.stderr"
}

for theme in amethyst daybreak; do
  home="$test_tmp/hooks-$theme"
  mkdir -p "$home/.local/state/maitri/current"
  cp -r "$test_tmp/$theme/.local/state/maitri/current/next-theme" "$home/.local/state/maitri/current/theme"
  : >"$home/hook.stderr"

  for hook in maitri-theme-set-zed maitri-theme-set-jetbrains maitri-theme-set-emacs; do
    run_hook "$home" "$hook" "$sandbox" || fail "$hook exits cleanly when its app is missing"
  done
  [[ ! -e $home/.config/zed && ! -e $home/.config/emacs && ! -e $home/.emacs.d && ! -e $home/.config/JetBrains ]] ||
    fail "the editor hooks leave no files behind when the editors are missing" "$(find "$home/.config" "$home/.emacs.d" 2>/dev/null)"
  [[ ! -s $home/hook.stderr ]] || fail "the editor hooks stay quiet when the editors are missing" "$(cat "$home/hook.stderr")"

  rendered="$home/.local/state/maitri/current/theme"
  mkdir -p "$home/.config/JetBrains/IntelliJIdea2025.2" "$home/.config/JetBrains/PyCharm2025.1" "$home/.config/JetBrains/consentOptions"
  for hook in maitri-theme-set-zed maitri-theme-set-jetbrains maitri-theme-set-emacs; do
    run_hook "$home" "$hook" "$apps:$sandbox" || fail "$hook installs the $theme theme"
  done

  [[ $(<"$rendered/zed.json") == "$(<"$home/.config/zed/themes/maitri.json")" ]] || fail "Zed gets the $theme theme in its themes dir"
  [[ ! -e $home/.config/zed/settings.json ]] || fail "the Zed hook leaves Zed's settings alone"
  [[ $(<"$rendered/emacs-theme.el") == "$(<"$home/.config/emacs/themes/maitri-theme.el")" ]] || fail "Emacs gets the $theme theme under ~/.config/emacs/themes"

  parent="Darcula"
  [[ $theme == "daybreak" ]] && parent="Default"
  for ide in IntelliJIdea2025.2 PyCharm2025.1; do
    scheme="$home/.config/JetBrains/$ide/colors/maitri.icls"
    [[ -f $scheme ]] || fail "$ide gets the $theme colour scheme"
    head -n 1 "$scheme" | grep -q "parent_scheme=\"$parent\"" || fail "the $theme colour scheme inherits from $parent" "$(head -n 1 "$scheme")"
    [[ $(tail -n +2 "$rendered/jetbrains.icls") == "$(tail -n +2 "$scheme")" ]] || fail "$ide gets the rendered $theme colour scheme"
  done
  [[ ! -e $home/.config/JetBrains/consentOptions/colors ]] || fail "only versioned IDE config dirs get a colour scheme"
  grep -q "JetBrains IDEs pick up the maitri colour scheme after a restart" "$home/hook.stderr" ||
    fail "the JetBrains hook says a restart is needed" "$(cat "$home/hook.stderr")"
  grep -q "load-theme 'maitri" "$home/hook.stderr" || fail "the Emacs hook says how to pick up the theme" "$(cat "$home/hook.stderr")"

  mkdir -p "$home/.emacs.d"
  run_hook "$home" maitri-theme-set-emacs "$apps:$sandbox" || fail "maitri-theme-set-emacs installs into ~/.emacs.d"
  [[ $(<"$rendered/emacs-theme.el") == "$(<"$home/.emacs.d/themes/maitri-theme.el")" ]] || fail "Emacs gets the $theme theme under ~/.emacs.d/themes when that dir exists"
done

pass "the editor hooks install only for editors that are present and say when a restart is needed"
