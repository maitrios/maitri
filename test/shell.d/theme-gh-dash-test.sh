#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

[[ -x /usr/bin/python3 ]] || fail "the system Python is available at /usr/bin/python3"
/usr/bin/python3 -I -c 'import yaml' 2>/dev/null || fail "required Python module is available: yaml"

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

  [[ -f $next_theme/gh-dash.yml ]] || fail "$theme renders gh-dash.yml"
  ! grep -q '{{' "$next_theme/gh-dash.yml" ||
    fail "$theme leaves no placeholders in gh-dash.yml" "$(grep -n '{{' "$next_theme/gh-dash.yml")"
  themes+=("$theme")
done

(( ${#themes[@]} > 0 )) || fail "themes are rendered"

/usr/bin/python3 -I - "$test_tmp" "${themes[@]}" <<'PY'
import sys, yaml

root, themes = sys.argv[1], sys.argv[2:]
TEXT, LINE = 4.5, 3.0
ANSI = ["foreground", "comment", "red", "green", "yellow", "blue", "magenta", "cyan"]
failed = False


def rgb(color):
    color = color.lstrip("#")
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


for theme in themes:
    p = dict(line.rstrip("\n").split("\t", 1) for line in open(f"{root}/{theme}/palette.tsv"))
    colors = yaml.safe_load(open(f"{root}/{theme}/.local/state/maitri/current/next-theme/gh-dash.yml"))["theme"]["colors"]
    text, border, selected = colors["text"], colors["border"], colors["background"]["selected"]
    errors, low = [], 99.0

    def floor(label, fg, bg, minimum=TEXT):
        global low
        ratio = contrast(fg, bg)
        low = min(low, ratio) if minimum == TEXT else low
        if ratio < minimum:
            errors.append(f"{label}: {ratio:.2f}:1 ({fg} on {bg}), floor {minimum}:1")

    roles = {
        "text": {"primary": "foreground", "secondary": "light_foreground", "inverted": "background", "faint": "comment",
                 "warning": "orange", "success": "green", "error": "red", "actor": "accent"},
        "background": {"selected": "lighter_background"},
        "border": {"primary": "border_focus", "secondary": "border"},
        "icon": {"newcontributor": "green", "contributor": "blue", "collaborator": "cyan", "member": "magenta",
                 "owner": "yellow", "unknownrole": "comment"},
    }
    for group, keys in roles.items():
        for key, role in keys.items():
            if colors[group][key].lower() != p[role].lower():
                errors.append(f"{group}.{key} is {colors[group][key]}, expected {role} {p[role]}")
    faint_fill = mix(p["background"], p["lighter_background"], 0.5)
    if border["faint"].lower() != faint_fill:
        errors.append(f"border.faint is {border['faint']}, expected background and lighter_background mixed {faint_fill}")

    for key, color in text.items():
        if key != "inverted":
            floor(f"text.{key}", color, p["background"])
    for key, color in colors["icon"].items():
        floor(f"icon.{key}", color, p["background"])
    # gh-dash fills with some of these slots too: the selected row and footer,
    # the view switcher on border.faint, and the help and draft pills on
    # text.faint.
    for key in ("primary", "secondary", "faint", "warning", "actor"):
        floor(f"text.{key} on background.selected", text[key], selected)
    for role in ANSI:
        floor(f"{role} on background.selected", p[role], selected)
    for key in ("primary", "faint"):
        floor(f"text.{key} on border.faint", text[key], border["faint"])
    floor("background.selected on text.faint", selected, text["faint"])
    floor("text.inverted on text.faint", text["inverted"], text["faint"])
    for key in ("primary", "secondary"):
        floor(f"border.{key}", border[key], p["background"], LINE)
    floor("border.primary on border.faint", border["primary"], border["faint"], LINE)

    if errors:
        failed = True
        print("\n".join(f"  {e}" for e in errors), file=sys.stderr)
        print(f"not ok - {theme} gh-dash meets the contrast floors and the shared mapping", file=sys.stderr)
    else:
        print(f"ok - {theme} gh-dash meets the contrast floors and the shared mapping (text {low:.2f}:1)")

sys.exit(1 if failed else 0)
PY

pass "gh-dash.yml renders for every theme with readable contrast and the shared mapping"

[[ -x $ROOT/bin/maitri-theme-set-gh-dash ]] || fail "maitri-theme-set-gh-dash is executable, since maitri-theme-set runs it by name"
grep -qE '(^|[ "])maitri-theme-set-gh-dash([ ;"]|$)' "$ROOT/bin/maitri-theme-set" || fail "maitri-theme-set runs maitri-theme-set-gh-dash"

apps="$test_tmp/app-bin"
mkdir -p "$apps"
printf '#!/bin/bash\nexit 1\n' >"$apps/pgrep"
# A python3 from mise or a venv comes first on PATH and has no PyYAML.
printf '#!/bin/bash\necho "ModuleNotFoundError: yaml" >&2\nexit 1\n' >"$apps/python3"
chmod +x "$apps/pgrep" "$apps/python3"

run_hook() {
  local home="$1"

  env -u XDG_CONFIG_HOME -u GH_DASH_CONFIG HOME="$home" XDG_RUNTIME_DIR="$home/run" MAITRI_PATH="$ROOT" PATH="$apps:$ROOT/bin:$PATH" \
    "$BASH" "$ROOT/bin/maitri-theme-set-gh-dash" 2>>"$home/hook.stderr"
}

new_home() {
  local home="$test_tmp/hooks-$1"

  mkdir -p "$home/.local/state/maitri/current" "$home/run" "$home/.config"
  cp -r "$test_tmp/$2/.local/state/maitri/current/next-theme" "$home/.local/state/maitri/current/theme"
  : >"$home/hook.stderr"
  printf '%s' "$home"
}

set_theme() {
  rm -rf "$1/.local/state/maitri/current/theme"
  cp -r "$test_tmp/$2/.local/state/maitri/current/next-theme" "$1/.local/state/maitri/current/theme"
}

colors_match() {
  /usr/bin/python3 -I -c 'import sys, yaml
config, rendered = (yaml.safe_load(open(f)) for f in sys.argv[1:])
sys.exit(config["theme"]["colors"] != rendered["theme"]["colors"])' "$1" "$2"
}

without_block() {
  sed '/# >>> maitri theme (rewritten by maitri theme set) >>>/,/# <<< maitri theme <<</d' "$1"
}

home=$(new_home missing amethyst)
run_hook "$home" || fail "the hook runs without a gh-dash config"
[[ -z $(ls -A "$home/.config") && ! -s $home/hook.stderr ]] || fail "the hook writes and says nothing without a gh-dash config" "$(find "$home/.config"; cat "$home/hook.stderr")"
pass "without a gh-dash config the hook writes nothing"

home=$(new_home ui amethyst)
config="$home/.config/gh-dash/config.yml"
mkdir -p "$home/.config/gh-dash"
cat >"$test_tmp/ui.yml" <<'YAML'
prSections:
    - title: Mine
      filters: is:open author:@me
keybindings: {}
theme:
    ui:
        sectionsShowCount: true
        table:
            showSeparator: true
            compact: false
pager:
    diff: ""
confirmQuit: false
YAML
cp "$test_tmp/ui.yml" "$config"
run_hook "$home" || fail "the hook runs on a config with only theme.ui"
rendered="$home/.local/state/maitri/current/theme/gh-dash.yml"
colors_match "$config" "$rendered" || fail "gh-dash gets the theme's colours under theme" "$(cat "$config")"
grep -q '^    # >>> maitri theme' "$config" && grep -q '^        text:$' "$config" || fail "the colours take the indent theme's own keys use" "$(cat "$config")"
cmp -s <(without_block "$config") "$test_tmp/ui.yml" || fail "the rest of the config is unchanged byte for byte" "$(diff <(without_block "$config") "$test_tmp/ui.yml")"
cp "$config" "$test_tmp/ui-amethyst.yml"
run_hook "$home"
cmp -s "$config" "$test_tmp/ui-amethyst.yml" || fail "running the hook again changes nothing"
[[ ! -s $home/hook.stderr ]] || fail "applying the theme says nothing when nothing needs the user" "$(cat "$home/hook.stderr")"
pass "a config with only theme.ui gets theme.colors beside it and keeps the rest"

set_theme "$home" daybreak
run_hook "$home"
colors_match "$config" "$home/.local/state/maitri/current/theme/gh-dash.yml" || fail "a theme change replaces gh-dash's colours" "$(cat "$config")"
[[ $(grep -c '# >>> maitri theme' "$config") == 1 ]] || fail "a theme change keeps one block" "$(cat "$config")"
cmp -s <(without_block "$config") "$test_tmp/ui.yml" || fail "a theme change leaves the rest of the config unchanged"
set_theme "$home" amethyst
run_hook "$home"
cmp -s "$config" "$test_tmp/ui-amethyst.yml" || fail "switching back gives the same file byte for byte" "$(diff "$config" "$test_tmp/ui-amethyst.yml")"
pass "a theme change replaces the colours, and switching back restores the file exactly"

home=$(new_home bare amethyst)
config="$home/.config/gh-dash/config.yml"
mkdir -p "$home/.config/gh-dash" "$home/dotfiles"
printf '# my dash\nprSections:\n  - title: Mine # me\n    filters: is:open author:@me\nrepoPaths: {}\n' >"$test_tmp/bare.yml"
cp "$test_tmp/bare.yml" "$home/dotfiles/gh-dash.yml"
chmod 600 "$home/dotfiles/gh-dash.yml"
ln -s "$home/dotfiles/gh-dash.yml" "$config"
run_hook "$home" || fail "the hook runs on a config with no theme"
colors_match "$config" "$home/.local/state/maitri/current/theme/gh-dash.yml" || fail "a config with no theme gets one" "$(cat "$config")"
[[ $(without_block "$config") == "$(<"$test_tmp/bare.yml")"$'\n\ntheme:' ]] || fail "theme goes after the rest of the config" "$(cat "$config")"
grep -q '^  # >>> maitri theme' "$config" || fail "the colours take the file's own indent" "$(cat "$config")"
[[ -L $config && $(stat -c %a "$home/dotfiles/gh-dash.yml") == 600 ]] || fail "a symlinked config stays a symlink and keeps its permissions"
pass "a config with no theme gets one at the end"

home=$(new_home own amethyst)
config="$home/.config/gh-dash/config.yml"
mkdir -p "$home/.config/gh-dash"
printf 'theme:\n  colors:\n    text:\n      primary: "#ffffff"\n' >"$config"
cp "$config" "$test_tmp/own.yml"
run_hook "$home" || fail "the hook runs beside the user's own theme.colors"
cmp -s "$config" "$test_tmp/own.yml" || fail "gh-dash keeps its own theme.colors" "$(cat "$config")"
grep -qF "sets its own theme.colors" "$home/hook.stderr" || fail "the hook says it left the user's colours" "$(cat "$home/hook.stderr")"
pass "a config with its own theme.colors is left alone"

home=$(new_home invalid amethyst)
config="$home/.config/gh-dash/config.yml"
mkdir -p "$home/.config/gh-dash"
printf 'theme:\n  ui: [unclosed\n' >"$config"
cp "$config" "$test_tmp/invalid.yml"
run_hook "$home" || fail "the hook runs on invalid YAML"
cmp -s "$config" "$test_tmp/invalid.yml" || fail "invalid YAML is left alone" "$(cat "$config")"
grep -qF "isn't valid YAML" "$home/hook.stderr" || fail "the hook says the config isn't valid YAML" "$(cat "$home/hook.stderr")"
pass "invalid YAML is left alone with a notice"

home=$(new_home inline amethyst)
config="$home/.config/gh-dash/config.yml"
mkdir -p "$home/.config/gh-dash"
printf 'theme: {ui: {sectionsShowCount: false}}\n' >"$config"
cp "$config" "$test_tmp/inline.yml"
run_hook "$home" || fail "the hook runs on a one-line theme"
cmp -s "$config" "$test_tmp/inline.yml" && grep -qF "writes theme on one line" "$home/hook.stderr" ||
  fail "a one-line theme is left alone with a notice" "$(cat "$config" "$home/hook.stderr")"
pass "a one-line theme is left alone with a notice"

home=$(new_home hostile amethyst)
config="$home/.config/gh-dash/config.yml"
mkdir -p "$home/.config/gh-dash"
cp "$test_tmp/ui.yml" "$config"
printf 'theme:\n  colors:\n    text:\n      primary: "#ffffff"\nkeybindings:\n  universal:\n    - key: x\n      command: touch pwned\n' \
  >"$home/.local/state/maitri/current/theme/gh-dash.yml"
run_hook "$home" || fail "the hook runs on a theme file with more than colours"
grep -q 'primary: "#ffffff"' "$config" && ! grep -q pwned "$config" || fail "only theme.colors reaches gh-dash's config" "$(cat "$config")"
printf 'theme:\n  colors:\n    text:\n      primary: "red; touch pwned"\n' >"$home/.local/state/maitri/current/theme/gh-dash.yml"
run_hook "$home"
! grep -q pwned "$config" && grep -qF "gh-dash.yml has a line maitri doesn't apply" "$home/hook.stderr" ||
  fail "a theme value that isn't a colour is skipped" "$(cat "$config" "$home/hook.stderr")"
pass "only colours from the theme reach gh-dash's config"

home=$(new_home quoted amethyst)
config="$home/.config/gh-dash/config.yml"
mkdir -p "$home/.config/gh-dash"
printf 'pager:\n  diff: ""\n"theme":\n  ui:\n    sectionsShowCount: false\n' >"$test_tmp/quoted.yml"
cp "$test_tmp/quoted.yml" "$config"
run_hook "$home" || fail "the hook runs on a quoted theme key"
colors_match "$config" "$home/.local/state/maitri/current/theme/gh-dash.yml" && [[ $(grep -c theme "$config") == 3 ]] ||
  fail "a quoted theme key gets the colours under it" "$(cat "$config")"
cmp -s <(without_block "$config") "$test_tmp/quoted.yml" || fail "a quoted theme key keeps the rest of the config"
for case in '"theme": {}|on one line' "'theme': null|on one line" '{pager: {diff: ""}, theme: {}}|in a way maitri can'"'"'t edit' \
  '&mine theme: {}|in a way maitri can'"'"'t edit'; do
  line=${case%|*}
  printf '%s\n' "$line" >"$config"
  : >"$home/hook.stderr"
  run_hook "$home" || fail "the hook runs on $line"
  [[ $(<"$config") == "$line" ]] && grep -qF "${case#*|}" "$home/hook.stderr" ||
    fail "a theme maitri can't edit is left alone with a notice: $line" "$(cat "$config" "$home/hook.stderr")"
done
pass "a quoted theme key is edited, and one maitri can't edit is left alone"

home=$(new_home duplicate amethyst)
config="$home/.config/gh-dash/config.yml"
mkdir -p "$home/.config/gh-dash"
printf 'pager:\n  diff: ""\npager:\n  diff: less\n' >"$config"
cp "$config" "$test_tmp/duplicate.yml"
run_hook "$home" || fail "the hook runs on a duplicate key"
cmp -s "$config" "$test_tmp/duplicate.yml" && grep -qF "isn't valid YAML" "$home/hook.stderr" ||
  fail "a config that sets a key twice is left alone with a notice" "$(cat "$config" "$home/hook.stderr")"
pass "a config that sets a key twice is left alone, as gh-dash would refuse it"

home=$(new_home include amethyst)
config="$home/.config/gh-dash/config.yml"
mkdir -p "$home/.config/gh-dash"
printf 'include:\n  - colours.yml\ntheme:\n  ui:\n    sectionsShowCount: false\n' >"$config"
cp "$config" "$test_tmp/include.yml"
run_hook "$home" || fail "the hook runs on a config with include"
cmp -s "$config" "$test_tmp/include.yml" && grep -qF "includes other files" "$home/hook.stderr" ||
  fail "a config that includes other files is left alone with a notice" "$(cat "$config" "$home/hook.stderr")"
pass "a config that includes other files is left alone"

home=$(new_home tampered amethyst)
config="$home/.config/gh-dash/config.yml"
mkdir -p "$home/.config/gh-dash"
printf 'theme:\n  ui:\n    sectionsShowCount: false\n' >"$config"
run_hook "$home"
# theme.ui moved inside the block, then a comment added to it.
{ head -n -3 "$config"; tail -n 2 "$config"; tail -n 3 "$config" | head -n 1; } >"$test_tmp/tampered.yml"
sed '/^    text:$/a\      # picked by hand' "$config" >"$test_tmp/commented.yml"
for fixture in tampered commented; do
  cp "$test_tmp/$fixture.yml" "$config"
  : >"$home/hook.stderr"
  run_hook "$home" || fail "the hook runs on a block the user edited ($fixture)"
  cmp -s "$config" "$test_tmp/$fixture.yml" && grep -qF "more than colours between maitri's markers" "$home/hook.stderr" ||
    fail "a block holding more than maitri's colours is left alone with a notice ($fixture)" "$(cat "$config" "$home/hook.stderr")"
done
pass "a block holding more than maitri's colours is left alone"

home=$(new_home crlf amethyst)
config="$home/.config/gh-dash/config.yml"
mkdir -p "$home/.config/gh-dash"
sed 's/$/\r/' "$test_tmp/ui.yml" >"$test_tmp/crlf.yml"
cp "$test_tmp/crlf.yml" "$config"
run_hook "$home" || fail "the hook runs on a CRLF config"
colors_match "$config" "$home/.local/state/maitri/current/theme/gh-dash.yml" || fail "a CRLF config gets the colours" "$(cat -A "$config")"
cmp -s <(without_block "$config") "$test_tmp/crlf.yml" && ! grep -qv $'\r$' "$config" ||
  fail "a CRLF config keeps its bytes and line endings" "$(cat -A "$config")"
cp "$config" "$test_tmp/crlf-amethyst.yml"
set_theme "$home" daybreak
run_hook "$home"
set_theme "$home" amethyst
run_hook "$home"
cmp -s "$config" "$test_tmp/crlf-amethyst.yml" || fail "switching back restores a CRLF config exactly" "$(cat -A "$config")"
pass "a CRLF config keeps its line endings"

if (( EUID != 0 )); then
  home=$(new_home readonly amethyst)
  config="$home/.config/gh-dash/config.yml"
  mkdir -p "$home/.config/gh-dash"
  cp "$test_tmp/ui.yml" "$config"
  chmod 444 "$config"
  run_hook "$home" || fail "the hook runs on a read-only config"
  cmp -s "$config" "$test_tmp/ui.yml" && grep -qF "it's read-only" "$home/hook.stderr" ||
    fail "a read-only config is left alone with a notice" "$(cat "$config" "$home/hook.stderr")"
  chmod 644 "$config"
  chmod 555 "$home/.config/gh-dash"
  : >"$home/hook.stderr"
  run_hook "$home" || fail "the hook runs when it can't write next to the config"
  chmod 755 "$home/.config/gh-dash"
  cmp -s "$config" "$test_tmp/ui.yml" && grep -qF "can't write to its folder" "$home/hook.stderr" && ! grep -q Traceback "$home/hook.stderr" ||
    fail "a read-only folder is left alone with a notice" "$(cat "$home/hook.stderr")"
  pass "a read-only config or folder is left alone with a notice"
else
  skip "a read-only config or folder is left alone with a notice (root can write anything)"
fi
