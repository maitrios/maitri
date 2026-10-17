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
    ("urlbarview-text-color-hover", "urlbarView-hover-background"),
    ("urlbarView-url-color", "toolbar-field-background-color-focus"),
    ("urlbarView-url-color", "urlbarView-hover-background"),
    ("link-color", "urlbarView-hover-background"),
    ("urlbarView-secondary-text-color", "toolbar-field-background-color-focus"),
    ("urlbarView-secondary-text-color", "urlbarView-hover-background"),
    ("urlbarView-secondary-text-color", "urlbarView-highlight-background"),
    ("urlbarView-action-color", "urlbarView-highlight-background"),
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
    ("toolbox-text-color", "toolbox-textcolor"),
    ("zen-main-browser-background", "zen-main-browser-background-old"),
    ("urlbarView-highlight-background", "urlbarview-background-color-selected"),
    ("urlbarView-highlight-color", "urlbarview-text-color-selected"),
    ("urlbarView-hover-background", "urlbarview-background-color-hover"),
    ("urlbarView-secondary-text-color", "urlbarview-text-color-secondary"),
    ("urlbarView-action-color", "urlbarview-text-color-action"),
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
    v = {k[2:]: val.lower() for k, val in block(rules, None, ":root, .smartbar").items() if k.startswith("--")}
    chrome.expect(block(rules, None, ":root, .smartbar").get("color-scheme") == mode, "color-scheme does not follow the theme mode")
    for fg, bg in CHROME_TEXT:
        chrome.floor(f"--{fg} on --{bg}", v.get(fg), v.get(bg))
    for fg, bg in CHROME_LINE:
        chrome.floor(f"--{fg} on --{bg}", v.get(fg), v.get(bg), LINE)
    menus = block(rules, None, ":is(menupopup, panel)")
    chrome.floor("context menu text", menus.get("--panel-text-color"), menus.get("--panel-background-color"))
    chrome.floor("context menu border", menus.get("--panel-border-color"), menus.get("--panel-background-color"), LINE)
    space = block(rules, None, "zen-workspace")
    chrome.floor("Zen space text", space.get("--toolbox-textcolor"), v.get("zen-main-browser-background"))
    chrome.floor("Zen space accent", space.get("--zen-primary-color"), v.get("zen-main-browser-background"), LINE)
    chrome.expect(space.get("color-scheme") == mode, "Zen spaces do not follow the theme mode")
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

    reader_body = block(rules, "about:reader", f"body.{mode}")
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
        selector = (f"body.{mode} :is(.header > h1, .moz-reader-content h1)" if level == 1
                    else f"body.{mode} .moz-reader-content h{level}")
        decl = block(rules, "about:reader", selector)
        color = decl.get("color", "").lower()
        content.expect(color == heading[level - 1], f"reader H{level} is {color}, expected {heading[level - 1]}")
        content.expect(decl.get("font-weight") == "bold", f"reader H{level} is not bold")
        content.floor(f"reader H{level}", color, bg)
    meta = block(rules, "about:reader", f"body.{mode} :is(.credits, .meta-data, .reader-estimated-time, .domain, figcaption, .wp-caption-text)")
    content.expect(meta["color"].lower() == p["comment"], "reader metadata is not comment")
    content.floor("reader metadata", meta["color"], bg)
    code = block(rules, "about:reader", f"body.{mode} .moz-reader-content code")["color"]
    content.floor("reader inline code", code, bg)
    pre = block(rules, "about:reader", f"body.{mode} .moz-reader-content pre")
    pre_code = block(rules, "about:reader", f"body.{mode} .moz-reader-content pre code")["color"]
    content.floor("reader code block", pre_code, pre["background-color"])
    content.floor("reader code block border", pre["border"].split()[-1], bg, LINE)
    quote = block(rules, "about:reader", f"body.{mode} .moz-reader-content blockquote")
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
for tool in awk bash cat cmp cp dirname env find flock grep jq mkdir mktemp mv python3 readlink realpath rm sed setsid sleep sort tail tr uname; do
  ln -s "$(command -v "$tool")" "$tools/$tool"
done

# Stand-ins for a running browser: the hook only counts a process whose
# executable is named like the browser's.
fake="$test_tmp/fake"
mkdir -p "$fake"
cp "$(command -v sleep)" "$fake/helium"
cp "$(command -v sleep)" "$fake/chrome"

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
mkdir -p "$fx_root/abc.default/chrome" "$fx_root/themed/chrome" "$fx_root/stowed" "$elsewhere" "$test_tmp/dotfiles-chrome-dir"
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

[Profile3]
Name=stowed
IsRelative=1
Path=stowed

[Install4F96D1932A9F858E]
Default=abc.default
INI
printf 'user_pref("browser.startup.page", 3);\nuser_pref("toolkit.legacyUserProfileCustomizations.stylesheets", false);\n' >"$fx_root/abc.default/user.js"
printf '#nav-bar { min-height: 40px; }\n' >"$fx_root/abc.default/chrome/userChrome.css"
printf '#main { color: blue; }\n' >"$test_tmp/dotfiles-userContent.css"
ln -s "$test_tmp/dotfiles-userContent.css" "$fx_root/abc.default/chrome/userContent.css"
printf 'user_pref("extensions.activeThemeID", "firefox-alpenglow@mozilla.org");\n' >"$fx_root/themed/prefs.js"
printf '@import url("maitri-userChrome.css");\n#tabbrowser-tabs { color: red; }\n' >"$fx_root/themed/chrome/userChrome.css"
printf 'stale\n' >"$fx_root/themed/chrome/maitri-userChrome.css"
printf '// user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);' >"$elsewhere/user.js"
printf '#nav-bar { min-height: 32px; }\n' >"$test_tmp/dotfiles-chrome-dir/userChrome.css"
ln -s "$test_tmp/dotfiles-chrome-dir" "$fx_root/stowed/chrome"
ln -s "127.0.0.1:+4242" "$elsewhere/lock"

zen_profile="$fx_home/.zen/xyz.Default (release)"
zen_accent="$fx_home/.zen/accent"
mkdir -p "$zen_profile/chrome" "$zen_accent"
: >"$zen_profile/chrome/userChrome.css"
printf 'user_pref("zen.theme.accent-color", "AccentColor");\n' >"$zen_profile/prefs.js"
printf 'user_pref("zen.theme.accent-color", "#ffb787");\n' >"$zen_accent/prefs.js"
printf '[Profile0]\nName=Default (release)\nIsRelative=1\nPath=xyz.Default (release)\n\n[Profile1]\nName=accent\nIsRelative=1\nPath=accent\n' >"$fx_home/.zen/profiles.ini"

run_hook "$fx_home" "$fx_stubs" maitri-theme-set-firefox 2>"$test_tmp/fx-stderr"

current="$fx_home/.local/state/maitri/current/theme"
marked='user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true); // maitri'
for profile in "$fx_root/abc.default" "$elsewhere" "$zen_profile"; do
  for part in userChrome userContent; do
    cmp -s "$current/firefox-$part.css" "$profile/chrome/maitri-$part.css" ||
      fail "the rendered $part.css lands in $(basename "$profile")" "$(cat "$test_tmp/fx-stderr")"
    [[ $profile/chrome/$part.css == "$fx_root/abc.default/chrome/userContent.css" ]] && continue
    head -n 1 "$profile/chrome/$part.css" | grep -qxF "@import url(\"maitri-$part.css\");" ||
      fail "$part.css in $(basename "$profile") imports maitri's stylesheet first"
  done
  [[ $profile == "$fx_root/abc.default" ]] && continue
  grep -qxF "$marked" "$profile/user.js" ||
    fail "user.js in $(basename "$profile") turns on userChrome.css with a marked line" "$(cat "$profile/user.js")"
done
pass "every Firefox and Zen profile on a built-in theme gets maitri's stylesheets"

grep -qxF '#nav-bar { min-height: 40px; }' "$fx_root/abc.default/chrome/userChrome.css" ||
  fail "an existing userChrome.css keeps its own rules"
grep -qxF 'user_pref("browser.startup.page", 3);' "$fx_root/abc.default/user.js" ||
  fail "user.js keeps the other prefs"
(( $(grep -c 'legacyUserProfileCustomizations' "$fx_root/abc.default/user.js") == 1 )) ||
  fail "user.js sets the stylesheet pref once"
pass "an existing userChrome.css and user.js are added to, not replaced"

grep -qxF 'user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", false);' "$fx_root/abc.default/user.js" ||
  fail "a user's explicit false in user.js is kept" "$(cat "$fx_root/abc.default/user.js")"
grep -qF "abc.default/user.js sets toolkit.legacyUserProfileCustomizations.stylesheets to false" "$test_tmp/fx-stderr" ||
  fail "a user's explicit false is reported" "$(cat "$test_tmp/fx-stderr")"
pass "a user who turned the stylesheet pref off keeps it off and is told why"

[[ -L $fx_root/stowed/chrome ]] || fail "a symlinked chrome folder stays a symlink"
[[ $(ls "$test_tmp/dotfiles-chrome-dir") == "userChrome.css" ]] || fail "nothing is written into a symlinked chrome folder" "$(ls "$test_tmp/dotfiles-chrome-dir")"
[[ $(cat "$test_tmp/dotfiles-chrome-dir/userChrome.css") == '#nav-bar { min-height: 32px; }' ]] || fail "a userChrome.css in a symlinked chrome folder is not edited"
grep -qF "stowed/chrome is a symlink, so maitri left it alone" "$test_tmp/fx-stderr" ||
  fail "a symlinked chrome folder is reported" "$(cat "$test_tmp/fx-stderr")"
grep -qxF "$marked" "$fx_root/stowed/user.js" || fail "a profile with a symlinked chrome folder still gets the stylesheet pref"
pass "a chrome folder linked from the user's dotfiles is left alone and reported"

[[ -L $fx_root/abc.default/chrome/userContent.css ]] || fail "a symlinked userContent.css stays a symlink"
[[ $(cat "$test_tmp/dotfiles-userContent.css") == '#main { color: blue; }' ]] || fail "maitri does not write through a symlinked userContent.css"
grep -qF "chrome/userContent.css is a symlink, so maitri left it alone" "$test_tmp/fx-stderr" ||
  fail "a symlinked userContent.css is reported" "$(cat "$test_tmp/fx-stderr")"
pass "a symlinked stylesheet from the user's dotfiles is left alone and reported"

[[ ! -e $fx_root/themed/chrome/maitri-userChrome.css ]] || fail "a profile with its own Firefox theme loses maitri's stylesheet"
! grep -qF 'maitri-userChrome.css' "$fx_root/themed/chrome/userChrome.css" || fail "a profile with its own Firefox theme loses the import"
grep -qxF '#tabbrowser-tabs { color: red; }' "$fx_root/themed/chrome/userChrome.css" || fail "a profile with its own Firefox theme keeps its rules"
[[ ! -e $fx_root/themed/user.js ]] || fail "a profile with its own Firefox theme gets no user.js"
[[ ! -e $zen_accent/chrome && ! -e $zen_accent/user.js ]] || fail "a Zen profile with its own accent is left alone"
pass "a profile with its own Firefox theme or Zen accent keeps it"

grep -qx 'Firefox is open, so restart it to pick up the new theme.' "$test_tmp/fx-stderr" ||
  fail "an open Firefox is told to restart" "$(cat "$test_tmp/fx-stderr")"
! grep -q 'Zen' "$test_tmp/fx-stderr" || fail "a closed Zen is not told to restart"
pass "only a running browser is asked to restart"

cp -r "$fx_root/abc.default" "$test_tmp/abc-before"
cp -a "$elsewhere" "$test_tmp/elsewhere-before"
run_hook "$fx_home" "$fx_stubs" maitri-theme-set-firefox 2>"$test_tmp/fx-stderr"
diff -r "$test_tmp/abc-before" "$fx_root/abc.default" >/dev/null || fail "running the Firefox hook again changes nothing"
diff -r --no-dereference "$test_tmp/elsewhere-before" "$elsewhere" >/dev/null || fail "running the Firefox hook again leaves an open profile alone"
! grep -q 'is open' "$test_tmp/fx-stderr" || fail "an open Firefox isn't told to restart when nothing changed" "$(cat "$test_tmp/fx-stderr")"
pass "the Firefox hook is idempotent and quiet when nothing changed"

bare_stubs="$test_tmp/no-browsers"
mkdir -p "$bare_stubs"
fresh_home="$test_tmp/firefox-absent"
mkdir -p "$fresh_home/run" "$fresh_home/.mozilla/firefox/p.default"
printf '[Profile0]\nIsRelative=1\nPath=p.default\n' >"$fresh_home/.mozilla/firefox/profiles.ini"
activate_theme amethyst "$fresh_home"
run_hook "$fresh_home" "$bare_stubs" maitri-theme-set-firefox
[[ ! -e $fresh_home/.mozilla/firefox/p.default/chrome ]] || fail "Firefox profiles are left alone when Firefox is not installed"
pass "nothing is written for a browser that is not installed"

echo hostile >"$fresh_home/.local/state/maitri/current/theme.name"
mkdir -p "$fresh_home/.config/maitri/themes/hostile/.git"
sed -i 's/^foreground = .*/foreground = "transparent"/' "$fresh_home/.local/state/maitri/current/theme/colors.toml"
run_hook "$fresh_home" "$fx_stubs" maitri-theme-set-firefox 2>"$test_tmp/fx-stderr"
[[ ! -e $fresh_home/.mozilla/firefox/p.default/chrome ]] || fail "a cloned theme with a colour that isn't #rrggbb is not installed"
grep -qF "has a colour that isn't #rrggbb" "$test_tmp/fx-stderr" || fail "a cloned theme's bad colour is reported" "$(cat "$test_tmp/fx-stderr")"
pass "a theme cloned from git only reaches Firefox with plain colours"

rm -rf "$fresh_home/.config/maitri/themes/hostile/.git"
run_hook "$fresh_home" "$fx_stubs" maitri-theme-set-firefox 2>/dev/null
[[ -f $fresh_home/.mozilla/firefox/p.default/chrome/maitri-userChrome.css ]] || fail "a theme the user wrote is trusted"
pass "a theme the user wrote is installed as it is"

# Chromium-family browsers.
cr_home="$test_tmp/chromium-home"
cr_stubs="$test_tmp/chromium-stubs"
stub_browsers "$cr_stubs" chromium helium
mkdir -p "$cr_home/run"
activate_theme amethyst "$cr_home"

host=$(uname -n)

cr_root="$cr_home/.config/chromium"
mkdir -p "$cr_root/Default" "$cr_root/Profile 1" "$cr_root/Profile 2" "$cr_root/Profile 3"
printf '{}\n' >"$cr_root/Local State"
printf '{"foo":{"bar":1},"browser":{"theme":{"color_scheme2":1}}}\n' >"$cr_root/Default/Preferences"
printf '{"extensions":{"theme":{"id":"user_color_theme_id"}},"browser":{"theme":{"user_color2":-16776961}}}\n' >"$cr_root/Profile 1/Preferences"
printf '{"extensions":{"theme":{"id":"autogenerated_theme_id"}},"autogenerated":{"theme":{"color":-15584170}}}\n' >"$cr_root/Profile 2/Preferences"
printf '{"browser":{"theme":{"is_grayscale2":true}}}\n' >"$cr_root/Profile 3/Preferences"
ln -s "$host-$$" "$cr_root/SingletonLock"

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
[[ ! -s $test_tmp/cr-stderr ]] || fail "a lock left by a crash, naming a process that isn't the browser, counts as closed" "$(cat "$test_tmp/cr-stderr")"

amethyst_bg=$(jq -r .BrowserThemeColor "$cr_home/.local/state/maitri/current/theme/chromium-policy.json")
prefs="$cr_root/Default/Preferences"
[[ $(jq -r '.extensions.theme.id' "$prefs") == "autogenerated_theme_id" ]] || fail "a default profile switches to a color theme" "$(cat "$prefs")"
[[ $(jq -r '.autogenerated.theme.color' "$prefs") == "$(skcolor "$amethyst_bg")" ]] || fail "a default profile takes the theme background" "$(cat "$prefs")"
[[ $(jq -r '.browser.theme.color_scheme2' "$prefs") == "1" ]] || fail "the profile keeps its own light or dark setting"
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
pass "a profile maitri colored follows the next theme change"

helium_root="$cr_home/.config/net.imput.helium"
mkdir -p "$helium_root/Default"
printf '{}\n' >"$helium_root/Local State"
printf '{}\n' >"$helium_root/Default/Preferences"
"$fake/helium" 60 <"$helium_root/Local State" &
helium_pid=$!
trap 'kill "$helium_pid" 2>/dev/null; rm -rf "$test_tmp"' EXIT
ln -s "$host-$helium_pid" "$helium_root/SingletonLock"

run_hook "$cr_home" "$cr_stubs" maitri-theme-set-chromium 2>"$test_tmp/cr-stderr"
grep -qx "Helium is open, so it picks up the new theme once it's closed and started again." "$test_tmp/cr-stderr" ||
  fail "an open Helium says when it picks up the theme" "$(cat "$test_tmp/cr-stderr")"
[[ $(jq -r '.extensions.theme.id // ""' "$helium_root/Default/Preferences") == "" ]] || fail "an open Helium's preferences are not written under it"

# Chromium drops its lock before its last write of Preferences, so it counts
# as closed only once nothing has a file open in its user data dir.
rm "$helium_root/SingletonLock"
sleep 3
[[ $(jq -r '.extensions.theme.id // ""' "$helium_root/Default/Preferences") == "" ]] || fail "Helium is not colored while its process is still shutting down"

kill "$helium_pid"
wait "$helium_pid" 2>/dev/null || true
for _ in $(seq 1 40); do
  [[ $(jq -r '.extensions.theme.id // ""' "$helium_root/Default/Preferences") == "autogenerated_theme_id" ]] && break
  sleep 0.25
done
[[ $(jq -r '.autogenerated.theme.color' "$helium_root/Default/Preferences") == "$(skcolor "$daybreak_bg")" ]] ||
  fail "Helium is colored once it closes" "$(cat "$helium_root/Default/Preferences")"
for _ in $(seq 1 20); do
  flock -n "$cr_home/.local/state/maitri/chromium-theme-waiter.lock" true && break
  sleep 0.25
done
flock -n "$cr_home/.local/state/maitri/chromium-theme-waiter.lock" true || fail "the waiter exits once every browser is colored"
pass "an open browser is colored after its process exits, without being restarted"

"$fake/helium" 60 <"$helium_root/Local State" &
helium_pid=$!
ln -sf "$host-$helium_pid" "$helium_root/SingletonLock"
run_hook "$cr_home" "$cr_stubs" maitri-theme-set-chromium 2>"$test_tmp/cr-stderr"
[[ ! -s $test_tmp/cr-stderr ]] || fail "an open browser with nothing to change gets no notice" "$(cat "$test_tmp/cr-stderr")"
pass "an open browser already on the theme color is not told to restart"

chrome_home="$test_tmp/chrome-home"
chrome_stubs="$test_tmp/chrome-stubs"
stub_browsers "$chrome_stubs" google-chrome-stable
mkdir -p "$chrome_home/run" "$chrome_home/.config" "$test_tmp/dotfiles-chrome/Default"
activate_theme amethyst "$chrome_home"
printf '{}\n' >"$test_tmp/dotfiles-chrome/Local State"
printf '{}\n' >"$test_tmp/dotfiles-chrome/Default/Preferences"
ln -s "$test_tmp/dotfiles-chrome" "$chrome_home/.config/google-chrome"
"$fake/chrome" 60 <"$test_tmp/dotfiles-chrome/Local State" &
chrome_pid=$!
trap 'kill "$helium_pid" "$chrome_pid" 2>/dev/null; rm -rf "$test_tmp"' EXIT

run_hook "$chrome_home" "$chrome_stubs" maitri-theme-set-chromium 2>"$test_tmp/cr-stderr"
grep -q "Chrome is open" "$test_tmp/cr-stderr" || fail "a browser behind a symlinked data dir counts as open" "$(cat "$test_tmp/cr-stderr")"
[[ $(jq -r '.extensions.theme.id // ""' "$test_tmp/dotfiles-chrome/Default/Preferences") == "" ]] ||
  fail "a browser behind a symlinked data dir is not written under"
kill "$chrome_pid"
wait "$chrome_pid" 2>/dev/null || true
for _ in $(seq 1 40); do
  [[ $(jq -r '.extensions.theme.id // ""' "$test_tmp/dotfiles-chrome/Default/Preferences") == "autogenerated_theme_id" ]] && break
  sleep 0.25
done
[[ $(jq -r '.extensions.theme.id // ""' "$test_tmp/dotfiles-chrome/Default/Preferences") == "autogenerated_theme_id" ]] ||
  fail "a browser behind a symlinked data dir is colored once it closes"
pass "a browser whose data dir is a symlink is detected and colored after it closes"

backup_home="$test_tmp/backup-home"
backup_stubs="$test_tmp/backup-stubs"
stub_browsers "$backup_stubs" chromium
mkdir -p "$backup_home/run" "$backup_home/.config/chromium/Default"
activate_theme amethyst "$backup_home"
printf '{}\n' >"$backup_home/.config/chromium/Local State"
printf '{}\n' >"$backup_home/.config/chromium/Default/Preferences"
sleep 60 <"$backup_home/.config/chromium/Local State" &
backup_pid=$!
trap 'kill "$helium_pid" "$chrome_pid" "$backup_pid" 2>/dev/null; rm -rf "$test_tmp"' EXIT
run_hook "$backup_home" "$backup_stubs" maitri-theme-set-chromium 2>"$test_tmp/cr-stderr"
kill "$backup_pid"
wait "$backup_pid" 2>/dev/null || true
[[ ! -s $test_tmp/cr-stderr ]] || fail "another process with a file open in the data dir doesn't count as the browser" "$(cat "$test_tmp/cr-stderr")"
[[ $(jq -r '.extensions.theme.id // ""' "$backup_home/.config/chromium/Default/Preferences") == "autogenerated_theme_id" ]] ||
  fail "a closed browser is colored while a backup reads its data dir"
pass "a backup or sync process reading the data dir doesn't hold the theme back"
