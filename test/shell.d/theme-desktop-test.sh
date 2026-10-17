#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

require_command python3

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

RENDERED=(hyprland.lua shell.toml vicinae.toml hyprland-preview-share-picker.css)

cat >"$test_tmp/contrast.py" <<'PY'
import re, sys, tomllib

theme_dir, colors_file, vicinae_file, mode = sys.argv[1:5]

def channel(c):
    c /= 255
    return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4

def rgb(color):
    h = color.lstrip("#")
    return [int(h[i:i + 2], 16) for i in (0, 2, 4)]

def luminance(color):
    r, g, b = rgb(color)
    return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)

def contrast(a, b):
    la, lb = sorted((luminance(a), luminance(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)

def norm(value):
    value = value.strip().strip("'\"")
    m = re.fullmatch(r"rgba?\(([0-9A-Fa-f]{6})([0-9A-Fa-f]{2})?\)", value)
    if m:
        value = m.group(1)
    return ("#" + value.lstrip("#")).lower()[:7]

def read(name):
    return open(f"{theme_dir}/{name}").read()

palette = {}
for line in open(colors_file):
    m = re.match(r'\s*([a-z_]+)\s*=\s*"([^"]*)"', line)
    if m:
        palette[m.group(1)] = m.group(2).lower()
palette["mode"] = mode

TEXT, LINE = 4.5, 3.0
bg = palette["background"]
rows = []

def check(app, label, fg, back, floor):
    rows.append((app, label, norm(fg), norm(back), contrast(norm(fg), norm(back)), floor))

def fail(message):
    print(f"FAIL\t{message}")

def not_role(app, label, value, *roles):
    for role in roles:
        if palette[role] in (palette["border"], palette["border_focus"]):
            continue
        if norm(value) == palette[role]:
            fail(f"{app} {label} is {role}")

def hyprland():
    h = read("hyprland.lua")
    active = re.search(r"^local active_border_color = (.+)$", h, re.M).group(1)
    inactive = re.search(r"^local inactive_border_color = (.+)$", h, re.M).group(1)
    inactive_border = re.findall(r'"([^"]+)"', inactive)[0]
    for label, spec in (("active border", active), ("inactive border", inactive)):
        for color in re.findall(r'"([^"]+)"', spec):
            check("hyprland", label, color, bg, LINE)
            not_role("hyprland", label, color, "muted", "selection")
    if norm(re.findall(r'"([^"]+)"', active)[0]) != palette["accent"]:
        fail("hyprland active border is not the accent")
    if norm(re.findall(r'"([^"]+)"', inactive)[0]) != palette["border"]:
        fail("hyprland inactive border is not border")
    if "595959" in h:
        fail("hyprland still hard-codes the inactive border")
    shadow = re.search(r'^local shadow_color = "(\w+)" == "light" and "([^"]+)" or "([^"]+)"$', h, re.M)
    expected = palette["foreground"] if shadow.group(1) == "light" else palette["darker_background"]
    if norm(shadow.group(2) if shadow.group(1) == "light" else shadow.group(3)) != expected:
        fail("hyprland shadow is not on the theme's darkest shade")
    bar = dict(re.findall(r'^\s+(\w+) = "(rgba?\([0-9A-Fa-f]+\))",?$', h.split("groupbar = {")[1], re.M))
    check("hyprland", "groupbar active", bar["text_color"], bar["active"], TEXT)
    check("hyprland", "groupbar inactive", bar["text_color_inactive"], bar["inactive"], TEXT)
    check("hyprland", "groupbar locked", bar["text_color"], bar["locked_active"], TEXT)
    check("hyprland", "groupbar locked inactive", bar["text_color_inactive"], bar["locked_inactive"], TEXT)
    locked = re.search(r'border_locked_active = "([^"]+)"', h).group(1)
    check("hyprland", "locked border", locked, bg, LINE)
    locked_inactive = re.search(r'border_locked_inactive = "([^"]+)"', h).group(1)
    check("hyprland", "locked inactive border", locked_inactive, bg, LINE)
    if norm(locked_inactive) == norm(inactive_border):
        fail("hyprland locked groups look unlocked when inactive")

def shell_sections(text):
    sections, current = {}, None
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        m = re.match(r"^\[([\w-]+)\]$", line)
        if m:
            current = sections.setdefault(m.group(1), {})
            continue
        m = re.match(r'^([\w-]+)\s*=\s*(?:"([^"]*)"|([^\s#]+))', line)
        if m and current is not None:
            current[m.group(1)] = (m.group(2) if m.group(2) is not None else m.group(3)).strip()
    return sections

def shell():
    s = shell_sections(read("shell.toml"))

    def resolve(value):
        while re.fullmatch(r"[\w-]+\.[\w-]+", value):
            section, key = value.split(".")
            value = s[section][key]
        return value.split()

    def solid(section, key, alpha_key=None):
        alpha = s[section].get(alpha_key or f"{key}-alpha", "1.0")
        if float(alpha) != 1.0:
            fail(f"shell {section}.{key} is drawn at alpha {alpha}")
        return [c for c in resolve(s[section][key]) if not c.endswith("deg")]

    c = s["controls"]
    for state in ("normal", "hover-cursor", "focus"):
        for color in solid("controls", f"{state}-border"):
            check("shell", f"{state} border", color, bg, LINE)
            not_role("shell", f"{state} border", color, "muted", "selection")
    if norm(c["focus-border"]) == norm(c["hover-cursor-border"]):
        fail("shell focus border mirrors hover")
    if norm(c["normal-border"]) != palette["border"]:
        fail("shell normal border is not border")
    if norm(c["focus-border"]) != palette["border_focus"]:
        fail("shell focus border is not border_focus")
    for color in solid("controls", "selection-color", "selection-fill-alpha"):
        check("shell", "text selection", palette["foreground"], color, TEXT)

    for section in ("menu",):
        back = solid(section, "selected-background")[0]
        check("shell", f"{section} selected row", s[section]["selected-text"], back, TEXT)
        if norm(back) != palette["selection"]:
            fail(f"shell {section} selected row is not selection")
        not_role("shell", f"{section} selected text", s[section]["selected-text"], "accent")
        check("shell", f"{section} text", s[section]["text"], s[section]["background"], TEXT)
        for color in solid(section, "border"):
            check("shell", f"{section} border", color, bg, LINE)

    for section in ("popups", "tooltip", "notifications", "polkit", "lock"):
        check("shell", f"{section} text", s[section]["text"], s[section]["background"], TEXT)
        for color in solid(section, "border", "border-alpha"):
            check("shell", f"{section} border", color, bg, LINE)
            not_role("shell", f"{section} border", color, "muted", "selection")
    for section in ("polkit", "lock"):
        check("shell", f"{section} error text", s[section]["text-error"], bg, TEXT)
        check("shell", f"{section} error border", s[section]["border-error"], bg, LINE)
        if norm(s[section]["text-error"]) != palette["red"]:
            fail(f"shell {section} error is not red")
    check("shell", "lock placeholder", s["lock"]["placeholder"], bg, TEXT)
    for color in solid("lock", "selection"):
        check("shell", "lock selection", s["lock"]["text"], color, TEXT)
    check("shell", "notification countdown", s["notifications"]["countdown"], bg, LINE)
    for key in ("selected-border", "unselected-border"):
        for color in solid("image-picker", key):
            check("shell", f"image picker {key}", color, bg, LINE)

def vicinae():
    v = tomllib.load(open(vicinae_file, "rb"))
    meta, colors = v["meta"], v["colors"]
    variant = "light" if palette.get("mode") == "light" else "dark"
    if meta["variant"] != variant or meta["inherits"] != f"vicinae-{variant}":
        fail(f"vicinae variant is {meta['variant']}/{meta['inherits']}, not {variant}")
    core, text, item = colors["core"], colors["text"], colors["list"]["item"]
    surface = core["secondary_background"]
    hover, selection = item["hover"], item["selection"]

    for label, color in (
        ("border", core["border"]),
        ("window border", colors["main_window"]["border"]),
        ("settings border", colors["settings_window"]["border"]),
        ("shortcut border", colors["shortcut"]["border"]),
        ("tooltip border", colors["tooltip"]["border"]),
        ("input border", colors["input"]["border"]),
        ("input focus", colors["input"]["border_focus"]),
        ("input error", colors["input"]["border_error"]),
        ("button focus", colors["button"]["primary"]["focus"]["outline"]),
        ("grid hover", colors["grid"]["item"]["hover"]["outline"]),
        ("grid selection", colors["grid"]["item"]["selection"]["outline"]),
        ("scrollbar", colors["scrollbars"]["background"]),
    ):
        check("vicinae", label, color, bg, LINE)
        not_role("vicinae", label, color, "muted", "selection")

    for label, color in (("text", text["default"]), ("muted", text["muted"]), ("placeholder", text["placeholder"]),
                         ("danger", text["danger"]), ("success", text["success"]),
                         ("link", text["links"]["default"]), ("visited link", text["links"]["visited"])):
        check("vicinae", label, color, bg, TEXT)
    check("vicinae", "muted on surface", text["muted"], surface, TEXT)
    check("vicinae", "placeholder in input", text["placeholder"], colors["input"]["background"], TEXT)
    footer = colors["main_window"]["footer"]["background"]
    check("vicinae", "footer text", text["muted"], footer, TEXT)
    if contrast(norm(hover["background"]), norm(footer)) < 1.08:
        fail("vicinae footer buttons have no visible hover")
    check("vicinae", "text selection", text["selection"]["foreground"], text["selection"]["background"], TEXT)
    check("vicinae", "accent button", core["accent_foreground"], core["accent"], TEXT)
    button = colors["button"]["primary"]
    check("vicinae", "button", button["foreground"], button["background"], TEXT)
    check("vicinae", "button hover", button["hover"]["foreground"], button["hover"]["background"], TEXT)
    check("vicinae", "hover row", hover["foreground"], hover["background"], TEXT)
    check("vicinae", "hover row secondary", hover["secondary_foreground"], hover["background"], TEXT)
    check("vicinae", "selected row", selection["foreground"], selection["background"], TEXT)
    check("vicinae", "selected row secondary", selection["secondary_foreground"], selection["secondary_background"], TEXT)

    if norm(text["links"]["default"]) != palette["link"]:
        fail("vicinae links are not link")
    for label, color in (("selected row", selection["background"]), ("text selection", text["selection"]["background"])):
        if norm(color) != palette["selection"]:
            fail(f"vicinae {label} is not selection")
    for label, color in (("selected row", selection["foreground"]), ("selected row secondary", selection["secondary_foreground"]),
                         ("text selection", text["selection"]["foreground"])):
        if norm(color) not in (palette["foreground"], palette["bright_foreground"]):
            fail(f"vicinae {label} text is not foreground")
    if norm(hover["background"]) == norm(selection["background"]):
        fail("vicinae hover row matches the selected row")
    for label, color in (("surface", surface), ("grid item", colors["grid"]["item"]["background"]),
                         ("button", button["background"]), ("input", colors["input"]["background"])):
        if norm(color) == palette["selection"]:
            fail(f"vicinae {label} fill is selection")

def share_picker():
    css = read("hyprland-preview-share-picker.css")
    c = {k: norm(v) for k, v in re.findall(r"@define-color (\w+) ([^;]+);", css)}
    if re.search(r"\{\{|bright_blue|@muted", css):
        fail("share picker uses bright_blue or muted")
    for key in ("border", "border_focus", "accent"):
        check("share picker", key, c[key], c["background"], LINE)
    check("share picker", "text", c["text"], c["background"], TEXT)
    check("share picker", "selected tab", c["selected_tab"], c["background"], TEXT)
    check("share picker", "card label", c["text"], c["card_bg"], TEXT)
    check("share picker", "hovered card", c["text"], c["card_hover"], TEXT)
    check("share picker", "selected card", c["text"], c["selection"], TEXT)
    check("share picker", "button", c["text_dark"], c["accent"], TEXT)
    check("share picker", "button hover", c["text_dark"], c["accent_hover"], TEXT)
    check("share picker", "disabled button", c["comment"], c["card_bg"], TEXT)
    if c["border"] != palette["border"] or c["selection"] != palette["selection"] or c["border_focus"] != palette["border_focus"]:
        fail("share picker border, focus and selection are not the theme roles")
    idle = re.search(r"flowboxchild > \.card, button > \.card \{(.*?)\}", css, re.S).group(1)
    if "@border" not in idle:
        fail("share picker idle cards have no visible border")

try:
    hyprland()
    shell()
    vicinae()
    share_picker()
except (KeyError, AttributeError, IndexError, ValueError) as error:
    fail(f"missing {error!r}")

for app, label, fg, back, ratio, floor in rows:
    print(f"{'ok' if ratio >= floor else 'FAIL'}\t{app}\t{label}\t{fg}\t{back}\t{ratio:.2f}\t{floor}")
PY

mkdir -p "$test_tmp/bin"
printf '#!/bin/bash\nexit 0\n' >"$test_tmp/bin/vicinae"
chmod +x "$test_tmp/bin/vicinae"

for theme_dir in "$ROOT"/themes/*/; do
  theme=$(basename "$theme_dir")
  home="$test_tmp/$theme"
  next_theme="$home/.local/state/maitri/current/next-theme"
  mkdir -p "$next_theme"
  cp "$theme_dir/colors.toml" "$next_theme/colors.toml"

  HOME="$home" MAITRI_PATH="$ROOT" PATH="$ROOT/bin:$PATH" bash "$ROOT/bin/maitri-theme-set-templates"

  for file in "${RENDERED[@]}"; do
    [[ -f $next_theme/$file ]] || fail "$theme renders $file"
    ! grep -q '{{' "$next_theme/$file" || fail "$theme leaves no placeholders in $file" "$(grep -n '{{' "$next_theme/$file")"
  done

  mkdir -p "$home/.local/state/maitri/current"
  ln -sfn "$next_theme" "$home/.local/state/maitri/current/theme"
  HOME="$home" MAITRI_PATH="$ROOT" PATH="$test_tmp/bin:$ROOT/bin:$PATH" bash "$ROOT/bin/maitri-theme-set-vicinae"
  vicinae_file="$home/.local/share/vicinae/themes/maitri.toml"
  [[ -f $vicinae_file ]] || fail "$theme installs the Vicinae theme"

  mode=$(PATH="$ROOT/bin:$PATH" maitri-theme-color --file "$next_theme/colors.toml" mode)
  report=$(python3 "$test_tmp/contrast.py" "$next_theme" "$theme_dir/colors.toml" "$vicinae_file" "$mode") ||
    fail "$theme desktop contrast check runs"
  [[ -n $report ]] || fail "$theme produces a desktop contrast report"
  if failures=$(grep '^FAIL' <<<"$report"); then
    fail "$theme Hyprland, shell, Vicinae and share picker colors clear 4.5:1 for text and 3:1 for lines" "$failures"
  fi
  [[ -z ${MAITRI_CONTRAST_REPORT:-} ]] || sed "s/^/$theme\t/" <<<"$report" >>"$MAITRI_CONTRAST_REPORT"
  pass "$theme Hyprland, shell, Vicinae and share picker colors clear 4.5:1 for text and 3:1 for lines"
done

home="$test_tmp/override"
next_theme="$home/.local/state/maitri/current/next-theme"
mkdir -p "$next_theme"
cp "$ROOT/themes/amethyst/colors.toml" "$next_theme/colors.toml"
printf '[menu]\nselected-text = "#123456"\n' >"$next_theme/shell.menu.toml"
HOME="$home" MAITRI_PATH="$ROOT" PATH="$ROOT/bin:$PATH" bash "$ROOT/bin/maitri-theme-set-templates"
menu=$(awk '/^\[menu\]/ { on = 1; next } /^\[/ { on = 0 } on' "$next_theme/shell.toml")
[[ $menu == 'selected-text = "#123456"' ]] || fail "a shell.menu.toml override replaces the [menu] section" "$menu"
border=$(PATH="$ROOT/bin:$PATH" maitri-theme-color --file "$next_theme/colors.toml" border)
grep -qF "normal-border       = \"$border\"" "$next_theme/shell.toml" ||
  fail "a shell.menu.toml override leaves [controls] on the theme roles"
pass "shell section overrides still replace their section"
