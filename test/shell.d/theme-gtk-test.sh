#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

require_command python3

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

render_theme() {
  local theme="$1"
  local home="$2"
  local state="$home/.local/state/maitri/current"

  rm -rf "$state/next-theme" "$state/theme"
  mkdir -p "$state/next-theme"
  cp "$ROOT/themes/$theme/colors.toml" "$state/next-theme/colors.toml"
  HOME="$home" MAITRI_PATH="$ROOT" PATH="$ROOT/bin:$PATH" bash "$ROOT/bin/maitri-theme-set-templates"
  mv "$state/next-theme" "$state/theme"
  echo "$theme" >"$state/theme.name"
}

run_hook() {
  local home="$1"

  HOME="$home" XDG_CONFIG_HOME="${CONFIG_HOME:-$home/.config}" XDG_RUNTIME_DIR="$home" \
    MAITRI_PATH="$ROOT" PATH="$ROOT/bin:$PATH" bash "$ROOT/bin/maitri-theme-set-gtk"
}

colour_line='@define-color [a-z_]+ #[0-9A-Fa-f]{6};|/\*[^*]*\*/|[[:space:]]*'

themes=()
for theme_dir in "$ROOT"/themes/*/; do
  theme=$(basename "$theme_dir")
  home="$test_tmp/render/$theme"
  render_theme "$theme" "$home"
  css="$home/.local/state/maitri/current/theme/gtk.css"

  [[ -f $css ]] || fail "$theme renders gtk.css"
  ! grep -q '{{' "$css" || fail "$theme leaves no placeholders in gtk.css" "$(grep -n '{{' "$css")"
  ! grep -vxE "$colour_line" "$css" | grep -q . ||
    fail "$theme renders gtk.css as colour definitions only" "$(grep -vxE "$colour_line" "$css")"
  themes+=("$theme")
done

(( ${#themes[@]} == 6 )) || fail "all six themes are rendered" "${themes[*]}"
pass "every theme renders gtk.css as plain colour definitions"

python3 - "$test_tmp/render" "$ROOT" "${themes[@]}" <<'PY'
import re, sys

root, repo, themes = sys.argv[1], sys.argv[2], sys.argv[3:]
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


def palette(theme):
    text = open(f"{repo}/themes/{theme}/colors.toml").read()
    return {k: v.lower() for k, v in re.findall(r'^(\w+)\s*=\s*"(#[0-9A-Fa-f]{6})"', text, re.M)}


SURFACES = ["window", "view", "headerbar", "sidebar", "secondary_sidebar", "card", "dialog", "popover", "thumbnail"]
FILLS = ["accent", "destructive", "success", "warning", "error"]
STANDALONE = FILLS + ["link"]
READ_ON = ["window", "view", "sidebar", "card", "popover", "dialog"]
ROLES = {
    "accent_bg_color": "accent", "link_color": "link", "warning_color": "orange", "error_color": "red",
    "destructive_color": "red", "success_color": "green", "borders": "border", "selection_bg_color": "selection",
    "window_bg_color": "dark_background", "view_bg_color": "background", "view_fg_color": "foreground",
}

for theme in themes:
    css = open(f"{root}/{theme}/.local/state/maitri/current/theme/gtk.css").read()
    c = {name: value.lower() for name, value in re.findall(r"@define-color (\w+) (#[0-9A-Fa-f]{6});", css)}
    p = palette(theme)
    errors, low = [], {TEXT: 99.0, LINE: 99.0}

    def floor(label, fg, bg, minimum):
        if fg not in c or bg not in c:
            errors.append(f"{label}: {fg} or {bg} is not defined")
            return
        ratio = contrast(c[fg], c[bg])
        low[minimum] = min(low[minimum], ratio)
        if ratio < minimum:
            errors.append(f"{label}: {ratio:.2f}:1 ({c[fg]} on {c[bg]}), floor {minimum}:1")

    for surface in SURFACES:
        floor(f"{surface} text", f"{surface}_fg_color", f"{surface}_bg_color", TEXT)
    for fill in FILLS:
        floor(f"text on {fill}", f"{fill}_fg_color", f"{fill}_bg_color", TEXT)
    for role in STANDALONE:
        for surface in READ_ON:
            floor(f"{role} text on {surface}", f"{role}_color", f"{surface}_bg_color", TEXT)
    floor("selected text", "selection_fg_color", "selection_bg_color", TEXT)
    floor("GTK3 text", "theme_text_color", "theme_base_color", TEXT)
    floor("GTK3 window text", "theme_fg_color", "theme_bg_color", TEXT)
    floor("GTK3 selected text", "theme_selected_fg_color", "theme_selected_bg_color", TEXT)
    floor("GTK3 insensitive text", "insensitive_fg_color", "insensitive_bg_color", TEXT)

    for surface in ["window", "view", "headerbar", "sidebar"]:
        floor(f"borders on {surface}", "borders", f"{surface}_bg_color", LINE)
    for surface in ["card", "popover", "thumbnail"]:
        floor(f"raised borders on {surface}", "raised_borders", f"{surface}_bg_color", LINE)
    floor("headerbar border", "headerbar_border_color", "headerbar_bg_color", LINE)
    floor("sidebar border against the view", "sidebar_border_color", "view_bg_color", LINE)
    floor("sidebar border against the sidebar", "sidebar_border_color", "sidebar_bg_color", LINE)
    for surface in ["window", "view", "card"]:
        floor(f"accent fill on {surface}", "accent_bg_color", f"{surface}_bg_color", LINE)

    for name, role in ROLES.items():
        if c.get(name) != p.get(role):
            errors.append(f"{name} is {c.get(name)}, expected {role} {p.get(role)}")

    if theme == "daybreak" and luminance(c["view_bg_color"]) < 0.5:
        errors.append("daybreak does not render on a light view background")

    if errors:
        failed = True
        print("\n".join(f"  {e}" for e in errors), file=sys.stderr)
        print(f"not ok - {theme} GTK meets the contrast floors and the shared mapping", file=sys.stderr)
    else:
        print(f"ok - {theme} GTK meets the contrast floors and the shared mapping (text {low[TEXT]:.2f}:1, lines {low[LINE]:.2f}:1)")

    table.append((theme, contrast(c["view_fg_color"], c["view_bg_color"]), contrast(c["window_fg_color"], c["window_bg_color"]),
                  contrast(c["card_fg_color"], c["card_bg_color"]), contrast(c["accent_fg_color"], c["accent_bg_color"]),
                  min(contrast(c[f"{r}_color"], c[f"{s}_bg_color"]) for r in STANDALONE for s in READ_ON),
                  contrast(c["selection_fg_color"], c["selection_bg_color"]),
                  min(contrast(c["borders"], c[f"{s}_bg_color"]) for s in ["window", "view", "headerbar", "sidebar"])))

print("# | theme | text on view | text on window | text on cards | text on accent | lowest accent/status/link text | selected text | borders |")
for row in table:
    print("# | " + row[0] + " | " + " | ".join(f"{v:.2f}" for v in row[1:]) + " |")

sys.exit(1 if failed else 0)
PY

# The hook only ever rewrites its own block, keeps it ahead of the user's rules
# and after their imports, and leaves a symlinked file or directory alone.
home="$test_tmp/home"
render_theme amethyst "$home"
gtk3="$home/.config/gtk-3.0/gtk.css"
gtk4="$home/.config/gtk-4.0/gtk.css"
mkdir -p "$home/.config/gtk-3.0"
printf '@import url("colors.css");\n\nwindow { padding: 2px; }\n' >"$gtk3"

run_hook "$home" 2>"$test_tmp/stderr"
for file in "$gtk3" "$gtk4"; do
  [[ -f $file ]] || fail "the hook writes $file"
  (( $(grep -cxF '/* >>> maitri theme (rewritten by maitri theme set) >>> */' "$file") == 1 )) || fail "$file holds one maitri block"
  grep -qF '@define-color accent_bg_color #B08CFF;' "$file" || fail "$file carries the theme's accent"
done
grep -qF -- '--accent-color: @accent_color;' "$gtk4" || fail "the GTK4 block carries the libadwaita rules"
! grep -qF -- '--accent-color' "$gtk3" || fail "the GTK3 block has no libadwaita variables, which GTK3 can't parse"
grep -qF 'button.suggested-action {' "$gtk3" || fail "the GTK3 block carries the GTK3 rules"
[[ $(head -n 1 "$gtk3") == '@import url("colors.css");' ]] || fail "the user's @import stays at the top" "$(head -n 3 "$gtk3")"
[[ $(tail -n 1 "$gtk3") == 'window { padding: 2px; }' ]] || fail "the user's own rules stay after the block" "$(tail -n 3 "$gtk3")"
grep -q "restarted" "$test_tmp/stderr" || fail "the hook says open apps need a restart"
pass "the hook splices the theme into both GTK configs around the user's own lines"

cp "$gtk3" "$test_tmp/gtk3-before"
run_hook "$home" 2>"$test_tmp/stderr"
cmp -s "$gtk3" "$test_tmp/gtk3-before" || fail "a second run changes nothing" "$(diff "$test_tmp/gtk3-before" "$gtk3")"
[[ ! -s $test_tmp/stderr ]] || fail "a run that changes nothing says nothing" "$(cat "$test_tmp/stderr")"
pass "the hook is idempotent"

render_theme daybreak "$home"
run_hook "$home" 2>/dev/null
for file in "$gtk3" "$gtk4"; do
  (( $(grep -cxF '/* <<< maitri theme <<< */' "$file") == 1 )) || fail "a theme change leaves one block in $file"
  grep -qF '@define-color accent_bg_color #644AC9;' "$file" || fail "a theme change rewrites the block in $file"
  ! grep -qF '#B08CFF' "$file" || fail "a theme change drops the old theme's colours from $file"
done
[[ $(tail -n 1 "$gtk3") == 'window { padding: 2px; }' ]] || fail "a theme change keeps the user's own rules"
pass "a theme change replaces the block and nothing else"

dotfiles="$test_tmp/dotfiles"
link_home="$test_tmp/link-home"
render_theme amethyst "$link_home"
mkdir -p "$dotfiles/gtk-4.0" "$link_home/.config/gtk-3.0"
printf 'label { color: red; }\n' >"$dotfiles/gtk-3.css"
ln -s "$dotfiles/gtk-3.css" "$link_home/.config/gtk-3.0/gtk.css"
ln -s "$dotfiles/gtk-4.0" "$link_home/.config/gtk-4.0"
run_hook "$link_home" 2>"$test_tmp/stderr"
[[ $(cat "$dotfiles/gtk-3.css") == 'label { color: red; }' ]] || fail "a symlinked gtk.css is not written through"
[[ ! -e $dotfiles/gtk-4.0/gtk.css ]] || fail "nothing is written into a symlinked GTK config dir"
(( $(grep -c "is a symlink, so maitri left it alone" "$test_tmp/stderr") == 2 )) ||
  fail "the hook says how to follow the theme from a symlinked config" "$(cat "$test_tmp/stderr")"
grep -qF "@import url(\"file://$link_home/.local/state/maitri/current/gtk-4.0.css\");" "$test_tmp/stderr" ||
  fail "the hint names the import line to add" "$(cat "$test_tmp/stderr")"
grep -qF 'button.suggested-action {' "$link_home/.local/state/maitri/current/gtk-3.0.css" ||
  fail "the hint's file carries the vetted block"
pass "a symlinked gtk.css or GTK config dir is left alone with a hint"

xdg_home="$test_tmp/xdg-home"
render_theme spark "$xdg_home"
CONFIG_HOME="$test_tmp/xdg-config" run_hook "$xdg_home" 2>/dev/null
[[ -f $test_tmp/xdg-config/gtk-4.0/gtk.css && ! -e $xdg_home/.config/gtk-4.0 ]] || fail "the hook writes under XDG_CONFIG_HOME"
pass "the hook follows XDG_CONFIG_HOME like GTK does"

hostile_home="$test_tmp/hostile-home"
render_theme amethyst "$hostile_home"
printf '@define-color accent_bg_color #B08CFF; } filechooser { opacity: 0; } x {\n' >>"$hostile_home/.local/state/maitri/current/theme/gtk.css"
run_hook "$hostile_home" 2>"$test_tmp/stderr"
[[ ! -e $hostile_home/.config/gtk-4.0/gtk.css && ! -e $hostile_home/.config/gtk-3.0/gtk.css ]] ||
  fail "a gtk.css with anything but colour definitions is not spliced in"
grep -q "isn't a colour definition" "$test_tmp/stderr" || fail "the hook says why it skipped a theme's gtk.css"
pass "a theme's gtk.css only gets through as colour definitions"

nul_home="$test_tmp/nul-home"
render_theme amethyst "$nul_home"
printf '/*\0*/\nbutton { opacity: 0; }\n' >>"$nul_home/.local/state/maitri/current/theme/gtk.css"
run_hook "$nul_home" 2>/dev/null
[[ ! -e $nul_home/.config/gtk-4.0/gtk.css ]] || fail "a NUL byte cannot smuggle a rule past the colour-only filter"
pass "a NUL byte cannot smuggle a rule past the colour-only filter"

marker_home="$test_tmp/marker-home"
render_theme amethyst "$marker_home"
echo '/* <<< maitri theme <<< */' >>"$marker_home/.local/state/maitri/current/theme/gtk.css"
run_hook "$marker_home" 2>/dev/null
[[ ! -e $marker_home/.config/gtk-4.0/gtk.css ]] || fail "a theme cannot carry the block markers"
pass "a theme cannot carry the block markers"

strip_home="$test_tmp/strip-home"
render_theme amethyst "$strip_home"
mkdir -p "$strip_home/.config/gtk-4.0"
printf 'label { color: red; }\n' >"$strip_home/.config/gtk-4.0/gtk.css"
run_hook "$strip_home" 2>/dev/null
echo 'window { opacity: 0; }' >>"$strip_home/.local/state/maitri/current/theme/gtk.css"
run_hook "$strip_home" 2>/dev/null
! grep -qF 'maitri theme' "$strip_home/.config/gtk-4.0/gtk.css" || fail "a theme that fails the filter drops the old block"
grep -qxF 'label { color: red; }' "$strip_home/.config/gtk-4.0/gtk.css" || fail "dropping the block keeps the user's rules"
[[ ! -s $strip_home/.local/state/maitri/current/gtk-4.0.css ]] || fail "dropping the block empties the file the symlink hint imports"
pass "a theme that fails the filter drops the previous theme's block"

locked_home="$test_tmp/locked-home"
render_theme amethyst "$locked_home"
mkdir -p "$locked_home/.config/gtk-4.0"
printf 'label { color: red; }\n' >"$locked_home/.config/gtk-4.0/gtk.css"
chmod 200 "$locked_home/.config/gtk-4.0/gtk.css"
if run_hook "$locked_home" 2>"$test_tmp/stderr"; then
  fail "the hook reports a gtk.css it can't read"
fi
chmod 600 "$locked_home/.config/gtk-4.0/gtk.css"
[[ $(cat "$locked_home/.config/gtk-4.0/gtk.css") == 'label { color: red; }' ]] || fail "an unreadable gtk.css is never emptied"
grep -q "can't be read" "$test_tmp/stderr" || fail "the hook says why it left an unreadable gtk.css alone" "$(cat "$test_tmp/stderr")"
[[ -z $(find "$locked_home/.config/gtk-4.0" -name '.gtk.css.*') ]] || fail "no staging file is left behind"
pass "an unreadable gtk.css is left alone and reported"

doubled_home="$test_tmp/doubled-home"
render_theme amethyst "$doubled_home"
mkdir -p "$doubled_home/.config/gtk-4.0"
printf '%s\nlabel { color: red; }\n%s\nbox {}\n%s\n' '/* >>> maitri theme (rewritten by maitri theme set) >>> */' \
  '/* >>> maitri theme (rewritten by maitri theme set) >>> */' '/* <<< maitri theme <<< */' >"$doubled_home/.config/gtk-4.0/gtk.css"
cp "$doubled_home/.config/gtk-4.0/gtk.css" "$test_tmp/doubled-before"
run_hook "$doubled_home" 2>"$test_tmp/stderr" && fail "the hook reports doubled markers"
cmp -s "$doubled_home/.config/gtk-4.0/gtk.css" "$test_tmp/doubled-before" || fail "doubled markers leave the file untouched"
grep -q "doubled or out of order" "$test_tmp/stderr" || fail "the hook names the marker problem"
pass "doubled markers are refused rather than eating the user's CSS"

shape_home="$test_tmp/shape-home"
render_theme amethyst "$shape_home"
mkdir -p "$shape_home/.config/gtk-4.0"
gtk4="$shape_home/.config/gtk-4.0/gtk.css"
printf '/* my theme */\n@import url(\r\n  "colors.css");\r\n\r\nlabel { color: red; }\r\n' >"$gtk4"
chmod 600 "$gtk4"
run_hook "$shape_home" 2>/dev/null
cp "$gtk4" "$test_tmp/shape-before"
run_hook "$shape_home" 2>/dev/null
cmp -s "$gtk4" "$test_tmp/shape-before" || fail "a CRLF gtk.css gets one block however often the hook runs" "$(diff "$test_tmp/shape-before" "$gtk4")"
[[ $(head -n 3 "$gtk4" | tr -d '\r') == $'/* my theme */\n@import url(\n  "colors.css");' ]] ||
  fail "the leading comment and a multi-line @import stay whole above the block" "$(head -n 4 "$gtk4")"
[[ $(sed -n 4p "$gtk4") == '/* >>> maitri theme (rewritten by maitri theme set) >>> */' ]] || fail "the block follows the prelude"
[[ $(stat -c %a "$gtk4") == 600 ]] || fail "the hook keeps gtk.css's mode" "$(stat -c %a "$gtk4")"
pass "the prelude stays whole, CRLF files stay at one block, and the file mode is kept"

skip_home="$test_tmp/skip-home"
render_theme amethyst "$skip_home"
mkdir -p "$skip_home/.local/state/maitri/toggles"
touch "$skip_home/.local/state/maitri/toggles/skip-gtk-theme-changes"
run_hook "$skip_home" 2>/dev/null
[[ ! -e $skip_home/.config/gtk-4.0 ]] || fail "skip-gtk-theme-changes leaves GTK alone"
pass "skip-gtk-theme-changes leaves GTK alone"

if /usr/bin/python3 -c 'import gi; gi.require_version("Gtk", "3.0")' 2>/dev/null &&
  /usr/bin/python3 -c 'import gi; gi.require_version("Gtk", "4.0")' 2>/dev/null; then
  for theme in "${themes[@]}"; do
    run_hook "$test_tmp/render/$theme" 2>/dev/null
    for version in 3.0 4.0; do
      /usr/bin/python3 - "$version" "$test_tmp/render/$theme/.local/state/maitri/current/gtk-$version.css" <<'PY' ||
import sys, gi
gi.require_version("Gtk", sys.argv[1])
from gi.repository import Gtk
errors = []
provider = Gtk.CssProvider()
provider.connect("parsing-error", lambda _p, _section, error: errors.append(error.message))
provider.load_from_path(sys.argv[2])
sys.exit("\n".join(errors) if errors else 0)
PY
        fail "GTK $version parses the $theme block"
    done
  done
  pass "GTK 3 and GTK 4 parse every theme's block without errors"
fi

# The GNOME hook maps each theme's accent onto the nearest GNOME preset.
fake_bin="$test_tmp/fake-bin"
mkdir -p "$fake_bin"
cat >"$fake_bin/gsettings" <<'SH'
#!/bin/bash
echo "$*" >>"$GSETTINGS_LOG"
[[ $1 == "range" && -n ${NO_ACCENT_KEY:-} ]] && exit 1
exit 0
SH
chmod +x "$fake_bin/gsettings"

declare -A presets=([amethyst]=purple [daybreak]=purple [ember]=orange [garnet]=red [harbor]=teal [spark]=blue)
for theme in "${themes[@]}"; do
  gnome_home="$test_tmp/gnome/$theme"
  render_theme "$theme" "$gnome_home"
  log="$gnome_home/gsettings.log"
  GSETTINGS_LOG="$log" DBUS_SESSION_BUS_ADDRESS="unix:path=$gnome_home/bus" HOME="$gnome_home" \
    MAITRI_PATH="$ROOT" PATH="$fake_bin:$ROOT/bin:$PATH" bash "$ROOT/bin/maitri-theme-set-gnome"
  grep -qxF "set org.gnome.desktop.interface accent-color ${presets[$theme]}" "$log" ||
    fail "$theme sets the ${presets[$theme]} accent preset" "$(cat "$log")"
  scheme=prefer-dark
  [[ $theme == "daybreak" ]] && scheme=prefer-light
  grep -qxF "set org.gnome.desktop.interface color-scheme $scheme" "$log" || fail "$theme sets color-scheme $scheme"
done
pass "each theme sets the GNOME accent preset nearest its accent"

grey_home="$test_tmp/gnome/grey"
render_theme amethyst "$grey_home"
sed -i 's/^accent = .*/accent = "#8A8A90"/' "$grey_home/.local/state/maitri/current/theme/colors.toml"
GSETTINGS_LOG="$grey_home/log" DBUS_SESSION_BUS_ADDRESS="unix:path=$grey_home/bus" HOME="$grey_home" \
  MAITRI_PATH="$ROOT" PATH="$fake_bin:$ROOT/bin:$PATH" bash "$ROOT/bin/maitri-theme-set-gnome"
grep -qxF "set org.gnome.desktop.interface accent-color slate" "$grey_home/log" || fail "a near-grey accent picks slate"
pass "a near-grey accent picks slate"

old_home="$test_tmp/gnome/old"
render_theme amethyst "$old_home"
NO_ACCENT_KEY=1 GSETTINGS_LOG="$old_home/log" DBUS_SESSION_BUS_ADDRESS="unix:path=$old_home/bus" HOME="$old_home" \
  MAITRI_PATH="$ROOT" PATH="$fake_bin:$ROOT/bin:$PATH" bash "$ROOT/bin/maitri-theme-set-gnome"
! grep -q "accent-color" <(grep '^set' "$old_home/log") || fail "schemas without accent-color are left alone"
grep -qxF "set org.gnome.desktop.interface color-scheme prefer-dark" "$old_home/log" || fail "color-scheme is still set without accent-color"
pass "GNOME schemas older than accent-color still get the colour scheme"
