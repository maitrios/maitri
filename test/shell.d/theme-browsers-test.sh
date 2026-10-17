#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

require_command python3
require_command jq

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

render_theme() {
  local theme="$1"
  local home="$2"
  local next_theme="$home/.local/state/maitri/current/next-theme"

  rm -rf "$next_theme" "$home/.local/state/maitri/current/theme"
  mkdir -p "$next_theme"
  cp "$ROOT/themes/$theme/colors.toml" "$next_theme/colors.toml"
  HOME="$home" MAITRI_PATH="$ROOT" PATH="$ROOT/bin:$PATH" bash "$ROOT/bin/maitri-theme-set-templates"
}

themes=()
for theme_dir in "$ROOT"/themes/*/; do
  theme=$(basename "$theme_dir")
  home="$test_tmp/render/$theme"
  render_theme "$theme" "$home"
  next_theme="$home/.local/state/maitri/current/next-theme"
  MAITRI_PATH="$ROOT" PATH="$ROOT/bin:$PATH" maitri-theme-color --file "$next_theme/colors.toml" --all >"$home/palette.tsv"

  for file in firefox-userChrome.css firefox-userContent.css chromium-policy.json; do
    [[ -f $next_theme/$file ]] || fail "$theme renders $file"
    ! grep -q '{{' "$next_theme/$file" || fail "$theme leaves no placeholders in $file" "$(grep -n '{{' "$next_theme/$file")"
  done
  jq -e . "$next_theme/chromium-policy.json" >/dev/null || fail "$theme renders valid JSON for Chromium"
  themes+=("$theme")
done

(( ${#themes[@]} == 6 )) || fail "all six themes are rendered" "${themes[*]}"
pass "every theme renders the Firefox and Chromium templates"

python3 - "$test_tmp/render" "${themes[@]}" <<'PY'
import json, re, sys

root, themes = sys.argv[1], sys.argv[2:]
TEXT, LINE = 4.5, 3.0
failed = False
table = []


def rgb(color):
    color = color.strip().lstrip("#")
    return tuple(int(color[i:i + 2], 16) for i in (0, 2, 4))


def luminance(color):
    def channel(value):
        value /= 255
        return value / 12.92 if value <= 0.03928 else ((value + 0.055) / 1.055) ** 2.4
    r, g, b = rgb(color)
    return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)


def contrast(fg, bg):
    a, b = sorted((luminance(fg), luminance(bg)), reverse=True)
    return (a + 0.05) / (b + 0.05)


def mix(a, b, amount):
    return "#%02x%02x%02x" % tuple(int(x * (1 - amount) + y * amount + 0.5) for x, y in zip(rgb(a), rgb(b)))


def parse(text):
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    rules, stack, buffer = [], [], ""
    for char in text:
        if char == "{":
            stack.append(buffer.strip())
            buffer = ""
        elif char == "}":
            selector = stack.pop()
            if buffer.strip():
                declarations = {}
                for part in buffer.split(";"):
                    if ":" in part:
                        key, value = part.split(":", 1)
                        declarations[key.strip()] = value.replace("!important", "").strip()
                rules.append((tuple(stack), selector, declarations))
            buffer = ""
        else:
            buffer += char
    return rules


def block(rules, context, selector):
    for ctx, sel, declarations in rules:
        if (context is None or any(context in c for c in ctx)) and sel == selector:
            return declarations
    raise KeyError(f"{selector} in {context}")


class Check:
    def __init__(self, theme, app):
        self.theme, self.app = theme, app
        self.errors = []
        self.low = {TEXT: 99.0, LINE: 99.0}

    def floor(self, label, fg, bg, minimum=TEXT):
        if not fg or not bg:
            self.errors.append(f"{label}: missing color ({fg} on {bg})")
            return
        ratio = contrast(fg, bg)
        self.low[minimum] = min(self.low[minimum], ratio)
        if ratio < minimum:
            self.errors.append(f"{label}: {ratio:.2f}:1 ({fg} on {bg}), floor {minimum}:1")

    def expect(self, condition, message):
        if not condition:
            self.errors.append(message)

    def report(self):
        global failed
        name = f"{self.theme} {self.app}"
        if self.errors:
            failed = True
            print("\n".join(f"  {e}" for e in self.errors), file=sys.stderr)
            print(f"not ok - {name} meets the contrast floors and the shared mapping", file=sys.stderr)
        else:
            print(f"ok - {name} meets the contrast floors and the shared mapping")
        return self.low


CHROME_TEXT = [
    ("toolbox-text-color", "toolbox-background-color"),
    ("toolbox-text-color-inactive", "toolbox-background-color-inactive"),
    ("tab-text-color", "toolbox-background-color"),
    ("tab-text-color-selected", "tab-background-color-selected"),
    ("tab-text-color-hover", "tab-background-color-hover"),
    ("toolbar-text-color", "toolbar-background-color"),
    ("toolbar-field-text-color", "toolbar-field-background-color"),
    ("toolbar-field-text-color-focus", "toolbar-field-background-color-focus"),
    ("lwt-toolbar-field-highlight-text", "lwt-toolbar-field-highlight"),
    ("urlbarView-highlight-color", "urlbarView-highlight-background"),
    ("toolbar-field-text-color-focus", "urlbarView-hover-background"),
    ("urlbarView-url-color", "toolbar-field-background-color-focus"),
    ("urlbarView-secondary-text-color", "toolbar-field-background-color-focus"),
    ("panel-text-color", "panel-background-color"),
    ("panel-text-color", "panel-item-hover-bgcolor"),
    ("panel-text-color", "panel-item-active-bgcolor"),
    ("panel-description-color", "panel-background-color"),
    ("sidebar-text-color", "sidebar-background-color"),
    ("button-text-color-primary", "color-accent-primary"),
    ("button-text-color-primary-hover", "color-accent-primary-hover"),
    ("button-text-color-primary-active", "color-accent-primary-active"),
    ("link-color", "toolbar-background-color"),
    ("link-color", "panel-background-color"),
    ("newtab-text-primary-color", "newtab-background-color"),
    ("toolbox-text-color", "zen-main-browser-background"),
    ("zen-colors-primary-foreground", "zen-colors-primary"),
    ("zen-colors-primary-foreground", "zen-colors-secondary"),
    ("zen-colors-primary-foreground", "zen-toolbar-element-bg-hover"),
    ("toolbar-field-text-color", "zen-urlbar-background"),
    ("panel-text-color", "zen-dialog-background"),
]

CHROME_LINE = [
    ("toolbarbutton-icon-fill", "toolbar-background-color"),
    ("toolbarbutton-icon-fill-attention", "toolbar-background-color"),
    ("toolbar-field-border-color", "toolbar-background-color"),
    ("toolbar-field-border-color-focus", "toolbar-background-color"),
    ("toolbar-field-border-color-focus", "toolbar-field-background-color-focus"),
    ("focus-outline-color", "toolbar-background-color"),
    ("focus-outline-color", "panel-background-color"),
    ("panel-border-color", "panel-background-color"),
    ("sidebar-border-color", "sidebar-background-color"),
    ("chrome-content-separator-color", "toolbar-background-color"),
    ("tabs-navbar-separator-color", "toolbox-background-color"),
    ("tab-border-color-selected", "toolbox-background-color"),
    ("tab-loading-fill", "toolbox-background-color"),
    ("color-accent-primary", "toolbar-background-color"),
    ("color-accent-primary", "panel-background-color"),
    ("zen-primary-color", "zen-main-browser-background"),
    ("zen-colors-border", "zen-main-browser-background"),
]

RENAMED = [
    ("toolbar-background-color", "toolbar-bgcolor"),
    ("toolbar-text-color", "toolbar-color"),
    ("tab-background-color-selected", "tab-selected-bgcolor"),
    ("tab-text-color-selected", "tab-selected-textcolor"),
    ("tab-background-color-hover", "tab-hover-background-color"),
    ("toolbar-field-text-color", "toolbar-field-color"),
    ("toolbar-field-background-color-focus", "toolbar-field-focus-background-color"),
    ("toolbar-field-text-color-focus", "toolbar-field-focus-color"),
    ("toolbar-field-border-color-focus", "toolbar-field-focus-border-color"),
    ("panel-background-color", "arrowpanel-background"),
    ("panel-text-color", "arrowpanel-color"),
    ("panel-border-color", "arrowpanel-border-color"),
    ("toolbox-background-color", "lwt-accent-color"),
    ("toolbox-text-color", "lwt-text-color"),
    ("urlbarView-url-color", "urlbar-popup-url-color"),
]

for theme in themes:
    out = f"{root}/{theme}/.local/state/maitri/current/next-theme"
    palette = dict(line.rstrip("\n").split("\t", 1) for line in open(f"{root}/{theme}/palette.tsv"))
    p = {k: v.lower() for k, v in palette.items() if re.fullmatch(r"#[0-9A-Fa-f]{6}", v)}
    mode = palette["mode"]
    heading = [mix(p["accent"], p["foreground"], n * 0.13) for n in range(6)]
    row = {"theme": theme}

    chrome = Check(theme, "firefox userChrome")
    rules = parse(open(f"{out}/firefox-userChrome.css").read())
    v = {k[2:]: val.lower() for k, val in block(rules, None, ":root").items() if k.startswith("--")}
    chrome.expect(block(rules, None, ":root").get("color-scheme") == mode, "color-scheme does not follow the theme mode")
    for fg, bg in CHROME_TEXT:
        chrome.floor(f"--{fg} on --{bg}", v.get(fg), v.get(bg))
    for fg, bg in CHROME_LINE:
        chrome.floor(f"--{fg} on --{bg}", v.get(fg), v.get(bg), LINE)
    for new, old in RENAMED:
        chrome.expect(v.get(new) and v.get(new) == v.get(old), f"--{old} does not match --{new}")
    chrome.expect(v.get("toolbar-background-color") == p["background"], "the toolbar is not the theme background")
    chrome.expect(v.get("color-accent-primary") == p["accent"], "the chrome accent is not the theme accent")
    chrome.expect(v.get("toolbar-field-border-color") == p["border"], "the URL bar border is not border")
    chrome.expect(v.get("toolbar-field-border-color-focus") == p["border_focus"], "the focused URL bar border is not border_focus")
    chrome.expect(v.get("lwt-toolbar-field-highlight") == p["selection"], "the URL bar selection is not selection")
    chrome.expect(v.get("link-color") == p["link"], "links are not link")
    chrome.expect(v.get("icon-color-warning") == p["orange"] and v.get("icon-color-critical") == p["red"], "warnings and errors are not orange and red")
    row["userChrome"] = chrome.report()

    content = Check(theme, "firefox userContent")
    rules = parse(open(f"{out}/firefox-userContent.css").read())
    nt = {k[2:]: val.lower() for k, val in block(rules, "about:newtab", ":root").items() if k.startswith("--")}
    for fg in ("newtab-text-primary-color", "newtab-text-secondary-color"):
        for bg in ("newtab-background-color", "newtab-background-color-secondary", "newtab-element-hover-color"):
            content.floor(f"new tab --{fg} on --{bg}", nt.get(fg), nt.get(bg))
    content.floor("new tab primary button text", nt.get("newtab-primary-element-text-color"), nt.get("newtab-primary-action-background"))
    content.floor("new tab --newtab-border-color", nt.get("newtab-border-color"), nt.get("newtab-background-color"), LINE)
    content.floor("new tab focused search box", nt.get("newtab-textbox-focus-color"), nt.get("newtab-textbox-background-color"), LINE)
    content.floor("new tab primary action", nt.get("newtab-primary-action-background"), nt.get("newtab-background-color"), LINE)

    reader_body = block(rules, "about:reader", "body:is(.light, .dark)")
    rd = {k[2:]: val.lower() for k, val in reader_body.items() if k.startswith("--")}
    bg = rd["main-background"]
    content.expect(bg == p["background"], "reader view background is not the theme background")
    for name in ("main-foreground", "link-foreground", "visited-link-foreground"):
        content.floor(f"reader --{name}", rd.get(name), bg)
    content.floor("reader selection", rd.get("text-selected-foreground"), rd.get("text-selected-background"))
    content.floor("reader popup", rd.get("popup-foreground"), rd.get("popup-background"))
    content.floor("reader tooltip", rd.get("tooltip-foreground"), rd.get("tooltip-background"))
    content.floor("reader --popup-border", rd.get("popup-border"), rd.get("popup-background"), LINE)
    content.floor("reader --toolbar-border", rd.get("toolbar-border"), bg, LINE)
    content.floor("reader --icon-fill", rd.get("icon-fill"), bg, LINE)
    content.expect(rd.get("link-foreground") == p["link"], "reader links are not link")
    for level in range(1, 7):
        selector = ("body:is(.light, .dark) :is(.header > h1, .moz-reader-content h1)" if level == 1
                    else f"body:is(.light, .dark) .moz-reader-content h{level}")
        decl = block(rules, "about:reader", selector)
        color = decl.get("color", "").lower()
        content.expect(color == heading[level - 1], f"reader H{level} is {color}, expected {heading[level - 1]}")
        content.expect(decl.get("font-weight") == "bold", f"reader H{level} is not bold")
        content.floor(f"reader H{level}", color, bg)
    meta = block(rules, "about:reader", "body:is(.light, .dark) :is(.credits, .meta-data, .reader-estimated-time, .domain, figcaption, .wp-caption-text)")
    content.expect(meta["color"].lower() == p["comment"], "reader metadata is not comment")
    content.floor("reader metadata", meta["color"], bg)
    code = block(rules, "about:reader", "body:is(.light, .dark) .moz-reader-content code")["color"]
    content.floor("reader inline code", code, bg)
    pre = block(rules, "about:reader", "body:is(.light, .dark) .moz-reader-content pre")
    pre_code = block(rules, "about:reader", "body:is(.light, .dark) .moz-reader-content pre code")["color"]
    content.floor("reader code block", pre_code, pre["background-color"])
    content.floor("reader code block border", pre["border"].split()[-1], bg, LINE)
    quote = block(rules, "about:reader", "body:is(.light, .dark) .moz-reader-content blockquote")
    content.floor("reader quote", quote["color"], bg)
    content.floor("reader quote border", quote["border-inline-start-color"], bg, LINE)

    vs_bg = block(rules, "view-source:", "#viewsource")["background-color"].lower()
    expected = {
        "#viewsource": ("light_foreground", None),
        "#viewsource span[id]::before": ("comment", None),
        "#viewsource :is(.start-tag, .end-tag)": ("cyan", None),
        "#viewsource .attribute-name": ("green", "italic"),
        "#viewsource .attribute-value": ("yellow", None),
        "#viewsource .comment": ("comment", "italic"),
        "#viewsource :is(.doctype, .markupdeclaration, .pi)": ("magenta", None),
        "#viewsource :is(.entity, .cdata)": ("magenta", None),
        "#viewsource .text": ("foreground", None),
        "#viewsource .error": ("red", None),
    }
    for selector, (role, style) in expected.items():
        decl = block(rules, "view-source:", selector)
        color = decl["color"].lower()
        content.expect(color == p[role], f"view-source {selector} is {color}, expected {role}")
        if style:
            content.expect(decl.get("font-style") == style, f"view-source {selector} is not {style}")
        content.floor(f"view-source {selector}", color, vs_bg)
    selection = block(rules, "view-source:", "::selection")
    content.floor("view-source selection", selection["color"], selection["background-color"])
    row["userContent"] = content.report()

    chromium = Check(theme, "chromium")
    seed = json.load(open(f"{out}/chromium-policy.json"))["BrowserThemeColor"].lower()
    chromium.expect(seed == p["background"], f"BrowserThemeColor is {seed}, not the theme background")
    # Chromium draws frame and toolbar text in white or #202124, whichever
    # stands out more from the frame color.
    chromium.floor("Chromium's frame text", max(("#ffffff", "#202124"), key=lambda c: contrast(c, seed)), seed)
    row["chromium"] = chromium.report()
    table.append(row)

print("# lowest text / lowest line ratio per rendered file")
print("# " + " | ".join(["app"] + themes))
for app in ("userChrome", "userContent", "chromium"):
    cells = []
    for row in table:
        low = row[app]
        line = f"{low[LINE]:.2f}" if low[LINE] < 99 else "-"
        cells.append(f"{low[TEXT]:.2f} / {line}")
    print("# " + " | ".join([app] + cells))

sys.exit(1 if failed else 0)
PY

# Commands the hooks run, without whatever browsers this machine has installed.
tools="$test_tmp/tools"
mkdir -p "$tools"
for tool in awk bash cat cp dirname env flock grep jq mkdir mktemp mv python3 readlink rm sed setsid sleep sort tail; do
  ln -s "$(command -v "$tool")" "$tools/$tool"
done

stub_browsers() {
  local dir="$1"
  shift

  mkdir -p "$dir"
  for browser in "$@"; do
    printf '#!/bin/bash\n' >"$dir/$browser"
    chmod +x "$dir/$browser"
  done
}

run_hook() {
  local home="$1"
  local stubs="$2"
  shift 2

  HOME="$home" XDG_RUNTIME_DIR="$home/run" MAITRI_PATH="$ROOT" PATH="$stubs:$ROOT/bin:$tools" "$@"
}

activate_theme() {
  local theme="$1"
  local home="$2"

  render_theme "$theme" "$home"
  mv "$home/.local/state/maitri/current/next-theme" "$home/.local/state/maitri/current/theme"
}

# Firefox and Zen.
fx_home="$test_tmp/firefox-home"
fx_stubs="$test_tmp/firefox-stubs"
stub_browsers "$fx_stubs" firefox zen-browser
mkdir -p "$fx_home/run"
activate_theme amethyst "$fx_home"

fx_root="$fx_home/.mozilla/firefox"
elsewhere="$test_tmp/elsewhere-profile"
mkdir -p "$fx_root/abc.default/chrome" "$fx_root/themed/chrome" "$elsewhere"
cat >"$fx_root/profiles.ini" <<INI
[General]
StartWithLastProfile=1

[Profile0]
Name=default
IsRelative=1
Path=abc.default
Default=1

[Profile1]
Name=elsewhere
IsRelative=0
Path=$elsewhere

[Profile2]
Name=themed
IsRelative=1
Path=themed

[Install4F96D1932A9F858E]
Default=abc.default
INI
printf 'user_pref("browser.startup.page", 3);\nuser_pref("toolkit.legacyUserProfileCustomizations.stylesheets", false);\n' >"$fx_root/abc.default/user.js"
printf '#nav-bar { min-height: 40px; }\n' >"$fx_root/abc.default/chrome/userChrome.css"
printf 'user_pref("extensions.activeThemeID", "firefox-alpenglow@mozilla.org");\n' >"$fx_root/themed/prefs.js"
printf '@import url("maitri-userChrome.css");\n#tabbrowser-tabs { color: red; }\n' >"$fx_root/themed/chrome/userChrome.css"
printf 'stale\n' >"$fx_root/themed/chrome/maitri-userChrome.css"
ln -s "127.0.0.1:+4242" "$elsewhere/lock"

zen_profile="$fx_home/.zen/xyz.Default (release)"
mkdir -p "$zen_profile"
printf '[Profile0]\nName=Default (release)\nIsRelative=1\nPath=xyz.Default (release)\n' >"$fx_home/.zen/profiles.ini"

run_hook "$fx_home" "$fx_stubs" maitri-theme-set-firefox 2>"$test_tmp/fx-stderr"

current="$fx_home/.local/state/maitri/current/theme"
for profile in "$fx_root/abc.default" "$elsewhere" "$zen_profile"; do
  for part in userChrome userContent; do
    cmp -s "$current/firefox-$part.css" "$profile/chrome/maitri-$part.css" ||
      fail "the rendered $part.css lands in $(basename "$profile")"
    head -n 1 "$profile/chrome/$part.css" | grep -qxF "@import url(\"maitri-$part.css\");" ||
      fail "$part.css in $(basename "$profile") imports maitri's stylesheet first"
  done
  grep -qxF 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' "$profile/user.js" ||
    fail "user.js in $(basename "$profile") turns on userChrome.css"
done
pass "every Firefox and Zen profile on a built-in theme gets maitri's stylesheets"

grep -qxF '#nav-bar { min-height: 40px; }' "$fx_root/abc.default/chrome/userChrome.css" ||
  fail "an existing userChrome.css keeps its own rules"
grep -qxF 'user_pref("browser.startup.page", 3);' "$fx_root/abc.default/user.js" ||
  fail "user.js keeps the other prefs"
(( $(grep -c 'legacyUserProfileCustomizations' "$fx_root/abc.default/user.js") == 1 )) ||
  fail "user.js sets the stylesheet pref once"
pass "an existing userChrome.css and user.js are added to, not replaced"

[[ ! -e $fx_root/themed/chrome/maitri-userChrome.css ]] || fail "a profile with its own Firefox theme loses maitri's stylesheet"
! grep -qF 'maitri-userChrome.css' "$fx_root/themed/chrome/userChrome.css" || fail "a profile with its own Firefox theme loses the import"
grep -qxF '#tabbrowser-tabs { color: red; }' "$fx_root/themed/chrome/userChrome.css" || fail "a profile with its own Firefox theme keeps its rules"
[[ ! -e $fx_root/themed/user.js ]] || fail "a profile with its own Firefox theme gets no user.js"
pass "a profile with its own Firefox theme keeps it"

grep -qx 'Firefox is open, so restart it to pick up the new theme.' "$test_tmp/fx-stderr" ||
  fail "an open Firefox is told to restart" "$(cat "$test_tmp/fx-stderr")"
! grep -q 'Zen' "$test_tmp/fx-stderr" || fail "a closed Zen is not told to restart"
pass "only a running browser is asked to restart"

cp -r "$fx_root/abc.default" "$test_tmp/abc-before"
run_hook "$fx_home" "$fx_stubs" maitri-theme-set-firefox 2>/dev/null
diff -r "$test_tmp/abc-before" "$fx_root/abc.default" >/dev/null || fail "running the Firefox hook again changes nothing"
pass "the Firefox hook is idempotent"

bare_stubs="$test_tmp/no-browsers"
mkdir -p "$bare_stubs"
fresh_home="$test_tmp/firefox-absent"
mkdir -p "$fresh_home/run" "$fresh_home/.mozilla/firefox/p.default"
printf '[Profile0]\nIsRelative=1\nPath=p.default\n' >"$fresh_home/.mozilla/firefox/profiles.ini"
activate_theme amethyst "$fresh_home"
run_hook "$fresh_home" "$bare_stubs" maitri-theme-set-firefox
[[ ! -e $fresh_home/.mozilla/firefox/p.default/chrome ]] || fail "Firefox profiles are left alone when Firefox is not installed"
pass "nothing is written for a browser that is not installed"

# Chromium-family browsers.
cr_home="$test_tmp/chromium-home"
cr_stubs="$test_tmp/chromium-stubs"
stub_browsers "$cr_stubs" chromium helium
mkdir -p "$cr_home/run"
activate_theme amethyst "$cr_home"

cr_root="$cr_home/.config/chromium"
mkdir -p "$cr_root/Default" "$cr_root/Profile 1" "$cr_root/Profile 2" "$cr_root/Profile 3"
printf '{}\n' >"$cr_root/Local State"
printf '{"foo":{"bar":1},"browser":{"theme":{"color_scheme2":0}}}\n' >"$cr_root/Default/Preferences"
printf '{"extensions":{"theme":{"id":"user_color_theme_id"}},"browser":{"theme":{"user_color2":-16776961}}}\n' >"$cr_root/Profile 1/Preferences"
printf '{"extensions":{"theme":{"id":"autogenerated_theme_id"}},"autogenerated":{"theme":{"color":-15584170}}}\n' >"$cr_root/Profile 2/Preferences"
printf '{"browser":{"theme":{"is_grayscale2":true}}}\n' >"$cr_root/Profile 3/Preferences"

chrome_root="$cr_home/.config/google-chrome"
mkdir -p "$chrome_root/Default"
printf '{}\n' >"$chrome_root/Local State"
printf '{}\n' >"$chrome_root/Default/Preferences"

skcolor() {
  python3 -c 'import sys; v = 0xFF000000 | int(sys.argv[1].lstrip("#"), 16); print(v - (1 << 32))' "$1"
}

cp "$cr_root/Profile 1/Preferences" "$test_tmp/p1"
cp "$cr_root/Profile 2/Preferences" "$test_tmp/p2"
cp "$cr_root/Profile 3/Preferences" "$test_tmp/p3"

run_hook "$cr_home" "$cr_stubs" maitri-theme-set-chromium 2>"$test_tmp/cr-stderr"
[[ ! -s $test_tmp/cr-stderr ]] || fail "a closed Chromium needs no restart notice" "$(cat "$test_tmp/cr-stderr")"

amethyst_bg=$(jq -r .BrowserThemeColor "$cr_home/.local/state/maitri/current/theme/chromium-policy.json")
prefs="$cr_root/Default/Preferences"
[[ $(jq -r '.extensions.theme.id' "$prefs") == "autogenerated_theme_id" ]] || fail "a default profile switches to a color theme" "$(cat "$prefs")"
[[ $(jq -r '.autogenerated.theme.color' "$prefs") == "$(skcolor "$amethyst_bg")" ]] || fail "a default profile takes the theme background" "$(cat "$prefs")"
[[ $(jq -r '.browser.theme.color_scheme2' "$prefs") == "2" ]] || fail "a dark theme puts the profile in dark mode"
[[ $(jq -r '.foo.bar' "$prefs") == "1" ]] || fail "the profile keeps its other preferences"
pass "a Chromium profile on the default theme takes the theme color"

cmp -s "$test_tmp/p1" "$cr_root/Profile 1/Preferences" || fail "a profile with its own Chrome color keeps it"
cmp -s "$test_tmp/p2" "$cr_root/Profile 2/Preferences" || fail "a profile with a color maitri never wrote keeps it"
cmp -s "$test_tmp/p3" "$cr_root/Profile 3/Preferences" || fail "a grayscale profile keeps it"
[[ $(jq -r '.extensions.theme.id // ""' "$chrome_root/Default/Preferences") == "" ]] || fail "Chrome is left alone when it is not installed"
pass "profiles with their own colors, and browsers that are not installed, are left alone"

activate_theme daybreak "$cr_home"
run_hook "$cr_home" "$cr_stubs" maitri-theme-set-chromium
daybreak_bg=$(jq -r .BrowserThemeColor "$cr_home/.local/state/maitri/current/theme/chromium-policy.json")
[[ $(jq -r '.autogenerated.theme.color' "$prefs") == "$(skcolor "$daybreak_bg")" ]] || fail "a color maitri wrote follows the next theme"
[[ $(jq -r '.browser.theme.color_scheme2' "$prefs") == "1" ]] || fail "a light theme puts the profile in light mode"
pass "a profile maitri colored follows the next theme change"

helium_root="$cr_home/.config/net.imput.helium"
mkdir -p "$helium_root/Default"
printf '{}\n' >"$helium_root/Local State"
printf '{}\n' >"$helium_root/Default/Preferences"
ln -s "andrew-box-4242" "$helium_root/SingletonLock"

run_hook "$cr_home" "$cr_stubs" maitri-theme-set-chromium 2>"$test_tmp/cr-stderr"
grep -qx "Helium is open, so it picks up the new theme once it's closed and started again." "$test_tmp/cr-stderr" ||
  fail "an open Helium says when it picks up the theme" "$(cat "$test_tmp/cr-stderr")"
[[ $(jq -r '.extensions.theme.id // ""' "$helium_root/Default/Preferences") == "" ]] || fail "an open Helium's preferences are not written under it"

rm "$helium_root/SingletonLock"
for _ in $(seq 1 40); do
  [[ $(jq -r '.extensions.theme.id // ""' "$helium_root/Default/Preferences") == "autogenerated_theme_id" ]] && break
  sleep 0.25
done
[[ $(jq -r '.autogenerated.theme.color' "$helium_root/Default/Preferences") == "$(skcolor "$daybreak_bg")" ]] ||
  fail "Helium is colored once it closes" "$(cat "$helium_root/Default/Preferences")"
for _ in $(seq 1 20); do
  flock -n "$cr_home/run/maitri-theme-set-chromium.lock" true && break
  sleep 0.25
done
flock -n "$cr_home/run/maitri-theme-set-chromium.lock" true || fail "the waiter exits once every browser is colored"
pass "an open browser is colored after it closes, without being restarted"
