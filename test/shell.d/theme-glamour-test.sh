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

  [[ -f $next_theme/glamour.json ]] || fail "$theme renders glamour.json"
  ! grep -q '{{' "$next_theme/glamour.json" ||
    fail "$theme leaves no placeholders in glamour.json" "$(grep -n '{{' "$next_theme/glamour.json")"
  themes+=("$theme")
done

(( ${#themes[@]} > 0 )) || fail "themes are rendered"

python3 - "$test_tmp" "${themes[@]}" <<'PY'
import json, math, sys

root, themes = sys.argv[1], sys.argv[2:]
TEXT, LINE = 4.5, 3.0
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


def lift(color, target, against, minimum):
    for step in range(51):
        amount = step / 50
        lifted = "#%02x%02x%02x" % tuple(int(s + (t - s) * amount + 0.5) for s, t in zip(rgb(color), rgb(target)))
        if contrast(lifted, against) >= minimum:
            break
    return lifted


def same(a, b):
    return a is not None and b is not None and a.lstrip("#").lower() == b.lstrip("#").lower()


# Code blocks go through chroma's terminal256 formatter, which rounds every
# token to the nearest xterm-256 colour. Its table holds the cube and grey ramp
# plus system colours 1-7, which a themed terminal shows as the palette's own.
LEVELS = (0, 95, 135, 175, 215, 255)
XTERM = {i: "#%02x%02x%02x" % (LEVELS[(i - 16) // 36], LEVELS[(i - 16) // 6 % 6], LEVELS[(i - 16) % 6]) for i in range(16, 232)}
XTERM.update({i: "#%02x%02x%02x" % ((8 + 10 * (i - 232),) * 3) for i in range(232, 256)})
XTERM.update({1: "#800000", 2: "#008000", 3: "#808000", 4: "#000080", 5: "#800080", 6: "#008080", 7: "#c0c0c0"})
SYSTEM = {1: "red", 2: "green", 3: "yellow", 4: "blue", 5: "magenta", 6: "cyan", 7: "foreground"}


def chroma_distance(a, b):
    (ar, ag, ab), (br, bg, bb) = rgb(a), rgb(b)
    rmean = (ar + br) // 2
    r, g, b = ar - br, ag - bg, ab - bb
    return math.sqrt((((512 + rmean) * r * r) >> 8) + 4 * g * g + (((767 - rmean) * b * b) >> 8))


def terminal256(color, palette):
    index = min(XTERM, key=lambda i: chroma_distance(XTERM[i], color))
    return palette[SYSTEM[index]] if index in SYSTEM else XTERM[index]


CHROMA = {
    "text": "foreground", "name": "foreground", "name_other": "foreground",
    "error": "red", "generic_deleted": "red",
    "comment": "comment",
    "comment_preproc": "magenta", "keyword": "magenta", "keyword_reserved": "magenta", "keyword_namespace": "magenta",
    "operator": "magenta", "literal_string_escape": "magenta",
    "keyword_type": "cyan", "name_builtin": "cyan", "name_tag": "cyan", "name_class": "cyan", "name_exception": "cyan",
    "punctuation": "light_foreground",
    "name_attribute": "green", "name_decorator": "green", "name_function": "green", "generic_inserted": "green",
    "name_constant": "blue", "literal": "blue", "literal_number": "blue", "literal_date": "blue", "generic_subheading": "blue",
    "literal_string": "yellow",
}
ITALIC = {"comment", "keyword_type", "name_attribute", "name_class", "name_decorator", "name_exception"}


class Check:
    def __init__(self, theme, palette):
        self.theme, self.p = theme, palette
        self.errors = []
        self.low = {TEXT: 99.0, LINE: 99.0, "code": 99.0}

    def floor(self, label, fg, bg, minimum=TEXT, bucket=None):
        if fg is None or bg is None:
            self.errors.append(f"{label}: missing color ({fg} on {bg})")
            return
        ratio = contrast(fg, bg)
        key = bucket or minimum
        self.low[key] = min(self.low[key], ratio)
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
        name = f"{self.theme} glamour"
        if self.errors:
            failed = True
            print("\n".join(f"  {e}" for e in self.errors), file=sys.stderr)
            print(f"not ok - {name} meets the contrast floors and the shared mapping", file=sys.stderr)
        else:
            print(f"ok - {name} meets the contrast floors and the shared mapping "
                  f"(text {self.low[TEXT]:.2f}:1, lines {self.low[LINE]:.2f}:1, code after 256-colour rounding {self.low['code']:.2f}:1)")


for theme in themes:
    palette = dict(line.rstrip("\n").split("\t", 1) for line in open(f"{root}/{theme}/palette.tsv"))
    doc = json.load(open(f"{root}/{theme}/.local/state/maitri/current/next-theme/glamour.json"))
    c = Check(theme, palette)
    bg = palette["background"]

    c.expect(not doc["text"].get("color"), "text sets a colour, which repaints heading text over the heading colour")
    c.role("document (the quote bar)", doc["document"].get("color"), "border")
    c.expect(doc["block_quote"].get("indent_token", "").strip() == "│", "block quotes are drawn with a bar")
    c.expect(not doc["block_quote"].get("color"), "block_quote sets a colour, which the bar never takes")
    c.role("hr", doc["hr"].get("color"), "border")
    c.floor("quote bar", doc["document"]["color"], bg, LINE)
    c.floor("hr", doc["hr"]["color"], bg, LINE)

    for key in ["paragraph", "list", "table", "definition_list", "code_block"]:
        c.role(key, doc[key].get("color"), "foreground")
    for key in ["link", "link_text", "image"]:
        c.role(key, doc[key].get("color"), "link")
    c.expect(doc["link"].get("underline"), "link URLs are underlined")
    c.role("strong", doc["strong"].get("color"), "bright_foreground")
    for key in ["strikethrough", "image_text", "html_block", "html_span"]:
        c.role(key, doc[key].get("color"), "comment")

    for level in range(1, 7):
        h = doc[f"h{level}"]
        expected = mix(palette["accent"], palette["foreground"], (level - 1) * 0.13)
        c.expect(same(h.get("color"), expected), f"H{level} is {h.get('color')}, expected {expected}")
        c.expect(h.get("bold"), f"H{level} is not bold")
        c.expect(h.get("prefix") == "#" * level + " ", f"H{level} prefix is {h.get('prefix')!r}")
    c.role("heading", doc["heading"].get("color"), "accent")

    for key in ["paragraph", "list", "table", "definition_list", "strong", "strikethrough", "link", "link_text",
                "image", "image_text", "html_block", "html_span", "heading"] + [f"h{n}" for n in range(1, 7)]:
        c.floor(key, doc[key].get("color"), bg)

    code = doc["code"]
    c.role("code background", code.get("background_color"), "lighter_background")
    c.expect(same(code.get("color"), lift(palette["cyan"], palette["foreground"], palette["lighter_background"], TEXT)),
             f"inline code is {code.get('color')}, expected cyan made readable on lighter_background")
    c.floor("inline code", code.get("color"), code.get("background_color"))

    chroma = doc["code_block"]["chroma"]
    c.role("chroma background", chroma["background"].get("background_color"), "background")
    lift_surface = mix(palette["darker_background"], palette["muted"], 0.10)
    for token, role in CHROMA.items():
        got = chroma[token].get("color")
        if role == "foreground":
            c.role(f"chroma {token}", got, role)
        else:
            expected = lift(palette[role], palette["foreground"], lift_surface, TEXT)
            c.expect(same(got, expected), f"chroma {token} is {got}, expected {role} made readable ({expected})")
        c.expect(bool(chroma[token].get("italic")) == (token in ITALIC), f"chroma {token} italic is {chroma[token].get('italic')}")
        c.floor(f"chroma {token}", got, bg)
        c.floor(f"chroma {token} after 256-colour rounding", terminal256(got, palette), bg, bucket="code")

    if theme == "daybreak":
        c.expect(palette["mode"] == "light" and luminance(bg) > 0.5, "daybreak is checked on a light background")

    c.report()

sys.exit(1 if failed else 0)
PY

pass "glamour.json renders for every theme on the shared mapping and clears the contrast floors"

fish_config="$ROOT/config/fish/config.fish"
style_lines=$(grep -F '# maitri:glamour-style' "$fish_config") || fail "config.fish carries the marked glamour lines"
(( $(wc -l <<<"$style_lines") == 2 )) || fail "config.fish carries exactly two glamour lines"
grep -qF 'not set -q GLAMOUR_STYLE' <<<"$style_lines" && grep -qF 'not set -q GLOW_STYLE' <<<"$style_lines" ||
  fail "each glamour line only sets its variable when it is unset"

migration="$ROOT/migrations/1792260843.sh"

if command -v fish >/dev/null 2>&1; then
  tools="$test_tmp/tools"
  mkdir -p "$tools/gh" "$tools/glow" "$tools/none"
  printf '#!/bin/sh\n' >"$tools/gh/gh"
  printf '#!/bin/sh\n' >"$tools/glow/glow"
  chmod +x "$tools/gh/gh" "$tools/glow/glow"
  fish_bin=$(command -v fish)

  styles() {
    local home="$1" path="$2"
    shift 2
    env -u GLAMOUR_STYLE -u GLOW_STYLE HOME="$home" PATH="$path" "$@" "$fish_bin" --no-config -c "source '$fish_config'; echo \"\$GLAMOUR_STYLE|\$GLOW_STYLE\""
  }

  home="$test_tmp/fish-home"
  mkdir -p "$home"
  [[ $(styles "$home" "$tools/gh:$tools/glow") == "|" ]] ||
    fail "fish leaves GLAMOUR_STYLE and GLOW_STYLE unset before a theme renders glamour.json"

  mkdir -p "$home/.local/state/maitri/current/theme"
  cp "$test_tmp/daybreak/.local/state/maitri/current/next-theme/glamour.json" "$home/.local/state/maitri/current/theme/"
  style="$home/.local/state/maitri/current/theme/glamour.json"
  got=$(styles "$home" "$tools/gh:$tools/glow")
  [[ $got == "$style|$style" ]] || fail "fish exports GLAMOUR_STYLE and GLOW_STYLE for the current theme" "$got"
  got=$(styles "$home" "$tools/gh")
  [[ $got == "$style|" ]] || fail "with only gh installed, fish exports GLAMOUR_STYLE alone" "$got"
  got=$(styles "$home" "$tools/none")
  [[ $got == "|" ]] || fail "without gh or glow, fish exports neither style" "$got"
  got=$(styles "$home" "$tools/gh:$tools/glow" GLAMOUR_STYLE="$home/mine.json" GLOW_STYLE="$home/mine-glow.json")
  [[ $got == "$home/mine.json|$home/mine-glow.json" ]] || fail "fish keeps a GLAMOUR_STYLE and GLOW_STYLE the user already set" "$got"
  got=$(GLAMOUR_STYLE=elsewhere GLOW_STYLE=elsewhere styles "$home" "$tools/none")
  [[ $got == "|" ]] || fail "the fish check ignores styles exported by the calling shell" "$got"
  pass "fish exports the glamour style only for gh and glow, once the theme has one, and never over the user's own"
else
  skip "fish is not installed; the glamour export was not run"
fi

stubs="$test_tmp/stubs"
mkdir -p "$stubs"
cat >"$stubs/maitri-theme-refresh" <<'SH'
#!/bin/bash
echo refreshed >>"$HOME/refresh.log"
mkdir -p "$HOME/.local/state/maitri/current/theme"
: >"$HOME/.local/state/maitri/current/theme/glamour.json"
SH
chmod +x "$stubs/maitri-theme-refresh"

run_migration() {
  env -u XDG_CONFIG_HOME HOME="$1" MAITRI_PATH="$ROOT" PATH="$stubs:$PATH" bash -euo pipefail "$migration" >/dev/null
}

home="$test_tmp/migration-home"
mkdir -p "$home/.config/fish" "$home/.local/state/maitri/current/theme"
printf 'set -gx FOO 1\n' >"$home/.config/fish/config.fish"
echo amethyst >"$home/.local/state/maitri/current/theme.name"
run_migration "$home" || fail "the glamour migration runs"
(( $(wc -l <"$home/refresh.log") == 1 )) || fail "the migration refreshes the theme once to render glamour.json"
run_migration "$home" || fail "the glamour migration runs twice"
[[ $(grep -F '# maitri:glamour-style' "$home/.config/fish/config.fish") == "$style_lines" ]] ||
  fail "the migration adds the lines config.fish ships, once"
grep -qx 'set -gx FOO 1' "$home/.config/fish/config.fish" || fail "the migration keeps the rest of config.fish"

home="$test_tmp/migration-theme-style"
mkdir -p "$home/.config/fish" "$home/.local/state/maitri/current/theme"
: >"$home/.config/fish/config.fish"
echo amethyst >"$home/.local/state/maitri/current/theme.name"
printf '{"h1":{"prefix":"theme"}}\n' >"$home/.local/state/maitri/current/theme/glamour.json"
run_migration "$home" || fail "the glamour migration runs over a glamour.json the theme supplied"
[[ -s $home/refresh.log && ! -s $home/.local/state/maitri/current/theme/glamour.json ]] ||
  fail "the migration re-renders a glamour.json the theme supplied, so the deny list applies"

failing_stubs="$test_tmp/failing-stubs"
mkdir -p "$failing_stubs"
cat >"$failing_stubs/maitri-theme-refresh" <<'SH'
#!/bin/bash
echo failed >>"$HOME/refresh.log"
exit 1
SH
chmod +x "$failing_stubs/maitri-theme-refresh"

home="$test_tmp/migration-refresh-fails"
mkdir -p "$home/.config/fish" "$home/.local/state/maitri/current/theme"
: >"$home/.config/fish/config.fish"
echo amethyst >"$home/.local/state/maitri/current/theme.name"
printf '{"h1":{"prefix":"theme"}}\n' >"$home/.local/state/maitri/current/theme/glamour.json"
env -u XDG_CONFIG_HOME HOME="$home" MAITRI_PATH="$ROOT" PATH="$failing_stubs:$PATH" bash -euo pipefail "$migration" >/dev/null 2>"$home/migration.stderr" ||
  fail "the glamour migration succeeds when the refresh fails, so the migration queue keeps moving"
[[ -s $home/refresh.log ]] || fail "the migration tries the refresh"
grep -q "Couldn't refresh the amethyst theme" "$home/migration.stderr" && grep -q "Open a new shell" "$home/migration.stderr" ||
  fail "the migration says the refresh failed and that glow needs a new shell" "$(<"$home/migration.stderr")"
[[ ! -e $home/.local/state/maitri/current/theme/glamour.json && -d $home/.local/state/maitri/current/theme ]] ||
  fail "a failed refresh drops the glamour.json the theme supplied, so the fish lines never reach it"
(( $(grep -cF '# maitri:glamour-style' "$home/.config/fish/config.fish") == 2 )) || fail "a failed refresh keeps the fish lines"

home="$test_tmp/migration-read-only"
mkdir -p "$home/.config/fish" "$home/.local/state/maitri/current/theme"
printf 'set -gx FOO 1\n' >"$home/.config/fish/config.fish"
chmod 444 "$home/.config/fish/config.fish"
echo amethyst >"$home/.local/state/maitri/current/theme.name"
notice=$(env -u XDG_CONFIG_HOME HOME="$home" MAITRI_PATH="$ROOT" PATH="$stubs:$PATH" bash -euo pipefail "$migration") ||
  fail "the glamour migration succeeds when config.fish is read-only, so the migration queue keeps moving"
grep -q "isn't writable" <<<"$notice" || fail "the migration says why it left a read-only config.fish alone" "$notice"
[[ $(<"$home/.config/fish/config.fish") == "set -gx FOO 1" ]] || fail "the migration leaves a read-only config.fish untouched"
[[ -s $home/refresh.log ]] || fail "the migration still renders glamour.json when config.fish is read-only"
chmod 644 "$home/.config/fish/config.fish"

home="$test_tmp/migration-xdg"
mkdir -p "$home/xdg/fish"
printf 'set -gx FOO 1\n' >"$home/xdg/fish/config.fish"
HOME="$home" XDG_CONFIG_HOME="$home/xdg" MAITRI_PATH="$ROOT" PATH="$stubs:$PATH" bash -euo pipefail "$migration" >/dev/null ||
  fail "the glamour migration runs with XDG_CONFIG_HOME set"
(( $(grep -cF '# maitri:glamour-style' "$home/xdg/fish/config.fish") == 2 )) || fail "the migration follows XDG_CONFIG_HOME"

if command -v fish >/dev/null 2>&1; then
  home="$test_tmp/migration-own-style"
  mkdir -p "$home/.config/fish" "$home/.local/state/maitri/current/theme"
  : >"$home/.local/state/maitri/current/theme/glamour.json"
  printf 'set -gx GLAMOUR_STYLE %s\n' "$home/mine.json" >"$home/.config/fish/config.fish"
  run_migration "$home" || fail "the glamour migration runs over a user's own style"
  got=$(env -u GLAMOUR_STYLE -u GLOW_STYLE HOME="$home" PATH="$tools/gh" "$fish_bin" --no-config -c "source '$home/.config/fish/config.fish'; echo \$GLAMOUR_STYLE")
  [[ $got == "$home/mine.json" ]] || fail "a user's own GLAMOUR_STYLE still wins after the migration" "$got"
fi

home="$test_tmp/migration-gone-theme"
mkdir -p "$home/.local/state/maitri/current"
echo retired-theme >"$home/.local/state/maitri/current/theme.name"
mkdir -p "$home/.local/state/maitri/current/theme"
printf '{"h1":{"prefix":"theme"}}\n' >"$home/.local/state/maitri/current/theme/glamour.json"
run_migration "$home" 2>"$home/migration.stderr" || fail "the glamour migration runs when the current theme is gone"
[[ ! -e $home/refresh.log && ! -e $home/.config/fish ]] || fail "the migration neither refreshes a missing theme nor creates a fish config"
[[ ! -e $home/.local/state/maitri/current/theme/glamour.json ]] && grep -q "Open a new shell" "$home/migration.stderr" ||
  fail "the migration drops a glamour.json a theme it can't refresh supplied and says glow needs a new shell" "$(<"$home/migration.stderr")"
run_migration "$home" 2>"$home/migration.stderr" || fail "the glamour migration runs again when the current theme is gone"
[[ ! -s $home/migration.stderr ]] || fail "the migration says nothing when there is no glamour.json to drop" "$(<"$home/migration.stderr")"

pass "the glamour migration adds the marked lines once, keeps a user's own style and renders the file"
