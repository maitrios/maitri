#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

require_command python3
require_command jq

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

  for file in slack.txt insomnia-theme.json fish.fish; do
    [[ -f $next_theme/$file ]] || fail "$theme renders $file"
    ! grep -q '{{' "$next_theme/$file" || fail "$theme leaves no placeholders in $file" "$(grep -n '{{' "$next_theme/$file")"
  done
  themes+=("$theme")
done

(( ${#themes[@]} == 6 )) || fail "all six themes are rendered" "rendered: ${themes[*]}"

python3 - "$test_tmp" "${themes[@]}" <<'PY'
import json, re, sys

root, themes = sys.argv[1], sys.argv[2:]
TEXT, LINE = 4.5, 3.0
failed = False


def parse(color, base=None):
    m = re.fullmatch(r"rgba\((\d+),\s*(\d+),\s*(\d+),\s*([0-9.]+)\)", color)
    if m:
        rgb, a = tuple(int(m.group(i)) for i in (1, 2, 3)), float(m.group(4))
        if base is None:
            return rgb
        return tuple(round(t * a + b * (1 - a)) for t, b in zip(rgb, parse(base)))
    color = color.lstrip("#")
    return tuple(int(color[i:i + 2], 16) for i in (0, 2, 4))


def flat(color, base):
    return "#%02x%02x%02x" % parse(color, base)


def luminance(rgb):
    def channel(value):
        value /= 255
        return value / 12.92 if value <= 0.03928 else ((value + 0.055) / 1.055) ** 2.4
    r, g, b = rgb
    return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)


def contrast(fg, bg):
    a, b = sorted((luminance(parse(fg, bg)), luminance(parse(bg))), reverse=True)
    return (a + 0.05) / (b + 0.05)


def same(a, b):
    return a is not None and b is not None and a.lstrip("#").lower() == b.lstrip("#").lower()


class Check:
    def __init__(self, theme, app, palette):
        self.theme, self.app, self.p = theme, app, palette
        self.errors = []
        self.low = {TEXT: 99.0, LINE: 99.0}
        self.pairs = []

    def floor(self, label, fg, bg, minimum=TEXT):
        if fg is None or bg is None:
            self.errors.append(f"{label}: missing color ({fg} on {bg})")
            return
        ratio = contrast(fg, bg)
        self.low[minimum] = min(self.low[minimum], ratio)
        self.pairs.append((label, ratio, minimum))
        if ratio < minimum:
            self.errors.append(f"{label}: {ratio:.2f}:1 ({fg} on {bg}), floor {minimum}:1")

    def role(self, label, got, role):
        if not same(got, self.p[role]):
            self.errors.append(f"{label} is {got}, expected {role} {self.p[role]}")

    def expect(self, condition, message):
        if not condition:
            self.errors.append(message)

    def report(self):
        global failed
        name = f"{self.theme} {self.app}"
        with open(f"{root}/{self.theme}/{self.app}.ratios", "w") as out:
            for label, ratio, minimum in self.pairs:
                out.write(f"{label}\t{ratio:.2f}\t{minimum}\n")
        if self.errors:
            failed = True
            print("\n".join(f"  {e}" for e in self.errors), file=sys.stderr)
            print(f"not ok - {name} meets the contrast floors and the shared mapping", file=sys.stderr)
        else:
            lines = f", lines {self.low[LINE]:.2f}:1" if self.low[LINE] < 99 else ""
            print(f"ok - {name} meets the contrast floors and the shared mapping (text {self.low[TEXT]:.2f}:1{lines})")


def slack(theme, p, path):
    c = Check(theme, "slack", p)
    text = open(path).read().strip()
    c.expect(re.fullmatch(r"#[0-9A-Fa-f]{6}(,#[0-9A-Fa-f]{6}){3}", text), f"slack.txt is {text!r}, not four hex colours")
    nav, selected, presence, badge = text.split(",")
    c.role("the sidebar", nav, "dark_background")
    c.role("selected items", selected, "selection")
    c.role("presence", presence, "green")
    c.role("notifications", badge, "red")
    c.floor("text on the sidebar", p["foreground"], nav)
    c.floor("text on a selected item", p["foreground"], selected)
    c.floor("the presence dot on the sidebar", presence, nav, LINE)
    c.floor("the mention badge on the sidebar", badge, nav, LINE)
    c.report()


def insomnia(theme, p, path):
    c = Check(theme, "insomnia", p)
    doc = json.load(open(path))
    t = doc["theme"]
    s = t["styles"]
    c.expect(doc["name"] == "maitri", "the Insomnia theme is not named maitri")
    statuses = ["success", "notice", "warning", "danger", "surprise", "info"]

    def colors(node, trail=""):
        for key, value in node.items():
            if isinstance(value, dict):
                yield from colors(value, f"{trail}{key}.")
            else:
                yield f"{trail}{key}", value
    for key, value in colors(t):
        c.expect(re.fullmatch(r"#[0-9A-Fa-f]{6}|rgba\(\d+,\s*\d+,\s*\d+,\s*[0-9.]+\)", value), f"{key} is {value}")

    bg = t["background"]["default"]
    surfaces = {
        "the app": bg,
        "the app header": s["appHeader"]["background"]["default"],
        "the sidebar": s["sidebar"]["background"]["default"],
        "a pane": s["pane"]["background"]["default"],
        "a dialog": s["dialog"]["background"]["default"],
        "the editor": s["editor"]["background"]["default"],
    }
    hl = t["highlight"]
    for name, surface in surfaces.items():
        c.floor(f"text on {name}", t["foreground"]["default"], surface)
        c.floor(f"muted text on {name}", hl["default"], surface)
        for level in ("sm", "md", "lg"):
            c.floor(f"hl-{level} borders on {name}", hl[level], surface, LINE)
        for row in ("xxs", "xs"):
            c.floor(f"text on an hl-{row} row on {name}", t["foreground"]["default"], flat(hl[row], surface))
    for status in statuses:
        for name, surface in (("the app", bg), ("the sidebar", surfaces["the sidebar"]), ("a dialog", surfaces["a dialog"])):
            c.floor(f"{status} text on {name}", s["sidebar"]["background"][status] if name == "the sidebar" else t["background"][status], surface)
        for name, surface in (("the sidebar", surfaces["the sidebar"]), ("the app", bg), ("a pane", surfaces["a pane"])):
            pill = s["sidebar"]["background"][status] if name == "the sidebar" else t["background"][status]
            c.floor(f"{status} tag text on a half-strength pill on {name}", t["foreground"][status], flat("rgba(%d,%d,%d,0.5)" % parse(pill), surface))
        c.floor(f"editor {status} tokens", s["editor"]["background"][status], surfaces["the editor"])
    c.floor("links", s["link"]["foreground"]["default"], bg)
    c.floor("text over the overlay", t["foreground"]["default"], flat(s["transparentOverlay"]["background"]["default"], bg))

    c.role("success", t["background"]["success"], "green")
    c.role("warning", t["background"]["warning"], "orange")
    c.role("danger", t["background"]["danger"], "red")
    c.role("surprise", t["background"]["surprise"], "accent")
    c.role("muted text", hl["default"], "comment")
    c.role("borders", hl["md"], "border")
    c.role("focused borders", hl["lg"], "border_focus")
    c.role("links", s["link"]["foreground"]["default"], "link")
    editor = s["editor"]["background"]
    c.role("editor strings", editor["notice"], "yellow")
    c.role("editor numbers and constants", editor["surprise"], "blue")
    c.role("editor properties", editor["success"], "orange")
    c.role("editor builtins", editor["info"], "cyan")
    c.role("editor errors", editor["danger"], "red")
    c.report()


def fish(theme, p, path):
    c = Check(theme, "fish", p)
    variables = {}
    for line in open(path):
        line = line.strip()
        if not line:
            continue
        words = line.split()
        c.expect(words[:2] == ["set", "-U"] and re.fullmatch(r"fish_(pager_)?color_[a-z_]+", words[2]), f"fish.fish line {line!r}")
        variables[words[2]] = words[3:]

    def fg(name):
        return next((w for w in variables[name] if re.fullmatch(r"[0-9A-Fa-f]{6}", w)), None)

    def bg(name):
        return next((w.split("=", 1)[1] for w in variables[name] if w.startswith("--background=")), None)

    background = p["background"]
    selection = p["selection"]
    for name in variables:
        color = fg(name)
        if color is None:
            continue
        if name.startswith("fish_pager_color_selected_"):
            under = selection
        else:
            under = bg(name) or background
        c.floor(name, color, under)
    for name in ("fish_color_comment", "fish_color_autosuggestion"):
        c.floor(f"{name} on the terminal", fg(name), background)

    c.role("fish_color_normal", fg("fish_color_normal"), "foreground")
    c.role("fish_color_command", fg("fish_color_command"), "green")
    c.role("fish_color_builtin", fg("fish_color_builtin"), "cyan")
    c.role("fish_color_keyword", fg("fish_color_keyword"), "magenta")
    c.role("fish_color_quote", fg("fish_color_quote"), "yellow")
    for name in ("fish_color_redirection", "fish_color_end", "fish_color_operator", "fish_color_escape"):
        c.role(name, fg(name), "magenta")
    c.role("fish_color_param", fg("fish_color_param"), "foreground")
    c.role("fish_color_option", fg("fish_color_option"), "orange")
    c.role("fish_color_error", fg("fish_color_error"), "red")
    c.role("fish_color_comment", fg("fish_color_comment"), "comment")
    c.expect("--italics" in variables["fish_color_comment"], "comments are not italic")
    c.role("fish_color_autosuggestion", fg("fish_color_autosuggestion"), "comment")
    c.role("fish_color_selection", bg("fish_color_selection"), "selection")
    c.role("fish_color_search_match", bg("fish_color_search_match"), "selection")
    c.role("fish_pager_color_selected_background", bg("fish_pager_color_selected_background"), "selection")
    c.role("fish_pager_color_prefix", fg("fish_pager_color_prefix"), "accent")
    c.expect(variables["fish_color_valid_path"] == ["--underline"], "valid paths only add an underline")
    c.report()


for theme in themes:
    palette = dict(line.rstrip("\n").split("\t", 1) for line in open(f"{root}/{theme}/palette.tsv"))
    rendered = f"{root}/{theme}/.local/state/maitri/current/next-theme"
    slack(theme, palette, f"{rendered}/slack.txt")
    insomnia(theme, palette, f"{rendered}/insomnia-theme.json")
    fish(theme, palette, f"{rendered}/fish.fish")

sys.exit(1 if failed else 0)
PY

if [[ -n ${MAITRI_THEME_APPS_RATIOS:-} ]]; then
  for theme in "${themes[@]}"; do
    for app in slack insomnia fish; do
      sed "s/^/$theme\t$app\t/" "$test_tmp/$theme/$app.ratios"
    done
  done >"$MAITRI_THEME_APPS_RATIOS"
fi

pass "Slack, Insomnia and fish render for every theme with readable contrast and the shared mapping"

sandbox="$test_tmp/sandbox-bin"
apps="$test_tmp/app-bin"
mkdir -p "$sandbox" "$apps"
for tool in cat grep jq mkdir mktemp mv tr; do
  ln -s "$(command -v "$tool")" "$sandbox/$tool"
done
for app in slack insomnia; do
  printf '#!/bin/bash\n' >"$apps/$app"
  chmod +x "$apps/$app"
done
printf '#!/bin/bash\ncat >"$HOME/clipboard"\n' >"$apps/wl-copy"
chmod +x "$apps/wl-copy"

run_hook() {
  local home="$1" hook="$2" path="$3"

  env -u XDG_CONFIG_HOME -u XDG_DATA_HOME HOME="$home" MAITRI_PATH="$ROOT" PATH="$ROOT/bin:$path" "$BASH" "$ROOT/bin/$hook" 2>>"$home/hook.stderr"
}

stage_theme() {
  local home="$1" theme="$2"

  mkdir -p "$home/.local/state/maitri/current"
  rm -rf "$home/.local/state/maitri/current/theme"
  cp -r "$test_tmp/$theme/.local/state/maitri/current/next-theme" "$home/.local/state/maitri/current/theme"
}

hooks=(maitri-theme-set-slack maitri-theme-set-insomnia maitri-theme-set-fish)

home="$test_tmp/hooks-missing"
stage_theme "$home" amethyst
: >"$home/hook.stderr"
for hook in "${hooks[@]}"; do
  run_hook "$home" "$hook" "$sandbox" || fail "$hook exits cleanly when its app is missing"
done
[[ ! -e $home/.config ]] || fail "the app hooks leave no files behind when the apps are missing" "$(find "$home/.config")"
[[ ! -s $home/hook.stderr ]] || fail "the app hooks stay quiet when the apps are missing" "$(cat "$home/hook.stderr")"

for theme in amethyst daybreak; do
  home="$test_tmp/hooks-$theme"
  stage_theme "$home" "$theme"
  : >"$home/hook.stderr"
  rendered="$home/.local/state/maitri/current/theme"

  run_hook "$home" maitri-theme-set-slack "$apps:$sandbox" || fail "maitri-theme-set-slack runs with Slack present"
  grep -q "maitri theme slack-copy" "$home/hook.stderr" || fail "theme set tells a Slack user how to paste the colours" "$(cat "$home/hook.stderr")"
  (( $(wc -l <"$home/hook.stderr") == 1 )) || fail "the Slack hint is one line" "$(cat "$home/hook.stderr")"
  [[ ! -e $home/.config ]] || fail "the Slack hook writes nothing"

  output=$(run_hook "$home" maitri-theme-slack-copy "$apps:$sandbox") || fail "maitri-theme-slack-copy copies the $theme colours"
  [[ $(<"$home/clipboard") == "$(tr -d '[:space:]' <"$rendered/slack.txt")" ]] || fail "the clipboard holds the $theme Slack theme string" "$(cat "$home/clipboard")"
  [[ $output == *"Appearance > Custom theme"* ]] || fail "maitri-theme-slack-copy says where to paste" "$output"

  : >"$home/hook.stderr"
  run_hook "$home" maitri-theme-set-insomnia "$apps:$sandbox" || fail "maitri-theme-set-insomnia installs the $theme theme"
  plugin="$home/.config/Insomnia/plugins/insomnia-plugin-maitri"
  [[ -f $plugin/package.json && -f $plugin/index.js ]] || fail "Insomnia gets the maitri theme plugin"
  [[ $(jq -r .name "$plugin/package.json") == "insomnia-plugin-maitri" && $(jq -r .insomnia.name "$plugin/package.json") == "maitri" ]] ||
    fail "the Insomnia plugin manifest names the maitri plugin" "$(cat "$plugin/package.json")"
  grep -q "Preferences > Themes" "$home/hook.stderr" || fail "the Insomnia hook says a restart or reload is needed" "$(cat "$home/hook.stderr")"
  [[ -z $(find "$home/.config/Insomnia/plugins" -name '.maitri-theme.*') ]] || fail "the Insomnia hook leaves no staging file behind"
  if command -v node >/dev/null 2>&1; then
    got=$(node -e 'const t = require(process.argv[1]).themes; console.log(t.length, t[0].name, t[0].theme.background.default)' "$plugin") ||
      fail "the Insomnia plugin loads in Node"
    expected=$(jq -r '"1 maitri " + .theme.background.default' "$rendered/insomnia-theme.json")
    [[ $got == "$expected" ]] || fail "the Insomnia plugin exports the $theme theme" "got $got, expected $expected"
  fi
done

home="$test_tmp/hooks-hostile"
stage_theme "$home" amethyst
mkdir -p "$home/.config/Insomnia"
: >"$home/hook.stderr"
printf '{"theme": {}}]; require("child_process").execSync("touch %s/pwned"); [{\n' "$home" >"$home/.local/state/maitri/current/theme/insomnia-theme.json"
run_hook "$home" maitri-theme-set-insomnia "$sandbox" || fail "maitri-theme-set-insomnia skips a theme file that isn't JSON"
[[ ! -e $home/.config/Insomnia/plugins/insomnia-plugin-maitri/index.js ]] || fail "Insomnia never gets a plugin from a theme file that isn't JSON"
printf '{"theme": "#ffffff"}\n' >"$home/.local/state/maitri/current/theme/insomnia-theme.json"
run_hook "$home" maitri-theme-set-insomnia "$sandbox" || fail "maitri-theme-set-insomnia skips a theme file without a theme object"
[[ ! -e $home/.config/Insomnia/plugins/insomnia-plugin-maitri/index.js ]] || fail "Insomnia never gets a plugin without a theme object"
(( $(grep -c "Skipping Insomnia theme" "$home/hook.stderr") == 2 )) || fail "the Insomnia hook says why it skipped" "$(cat "$home/hook.stderr")"
printf '{"theme": {"background": {"default": "#000000"}, "rawCss": "@import url(https://example.com/x.css);"}}\n' >"$home/.local/state/maitri/current/theme/insomnia-theme.json"
run_hook "$home" maitri-theme-set-insomnia "$sandbox" || fail "maitri-theme-set-insomnia installs a theme that ships rawCss"
plugin="$home/.config/Insomnia/plugins/insomnia-plugin-maitri"
[[ -f $plugin/index.js ]] && ! grep -q rawCss "$plugin/index.js" || fail "Insomnia never gets a theme's rawCss" "$(cat "$plugin/index.js")"

printf '#a1b2c3,#a1b2c3\n' >"$home/.local/state/maitri/current/theme/slack.txt"
! run_hook "$home" maitri-theme-slack-copy "$apps:$sandbox" >/dev/null || fail "maitri-theme-slack-copy refuses a slack.txt that isn't a Slack theme"
[[ ! -e $home/clipboard ]] || fail "a slack.txt that isn't a Slack theme never reaches the clipboard"

broken="$test_tmp/broken-bin"
mkdir -p "$broken"
printf '#!/bin/bash\nexit 1\n' >"$broken/wl-copy"
chmod +x "$broken/wl-copy"
cp "$test_tmp/amethyst/.local/state/maitri/current/next-theme/slack.txt" "$home/.local/state/maitri/current/theme/slack.txt"
! output=$(run_hook "$home" maitri-theme-slack-copy "$broken:$apps:$sandbox") || fail "maitri-theme-slack-copy fails when wl-copy does"
[[ $output != *Copied* ]] || fail "maitri-theme-slack-copy never says it copied when wl-copy failed" "$output"

pass "the Slack and Insomnia hooks install only for apps that are present and say what a user has to do"

if ! command -v fish >/dev/null 2>&1; then
  skip "fish takes the theme as universal variables (fish is not installed)"
  exit 0
fi

ln -s "$(command -v fish)" "$apps/fish"

fish_get() {
  local home="$1"
  shift

  env -u XDG_CONFIG_HOME -u XDG_DATA_HOME HOME="$home" fish -c 'for name in $argv; set -S $name | string match -q "*universal*"; or echo "$name is not universal"; echo "$name=$$name"; end' -- "$@"
}

home="$test_tmp/hooks-fish"
stage_theme "$home" amethyst
: >"$home/hook.stderr"
run_hook "$home" maitri-theme-set-fish "$apps:$sandbox:$PATH" || fail "maitri-theme-set-fish sets the amethyst colours"
amethyst_green=$(awk -F'\t' '$1 == "green" { print substr($2, 2) }' "$test_tmp/amethyst/palette.tsv")
amethyst_selection=$(awk -F'\t' '$1 == "selection" { print substr($2, 2) }' "$test_tmp/amethyst/palette.tsv")
got=$(fish_get "$home" fish_color_command fish_pager_color_selected_background fish_color_valid_path)
expected="fish_color_command=$amethyst_green
fish_pager_color_selected_background=--background=$amethyst_selection
fish_color_valid_path=--underline"
[[ $got == "$expected" ]] || fail "fish gets the amethyst colours as universal variables" "$got"
[[ ! -s $home/hook.stderr ]] || fail "the fish hook is quiet on a clean config" "$(cat "$home/hook.stderr")"
first=$(grep -c '^SETUVAR fish_' "$home/.config/fish/fish_variables")
(( first == $(grep -c '^set -U' "$home/.local/state/maitri/current/theme/fish.fish") )) || fail "fish gets every colour in fish.fish"

run_hook "$home" maitri-theme-set-fish "$apps:$sandbox:$PATH" || fail "maitri-theme-set-fish runs again"
stage_theme "$home" daybreak
run_hook "$home" maitri-theme-set-fish "$apps:$sandbox:$PATH" || fail "maitri-theme-set-fish switches to daybreak"
(( $(grep -c '^SETUVAR fish_' "$home/.config/fish/fish_variables") == first )) || fail "switching themes leaves the same set of fish colours"
daybreak_green=$(awk -F'\t' '$1 == "green" { print substr($2, 2) }' "$test_tmp/daybreak/palette.tsv")
[[ $(fish_get "$home" fish_color_command) == "fish_color_command=$daybreak_green" ]] || fail "fish follows the switch to daybreak" "$(fish_get "$home" fish_color_command)"

mkdir -p "$home/.config/fish/conf.d"
printf 'set --global fish_color_command red\n' >"$home/.config/fish/conf.d/fish_frozen_theme.fish"
run_hook "$home" maitri-theme-set-fish "$apps:$sandbox:$PATH" || fail "maitri-theme-set-fish runs beside a frozen theme"
grep -q "fish_frozen_theme.fish sets colours globally" "$home/hook.stderr" || fail "the fish hook says when a global colour hides the theme" "$(cat "$home/hook.stderr")"
rm "$home/.config/fish/conf.d/fish_frozen_theme.fish"

for line in 'set -gx fish_color_command red' 'fish_config theme choose "Tomorrow Night"'; do
  : >"$home/hook.stderr"
  printf '%s\n' "$line" >"$home/.config/fish/config.fish"
  run_hook "$home" maitri-theme-set-fish "$apps:$sandbox:$PATH" || fail "maitri-theme-set-fish runs beside $line"
  grep -q "config.fish sets colours globally" "$home/hook.stderr" || fail "the fish hook says that $line hides the theme" "$(cat "$home/hook.stderr")"
done
rm "$home/.config/fish/config.fish"

: >"$home/hook.stderr"
printf 'set -U fish_color_command (touch %s/pwned)\n' "$home" >"$home/.local/state/maitri/current/theme/fish.fish"
run_hook "$home" maitri-theme-set-fish "$apps:$sandbox:$PATH" || fail "maitri-theme-set-fish skips a fish.fish that isn't colours"
[[ ! -e $home/pwned ]] || fail "a fish.fish that isn't colours never runs"
[[ $(fish_get "$home" fish_color_command) == "fish_color_command=$daybreak_green" ]] || fail "a fish.fish that isn't colours changes nothing"
grep -q "isn't a colour" "$home/hook.stderr" || fail "the fish hook says why it skipped" "$(cat "$home/hook.stderr")"

: >"$home/hook.stderr"
printf '# a theme of my own\nset -U fish_color_command %s' "$amethyst_green" >"$home/.local/state/maitri/current/theme/fish.fish"
run_hook "$home" maitri-theme-set-fish "$apps:$sandbox:$PATH" || fail "maitri-theme-set-fish takes a shorter fish.fish"
[[ $(fish_get "$home" fish_color_command) == "fish_color_command=$amethyst_green" ]] || fail "fish gets the last line of a fish.fish without a final newline" "$(fish_get "$home" fish_color_command)"
(( $(grep -cE '^SETUVAR fish_(pager_)?color_' "$home/.config/fish/fish_variables") == 1 )) || fail "a shorter fish.fish leaves none of the previous theme's colours" "$(grep SETUVAR "$home/.config/fish/fish_variables")"
[[ ! -s $home/hook.stderr ]] || fail "a comment in fish.fish is skipped quietly" "$(cat "$home/hook.stderr")"

pass "fish takes the theme as universal variables, idempotently, and never runs a theme's fish.fish"
