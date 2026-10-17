#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

require_command python3
require_command jq

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

files=(eza.fish voxtype.toml gitkraken.json gemini-cli.json opencode.json lazydocker.yml mpv.conf bat.tmTheme)

themes=()
for theme_dir in "$ROOT"/themes/*/; do
  theme=$(basename "$theme_dir")
  next_theme="$test_tmp/$theme/.local/state/maitri/current/next-theme"
  mkdir -p "$next_theme"
  cp "$theme_dir/colors.toml" "$next_theme/colors.toml"

  HOME="$test_tmp/$theme" MAITRI_PATH="$ROOT" PATH="$ROOT/bin:$PATH" bash "$ROOT/bin/maitri-theme-set-templates"
  MAITRI_PATH="$ROOT" PATH="$ROOT/bin:$PATH" maitri-theme-color --file "$next_theme/colors.toml" --all >"$test_tmp/$theme/palette.tsv"

  for file in "${files[@]}"; do
    [[ -f $next_theme/$file ]] || fail "$theme renders $file"
    ! grep -q '{{' "$next_theme/$file" || fail "$theme leaves no placeholders in $file" "$(grep -n '{{' "$next_theme/$file")"
  done
  themes+=("$theme")
done

(( ${#themes[@]} > 0 )) || fail "themes are rendered"

python3 - "$test_tmp" "${themes[@]}" <<'PY'
import json, plistlib, re, sys, tomllib

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


def same(a, b):
    return a is not None and b is not None and a.lstrip("#").lower()[:6] == b.lstrip("#").lower()[:6]


ANSI = ["foreground", "comment", "red", "green", "yellow", "blue", "magenta", "cyan"]


class Check:
    def __init__(self, theme, app, palette):
        self.theme, self.app, self.p = theme, app, palette
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

    def role(self, label, got, role):
        if not same(got, self.p[role]):
            self.errors.append(f"{label} is {got}, expected {role} {self.p[role]}")

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
            lines = f", lines {self.low[LINE]:.2f}:1" if self.low[LINE] < 99 else ""
            print(f"ok - {name} meets the contrast floors and the shared mapping (text {self.low[TEXT]:.2f}:1{lines})")


def eza(theme, p, path):
    c = Check(theme, "eza", p)
    spec = re.fullmatch(r'set -Ux EZA_COLORS "([^"]+)"\n', open(path).read()).group(1)
    keys = {}
    for entry in spec.split(":"):
        key, value = entry.split("=")
        attrs, color = value.rsplit(";", 1) if ";" in value else ("", value)
        keys[key] = (attrs, "#%02x%02x%02x" % tuple(int(v) for v in color.split(",")))
    for key, (_, color) in keys.items():
        c.floor(key, color, p["background"])
    for key, role in {"di": "blue", "ex": "green", "ln": "cyan", "or": "red", "uw": "red", "ur": "yellow",
                      "ga": "green", "gm": "blue", "gd": "red", "gc": "red", "xx": "comment", "da": "blue",
                      "hd": "accent", "im": "yellow", "vi": "magenta", "co": "red", "do": "cyan", "Gd": "orange"}.items():
        c.role(key, keys[key][1], role)
    c.expect(keys["di"][0] == "1" and keys["hd"][0] == "4", "directories are not bold or the header is not underlined")
    c.report()


def codex(theme, p, path):
    c = Check(theme, "Codex", p)
    doc = plistlib.load(open(path, "rb"))
    rules = {r["scope"]: r["settings"] for r in doc["settings"][1:]}
    c.role("codex.accent", rules["codex.accent"]["foreground"], "accent")
    syntax = {s["foreground"] for s in rules.values() if "foreground" in s}
    for scope, role in (("diff.inserted", "green"), ("diff.deleted", "red")):
        fill = rules[scope]["background"]
        c.expect(same(fill, mix(p["background"], p[role], 0.08)), f"{scope} fill is {fill}, expected an 8% {role} tint")
        for color in syntax:
            c.floor(f"{color} on {scope}", color, fill)
    c.report()


def voxtype(theme, p, path):
    c = Check(theme, "voxtype", p)
    doc = tomllib.load(open(path, "rb"))
    colors = doc["colors"]
    c.expect(doc["name"] == "maitri" and doc["palette"] == "package", "the voxtype package is not maitri's own palette")
    for key, role in {"accent": "accent", "background": "background", "foreground": "foreground", "warning": "orange",
                      "error": "red", "recording": "red", "success": "green"}.items():
        c.role(key, colors[key], role)
    for key in ("foreground", "muted", "idle"):
        c.floor(key, colors[key], colors["background"])
    for key in ("accent", "success", "warning", "error", "recording", "streaming", "transcribing"):
        c.floor(key, colors[key], colors["background"], LINE)
    c.report()


def gitkraken(theme, p, path):
    c = Check(theme, "GitKraken", p)
    doc = json.load(open(path))
    c.expect(doc["meta"] == {"name": "maitri", "scheme": p["theme_type"]}, f"GitKraken meta is {doc['meta']}")
    root = doc["themeValues"]["root"]
    surfaces = ["app__bg0", "toolbar__bg0", "toolbar__bg1", "toolbar__bg2", "panel__bg0", "panel__bg1", "panel__bg2",
                "card__bg", "hover-row", "selected-row", "code-bg"]
    for text in ("text-normal", "text-selected", "text-secondary", "text-accent", "text-bright", "btn-text", "link-color",
                 "red", "orange", "yellow", "green", "teal", "blue", "purple"):
        for surface in surfaces:
            c.floor(f"{text} on {surface}", root[text], root[surface])
    for row in ("added-line", "deleted-line", "modified-line", "danger-row", "warning-row", "checked-out"):
        c.floor(f"text-normal on {row}", root["text-normal"], root[row])
    for i in range(10):
        c.floor(f"graph-color-{i}", root[f"graph-color-{i}"], root["app__bg0"], LINE)
    c.floor("panel-border", root["panel-border"], root["app__bg0"], LINE)
    c.role("link-color", root["link-color"], "link")
    c.role("panel-border", root["panel-border"], "border")
    c.role("form-control-focus", root["form-control-focus"], "border_focus")
    c.role("warning-border", root["warning-border"], "orange")
    c.role("danger-border", root["danger-border"], "red")
    c.role("text-accent", root["text-accent"], "accent")
    for bar in ("toolbar", "tabsbar"):
        for key, value in doc["themeValues"][bar].items():
            if key.startswith("text-") and key != "text-disabled" or key in ("link-color", "btn-text"):
                c.floor(f"{bar} {key}", value, root["toolbar__bg0"])
    c.report()


def gemini(theme, p, path):
    c = Check(theme, "Gemini CLI", p)
    doc = json.load(open(path))
    for key in ("Foreground", "LightBlue", "AccentBlue", "AccentPurple", "AccentCyan", "AccentGreen", "AccentYellow",
                "AccentRed", "Comment", "Gray"):
        c.floor(key, doc[key], doc["Background"])
    for fill in ("DiffAdded", "DiffRemoved"):
        for key in ("Foreground", "Comment", "AccentGreen", "AccentRed", "AccentYellow", "AccentPurple"):
            c.floor(f"{key} on {fill}", doc[key], doc[fill])
    c.floor("DarkGray", doc["DarkGray"], doc["Background"], LINE)
    for key, role in {"Background": "background", "Foreground": "foreground", "LightBlue": "link", "AccentBlue": "accent", "AccentPurple": "accent",
                      "AccentYellow": "orange", "AccentRed": "red", "Comment": "comment", "DarkGray": "border"}.items():
        c.role(key, doc[key], role)
    c.report()


def opencode(theme, p, path):
    c = Check(theme, "opencode", p)
    t = json.load(open(path))["theme"]
    bg = p["background"]
    c.expect(t["background"] == "none", "opencode paints its own background over the terminal's")
    text = ["primary", "secondary", "accent", "error", "warning", "success", "info", "text", "textMuted"] + \
        [k for k in t if k.startswith("markdown") and k != "markdownHorizontalRule"] + \
        [k for k in t if k.startswith("syntax")]
    for key in text:
        for surface in ("background", "backgroundPanel", "backgroundElement", "backgroundMenu"):
            c.floor(f"{key} on {surface}", t[key], bg if surface == "background" else t[surface])
    c.floor("selectedListItemText on primary", t["selectedListItemText"], t["primary"])
    for fill in ("diffAddedBg", "diffRemovedBg", "diffContextBg", "diffAddedLineNumberBg", "diffRemovedLineNumberBg"):
        for key in ["text", "diffAdded", "diffRemoved", "diffContext", "diffLineNumber"] + [k for k in t if k.startswith("syntax")]:
            c.floor(f"{key} on {fill}", t[key], t[fill])
    for key in ("border", "borderActive", "markdownHorizontalRule"):
        c.floor(key, t[key], bg, LINE)
    for key, role in {"primary": "accent", "error": "red", "warning": "orange", "success": "green", "text": "foreground",
                      "textMuted": "comment", "border": "border", "borderActive": "border_focus", "markdownHeading": "accent",
                      "markdownLinkText": "link", "accent": "hint", "syntaxComment": "comment", "syntaxString": "yellow",
                      "syntaxKeyword": "magenta", "syntaxFunction": "green"}.items():
        c.role(key, t[key], role)
    c.report()


def lazydocker(theme, p, path):
    c = Check(theme, "lazydocker", p)
    keys, key = {}, None
    for line in open(path):
        m = re.fullmatch(r"    ([A-Za-z]+):\n", line)
        if m:
            key = m.group(1)
            keys[key] = []
        elif key and (m := re.fullmatch(r'      - "?([^"\n]+)"?\n', line)):
            keys[key].append(m.group(1))
    c.role("activeBorderColor", keys["activeBorderColor"][0], "border_focus")
    c.expect("bold" in keys["activeBorderColor"], "the active border is not bold")
    c.role("inactiveBorderColor", keys["inactiveBorderColor"][0], "border")
    c.role("optionsTextColor", keys["optionsTextColor"][0], "accent")
    for key in ("activeBorderColor", "inactiveBorderColor"):
        c.floor(key, keys[key][0], p["background"], LINE)
    c.floor("optionsTextColor", keys["optionsTextColor"][0], p["background"])
    for role in ANSI:
        c.floor(f"{role} on selectedLineBgColor", p[role], keys["selectedLineBgColor"][0])
    c.report()


def mpv(theme, p, path):
    c = Check(theme, "mpv", p)
    keys = {k: v.strip('"') for k, v in (line.rstrip("\n").split("=", 1) for line in open(path))}
    for kind in ("osd", "sub"):
        c.role(f"{kind}-color", keys[f"{kind}-color"], "foreground")
        c.role(f"{kind}-outline-color", keys[f"{kind}-outline-color"], "background")
        c.floor(kind, keys[f"{kind}-color"], keys[f"{kind}-outline-color"])
    c.role("osd-selected-color", keys["osd-selected-color"], "accent")
    c.floor("osd-selected", keys["osd-selected-color"], keys["osd-selected-outline-color"])
    c.report()


for theme in themes:
    palette = dict(line.rstrip("\n").split("\t", 1) for line in open(f"{root}/{theme}/palette.tsv"))
    rendered = f"{root}/{theme}/.local/state/maitri/current/next-theme"
    eza(theme, palette, f"{rendered}/eza.fish")
    codex(theme, palette, f"{rendered}/bat.tmTheme")
    voxtype(theme, palette, f"{rendered}/voxtype.toml")
    gitkraken(theme, palette, f"{rendered}/gitkraken.json")
    gemini(theme, palette, f"{rendered}/gemini-cli.json")
    opencode(theme, palette, f"{rendered}/opencode.json")
    lazydocker(theme, palette, f"{rendered}/lazydocker.yml")
    mpv(theme, palette, f"{rendered}/mpv.conf")

sys.exit(1 if failed else 0)
PY

pass "eza, Codex, voxtype, GitKraken, Gemini CLI, opencode, lazydocker and mpv render for every theme with readable contrast and the shared mapping"

sandbox="$test_tmp/sandbox-bin"
apps="$test_tmp/app-bin"
mkdir -p "$sandbox" "$apps"
for tool in awk cat cksum cmp cp cut dirname flock grep head jq mkdir mktemp mv paste rm sed sort touch uniq; do
  ln -s "$(command -v "$tool")" "$sandbox/$tool"
done
for app in eza codex voxtype gitkraken gemini opencode lazydocker mpv mise; do
  printf '#!/bin/bash\n' >"$apps/$app"
done
printf '#!/bin/bash\nexit 1\n' >"$apps/pgrep"
printf '#!/bin/bash\necho "$*" >>"$HOME/systemctl.log"\n[[ $3 != is-active ]] || [[ -e $HOME/voxtype.active ]]\n' >"$apps/systemctl"
chmod +x "$apps"/*
if command -v fish >/dev/null 2>&1; then
  ln -s "$(command -v fish)" "$apps/fish"
  has_fish=1
else
  has_fish=""
fi

hooks=(maitri-theme-set-eza maitri-theme-set-codex maitri-theme-set-voxtype maitri-theme-set-gitkraken maitri-theme-set-gemini
  maitri-theme-set-opencode maitri-theme-set-lazydocker maitri-theme-set-mpv)

isolated() {
  local home="$1"
  shift

  env -u XDG_CONFIG_HOME -u CODEX_HOME -u GEMINI_CLI_HOME -u MPV_HOME -u CONFIG_DIR -u EZA_COLORS \
    HOME="$home" XDG_RUNTIME_DIR="$home/run" "$@"
}

run_hook() {
  local home="$1" hook="$2" path="$3"

  isolated "$home" MAITRI_PATH="$ROOT" PATH="$ROOT/bin:$path" "$BASH" "$ROOT/bin/$hook" 2>>"$home/hook.stderr"
}

run_hooks() {
  local home="$1" path="$2" hook

  for hook in "${hooks[@]}"; do
    run_hook "$home" "$hook" "$path" || fail "$hook runs in $(basename "$home")"
  done
}

new_home() {
  local home="$test_tmp/hooks-$1"

  mkdir -p "$home/.local/state/maitri/current" "$home/run"
  cp -r "$test_tmp/$2/.local/state/maitri/current/next-theme" "$home/.local/state/maitri/current/theme"
  : >"$home/hook.stderr"
  printf '%s' "$home"
}

set_theme() {
  rm -rf "$1/.local/state/maitri/current/theme"
  cp -r "$test_tmp/$2/.local/state/maitri/current/next-theme" "$1/.local/state/maitri/current/theme"
}

toml_value() {
  python3 -c 'import sys, tomllib; d = tomllib.load(open(sys.argv[1], "rb"))
for k in sys.argv[2].split("."): d = d[k]
print(d)' "$@"
}

eza_colors() {
  isolated "$1" fish -c 'echo $EZA_COLORS'
}

for hook in "${hooks[@]}" maitri-theme-toml-block; do
  [[ -x $ROOT/bin/$hook ]] || fail "$hook is executable, since maitri-theme-set runs it by name"
  grep -qE "(^|[ \"])$hook([ ;\"]|\$)" "$ROOT/bin/maitri-theme-set" || [[ $hook == maitri-theme-toml-block ]] ||
    fail "maitri-theme-set runs $hook"
done

home=$(new_home missing amethyst)
run_hooks "$home" "$sandbox"
[[ -z $(find "$home" -mindepth 1 -maxdepth 1 -newer "$home/hook.stderr" ! -name run) && ! -e $home/.config ]] ||
  fail "the hooks write nothing when the tools are missing" "$(find "$home" -newer "$home/hook.stderr")"
[[ ! -s $home/hook.stderr ]] || fail "the hooks stay quiet when the tools are missing" "$(cat "$home/hook.stderr")"
pass "the hooks write nothing and say nothing without their tools"

home=$(new_home apply amethyst)
config="$home/.config"
mkdir -p "$config/voxtype" "$config/opencode" "$config/lazydocker" "$home/.codex" "$home/.gemini" "$home/dotfiles" "$config/mpv"
cp "$ROOT/default/voxtype/config.toml" "$config/voxtype/config.toml"
cp "$ROOT/config/opencode/opencode.json" "$config/opencode/opencode.json"
printf 'model = "o3"\n\n[tui]\nanimations = false\n\n[projects."/x"]\ntrust_level = "trusted"\n' >"$home/.codex/config.toml"
printf '{\n  "general": {\n    "vimMode": true\n  }\n}\n' >"$home/.gemini/settings.json"
printf 'gui:\n  showAllContainers: true\nlogs:\n  timestamps: false\n' >"$config/lazydocker/config.yml"
printf '# my mpv\n\nvolume=50\n\n[big]\nprofile-cond=width >= 1920\n' >"$home/dotfiles/mpv.conf"
ln -s "$home/dotfiles/mpv.conf" "$config/mpv/mpv.conf"

for pass in first second; do
  run_hooks "$home" "$apps:$sandbox"
  find "$home" -path "$home/run" -prune -o -path "$home/.local" -prune -o -type f ! -name hook.stderr -exec md5sum {} + | sort >"$test_tmp/$pass.sums"
done
diff "$test_tmp/first.sums" "$test_tmp/second.sums" >/dev/null || fail "running the hooks again changes nothing" "$(diff "$test_tmp/first.sums" "$test_tmp/second.sums")"
rendered="$home/.local/state/maitri/current/theme"

if [[ -n $has_fish ]]; then
  [[ $(eza_colors "$home") == "di=1;38;2;141;179;255:ex=1;38;2;133;220;140:"* ]] || fail "fish gets EZA_COLORS as 24-bit colours" "$(eza_colors "$home")"
fi
cmp -s "$rendered/bat.tmTheme" "$home/.codex/themes/maitri.tmTheme" || fail "Codex gets the bat tmTheme as its maitri theme"
[[ $(toml_value "$home/.codex/config.toml" tui.theme) == maitri && $(toml_value "$home/.codex/config.toml" tui.animations) == False &&
  $(toml_value "$home/.codex/config.toml" model) == o3 ]] || fail "Codex's config selects maitri under its own [tui]" "$(cat "$home/.codex/config.toml")"
cmp -s "$rendered/voxtype.toml" "$config/voxtype/osd/maitri/voxtype-osd.toml" || fail "voxtype gets the maitri style package"
[[ $(toml_value "$config/voxtype/config.toml" osd.style) == maitri && $(toml_value "$config/voxtype/config.toml" osd.frontend) == quickshell &&
  $(toml_value "$config/voxtype/config.toml" whisper.model) == base.en ]] || fail "voxtype's config picks the maitri OSD and keeps the rest" "$(cat "$config/voxtype/config.toml")"
cmp -s "$rendered/gitkraken.json" "$home/.gitkraken/themes/maitri.jsonc" || fail "GitKraken gets the maitri theme file"
[[ $(jq -c '[.ui.theme, .general.vimMode, (.ui.customThemes.maitri == input)]' "$home/.gemini/settings.json" "$rendered/gemini-cli.json") == '["maitri",true,true]' ]] ||
  fail "Gemini CLI's settings get the maitri theme and keep the rest" "$(cat "$home/.gemini/settings.json")"
cmp -s "$rendered/opencode.json" "$config/opencode/themes/maitri.json" || fail "opencode gets the maitri theme file"
[[ $(jq -r .theme "$config/opencode/tui.json") == maitri ]] || fail "opencode's tui.json picks maitri over the old system theme" "$(cat "$config/opencode/tui.json")"
cmp -s "$config/opencode/opencode.json" "$ROOT/config/opencode/opencode.json" || fail "opencode.json is left to opencode"
grep -q '^  # >>> maitri theme' "$config/lazydocker/config.yml" && grep -q '      - "#7058A3"' "$config/lazydocker/config.yml" &&
  grep -q '^  showAllContainers: true' "$config/lazydocker/config.yml" || fail "lazydocker's config gets gui.theme under its own gui" "$(cat "$config/lazydocker/config.yml")"
[[ -L $config/mpv/mpv.conf ]] || fail "a symlinked mpv.conf stays a symlink"
[[ $(<"$home/dotfiles/mpv.conf") == $'# my mpv\n\n# >>> maitri theme (rewritten by maitri theme set) >>>\n'"$(<"$rendered/mpv.conf")"$'\n# <<< maitri theme <<<\n\nvolume=50\n\n[big]\nprofile-cond=width >= 1920' ]] ||
  fail "mpv.conf gets the colours above the user's settings and profiles" "$(cat "$home/dotfiles/mpv.conf")"
[[ ! -s $home/hook.stderr ]] || fail "applying the theme says nothing when nothing needs the user" "$(cat "$home/hook.stderr")"
pass "each tool gets the maitri theme in its own place, and a second run changes nothing"

set_theme "$home" daybreak
run_hooks "$home" "$apps:$sandbox"
rendered="$home/.local/state/maitri/current/theme"
if [[ -n $has_fish ]]; then
  [[ $(eza_colors "$home") == "di=1;38;2;52;93;176:"* ]] || fail "a theme change replaces EZA_COLORS" "$(eza_colors "$home")"
  got=$(isolated "$home" EZA_COLORS="di=31" fish -c 'echo $EZA_COLORS')
  [[ $got == "di=1;38;2;52;93;176:"* ]] || fail "a fish that inherits the old EZA_COLORS from the session gets the new one" "$got"
fi
for pair in "bat.tmTheme:.codex/themes/maitri.tmTheme" "voxtype.toml:.config/voxtype/osd/maitri/voxtype-osd.toml" \
  "gitkraken.json:.gitkraken/themes/maitri.jsonc" "opencode.json:.config/opencode/themes/maitri.json"; do
  cmp -s "$rendered/${pair%%:*}" "$home/${pair#*:}" || fail "a theme change replaces ${pair#*:}"
done
[[ $(jq -r .ui.customThemes.maitri.Background "$home/.gemini/settings.json") == "#F5F5F5" ]] || fail "a theme change replaces the Gemini CLI theme"
grep -q '      - "#816CD2"' "$config/lazydocker/config.yml" && ! grep -q '#7058A3' "$config/lazydocker/config.yml" || fail "a theme change replaces lazydocker's colours"
[[ $(grep -c 'maitri theme' "$home/dotfiles/mpv.conf") == 2 ]] && grep -q "^osd-color=\"#1F1F1F\"$" "$home/dotfiles/mpv.conf" || fail "a theme change replaces mpv's block" "$(cat "$home/dotfiles/mpv.conf")"
for file in "$home/.codex/config.toml" "$config/voxtype/config.toml"; do
  [[ $(grep -c '# >>> maitri theme' "$file") == 1 ]] || fail "a theme change keeps one block in $file" "$(cat "$file")"
done
pass "a theme change replaces every tool's colours in place"

home=$(new_home own amethyst)
config="$home/.config"
mkdir -p "$config/voxtype" "$config/opencode" "$config/lazydocker" "$config/fish" "$home/.codex" "$home/.gemini"
printf '[tui]\ntheme = "gruvbox-dark"\n' >"$home/.codex/config.toml"
printf '[osd]\nstyle = "mine"\n' >"$config/voxtype/config.toml"
printf '{"ui": {"theme": "GitHub"}}\n' >"$home/.gemini/settings.json"
printf '{"theme": "tokyonight"}\n' >"$config/opencode/tui.json"
printf 'gui:\n  theme:\n    activeBorderColor:\n      - red\n' >"$config/lazydocker/config.yml"
printf 'set -Ux EZA_COLORS "di=31"\n' >"$config/fish/config.fish"
mkdir -p "$test_tmp/own-before"
cp -r "$config/lazydocker" "$test_tmp/own-before"
run_hooks "$home" "$apps:$sandbox"
[[ $(toml_value "$home/.codex/config.toml" tui.theme) == gruvbox-dark && $(grep -c theme "$home/.codex/config.toml") == 1 ]] ||
  fail "Codex keeps its own [tui] theme" "$(cat "$home/.codex/config.toml")"
[[ $(toml_value "$config/voxtype/config.toml" osd.style) == mine && $(toml_value "$config/voxtype/config.toml" osd.frontend) == quickshell ]] ||
  fail "voxtype keeps its own OSD style and gets the rest" "$(cat "$config/voxtype/config.toml")"
[[ $(jq -r '[.ui.theme, .ui.customThemes.maitri.name] | join(" ")' "$home/.gemini/settings.json") == "GitHub maitri" ]] ||
  fail "Gemini CLI keeps its own theme and gets maitri to pick" "$(cat "$home/.gemini/settings.json")"
[[ $(jq -r .theme "$config/opencode/tui.json") == tokyonight && -f $config/opencode/themes/maitri.json ]] ||
  fail "opencode keeps its own theme and gets maitri to pick" "$(cat "$config/opencode/tui.json")"
cmp -s "$config/lazydocker/config.yml" "$test_tmp/own-before/lazydocker/config.yml" || fail "lazydocker keeps its own gui.theme" "$(cat "$config/lazydocker/config.yml")"
for note in "Codex's config.toml picks its own" "voxtype's config.toml sets its own OSD style" "Gemini CLI uses its own theme" \
  "opencode uses its own theme" "lazydocker's config.yml sets its own gui.theme"; do
  grep -qF "$note" "$home/hook.stderr" || fail "a hook says it left the user's choice: $note" "$(cat "$home/hook.stderr")"
done
if [[ -n $has_fish ]]; then
  grep -qF "sets EZA_COLORS itself" "$home/hook.stderr" || fail "the eza hook says config.fish hides its colours" "$(cat "$home/hook.stderr")"
fi

home=$(new_home legacy amethyst)
mkdir -p "$home/.config/opencode"
printf '{"theme": "nord"}\n' >"$home/.config/opencode/opencode.json"
run_hook "$home" maitri-theme-set-opencode "$apps:$sandbox" || fail "maitri-theme-set-opencode runs beside an older opencode.json theme"
[[ ! -e $home/.config/opencode/tui.json ]] && grep -q "opencode uses its own theme" "$home/hook.stderr" ||
  fail "an older opencode.json theme of the user's own is left for opencode to move" "$(cat "$home/hook.stderr")"

home=$(new_home inline amethyst)
mkdir -p "$home/.codex" "$home/.gemini"
printf 'tui = { theme = "gruvbox-dark" }\n' >"$home/.codex/config.toml"
printf '{\n  // mine\n  "ui": {}\n}\n' >"$home/.gemini/settings.json"
cp "$home/.codex/config.toml" "$home/.gemini/settings.json" "$test_tmp/"
run_hook "$home" maitri-theme-set-codex "$apps:$sandbox" || fail "maitri-theme-set-codex runs beside an inline [tui]"
run_hook "$home" maitri-theme-set-gemini "$apps:$sandbox" || fail "maitri-theme-set-gemini runs beside settings with comments"
cmp -s "$home/.codex/config.toml" "$test_tmp/config.toml" && cmp -s "$home/.gemini/settings.json" "$test_tmp/settings.json" ||
  fail "configs maitri can't edit safely are left as they were"
grep -q "writes \[tui\] inline, as dotted keys" "$home/hook.stderr" && grep -q "isn't plain JSON" "$home/hook.stderr" ||
  fail "the hooks say why they left a config alone" "$(cat "$home/hook.stderr")"
pass "the hooks leave a theme the user chose in place and say so"

home=$(new_home toml amethyst)
mkdir -p "$home/.codex" "$home/.config/voxtype"
printf 'notes = """\n[tui]\ntheme = 1\n"""\nlist = [\n  ["a", "b"],\n]\n\n[tui]\nanimations = false\n' >"$home/.codex/config.toml"
printf 'osd.frontend = "gtk4"\n' >"$home/.config/voxtype/config.toml"
cp "$home/.config/voxtype/config.toml" "$test_tmp/dotted.toml"
run_hook "$home" maitri-theme-set-codex "$apps:$sandbox" || fail "maitri-theme-set-codex runs beside multi-line values"
run_hook "$home" maitri-theme-set-voxtype "$apps:$sandbox" || fail "maitri-theme-set-voxtype runs beside a dotted [osd]"
[[ $(toml_value "$home/.codex/config.toml" tui.theme) == maitri && $(toml_value "$home/.codex/config.toml" notes) == $'[tui]\ntheme = 1' ]] ||
  fail "a header or key inside a multi-line value isn't taken for the user's own" "$(cat "$home/.codex/config.toml")"
cmp -s "$home/.config/voxtype/config.toml" "$test_tmp/dotted.toml" && grep -q "as dotted keys" "$home/hook.stderr" ||
  fail "a table set through dotted keys never gets a second header" "$(cat "$home/.config/voxtype/config.toml")"
pass "the TOML block reads multi-line values and dotted tables the way TOML does"

home=$(new_home dangling amethyst)
mkdir -p "$home/.codex" "$home/.config/mpv"
printf '# >>> maitri theme (rewritten by maitri theme set) >>>\nmodel = "o3"\n[tui]\nanimations = false\n' >"$home/.codex/config.toml"
printf '# >>> maitri theme (rewritten by maitri theme set) >>>\nvolume=50\n' >"$home/.config/mpv/mpv.conf"
for run in 1 2; do
  run_hook "$home" maitri-theme-set-codex "$apps:$sandbox" || fail "maitri-theme-set-codex runs beside a start marker without an end"
  run_hook "$home" maitri-theme-set-mpv "$apps:$sandbox" || fail "maitri-theme-set-mpv runs beside a start marker without an end"
done
[[ $(toml_value "$home/.codex/config.toml" model) == o3 && $(toml_value "$home/.codex/config.toml" tui.theme) == maitri &&
  $(grep -c '<<< maitri theme' "$home/.codex/config.toml") == 1 ]] || fail "a dangling marker in Codex's config loses nothing" "$(cat "$home/.codex/config.toml")"
grep -q '^volume=50$' "$home/.config/mpv/mpv.conf" && [[ $(grep -c '<<< maitri theme' "$home/.config/mpv/mpv.conf") == 1 ]] ||
  fail "a dangling marker in mpv.conf loses nothing" "$(cat "$home/.config/mpv/mpv.conf")"
pass "a start marker without an end never costs the user a line"

home=$(new_home hostile amethyst)
rendered="$home/.local/state/maitri/current/theme"
mkdir -p "$home/.config/voxtype" "$home/.config/lazydocker"
printf '[osd]\n' >"$home/.config/voxtype/config.toml"
printf 'set -Ux EZA_COLORS "di=1;1,2,3"; touch pwned\n' >"$rendered/eza.fish"
printf 'name = "maitri"\nqml_entry = "pwned.qml"\n[colors]\naccent = "#ffffff"\n' >"$rendered/voxtype.toml"
jq '.themeValues.root.white = "url(https://pwned)"' "$rendered/gitkraken.json" >"$test_tmp/gk" && mv "$test_tmp/gk" "$rendered/gitkraken.json"
jq '.Background = "{{ background }}"' "$rendered/gemini-cli.json" >"$test_tmp/gm" && mv "$test_tmp/gm" "$rendered/gemini-cli.json"
jq '.theme.text = "pwned"' "$rendered/opencode.json" >"$test_tmp/oc" && mv "$test_tmp/oc" "$rendered/opencode.json"
printf 'gui:\n  theme:\n    activeBorderColor:\n      - "#ffffff"\ncustomCommands:\n  containers:\n    - command: touch pwned\n' >"$rendered/lazydocker.yml"
printf 'osd-color="#ffffff"\nscript=/tmp/pwned.lua\n' >"$rendered/mpv.conf"
printf '<plist>{{ accent }}</plist>\n' >"$rendered/bat.tmTheme"
run_hooks "$home" "$apps:$sandbox"
! grep -rq pwned "$home/.config" "$home/.gitkraken" "$home/.gemini" "$home/.codex" 2>/dev/null ||
  fail "nothing from a rendered file beyond colours reaches a config" "$(grep -rn pwned "$home/.config" "$home/.gitkraken" "$home/.gemini" "$home/.codex" 2>/dev/null)"
[[ ! -e $home/.config/voxtype/osd && ! -e $home/.gitkraken && ! -e $home/.gemini && ! -e $home/.codex && ! -e $home/.config/opencode &&
  ! -e $home/.config/mpv ]] || fail "the hooks write nothing from a rendered file they skip"
grep -q '      - "#ffffff"' "$home/.config/lazydocker/config.yml" || fail "lazydocker still gets the theme's colours" "$(cat "$home/.config/lazydocker/config.yml")"
for app in voxtype GitKraken "Gemini CLI" opencode mpv Codex; do
  grep -q "Skipping $app theme" "$home/hook.stderr" || fail "the $app hook says why it skipped" "$(cat "$home/hook.stderr")"
done
if [[ -n $has_fish ]]; then
  grep -q "Skipping eza theme" "$home/hook.stderr" && [[ -z $(eza_colors "$home") ]] || fail "the eza hook skips anything but a colour list" "$(cat "$home/hook.stderr")"
fi
pass "the hooks apply only colours and skip a rendered file with anything else"

home=$(new_home voxtype amethyst)
mkdir -p "$home/.config/voxtype" "$home/run/voxtype"
printf '[osd]\nenabled = true\n' >"$home/.config/voxtype/config.toml"
touch "$home/voxtype.active"
echo recording >"$home/run/voxtype/state"
run_hook "$home" maitri-theme-set-voxtype "$apps:$sandbox" || fail "maitri-theme-set-voxtype runs while dictating"
! grep -q try-restart "$home/systemctl.log" && grep -q "Restart voxtype" "$home/hook.stderr" ||
  fail "voxtype is never restarted in the middle of a dictation" "$(cat "$home/systemctl.log")"
printf '[osd]\nenabled = true\n' >"$home/.config/voxtype/config.toml"
echo idle >"$home/run/voxtype/state"
run_hook "$home" maitri-theme-set-voxtype "$apps:$sandbox" || fail "maitri-theme-set-voxtype runs while idle"
grep -q '^--user try-restart voxtype.service$' "$home/systemctl.log" || fail "an idle voxtype restarts onto the maitri OSD" "$(cat "$home/systemctl.log")"
printf '{"style": "maitri", "palette": "package", "colors": {"accent": "#000000", "glow": "#123456"}}\n' >"$home/run/voxtype/quickshell-style.json"
set_theme "$home" daybreak
: >"$home/systemctl.log"
run_hook "$home" maitri-theme-set-voxtype "$apps:$sandbox" || fail "maitri-theme-set-voxtype runs on a theme change"
[[ $(jq -c '.colors | [.accent, .glow]' "$home/run/voxtype/quickshell-style.json") == '["#644AC9","#123456"]' && ! -s $home/systemctl.log ]] ||
  fail "a running Quickshell OSD gets the new colours without a restart" "$(cat "$home/run/voxtype/quickshell-style.json")"
printf '{"style": "other", "palette": "package", "colors": {"accent": "#000000"}}\n' >"$home/run/voxtype/quickshell-style.json"
set_theme "$home" amethyst
run_hook "$home" maitri-theme-set-voxtype "$apps:$sandbox" || fail "maitri-theme-set-voxtype runs beside another OSD style"
[[ $(jq -r .colors.accent "$home/run/voxtype/quickshell-style.json") == "#000000" ]] || fail "an OSD on another style keeps its colours"
pass "voxtype switches to the maitri OSD while idle and retints a running one in place"

toml_block_case() {
  local description="$1" input="$2" expected_status="$3" status=0
  printf '%b' "$input" >"$test_tmp/case.toml"
  cp "$test_tmp/case.toml" "$test_tmp/case.before"
  "$ROOT/bin/maitri-theme-toml-block" "$test_tmp/case.toml" tui "$test_tmp/case.block" >"$test_tmp/case.dropped" || status=$?
  (( status == expected_status )) || fail "$description: exits $expected_status" "exit $status: $(cat "$test_tmp/case.toml")"
  if (( status == 3 )); then
    cmp -s "$test_tmp/case.toml" "$test_tmp/case.before" || fail "$description: file left as it is" "$(cat "$test_tmp/case.toml")"
  fi
  python3 -c 'import sys, tomllib; tomllib.load(open(sys.argv[1], "rb"))' "$test_tmp/case.toml" ||
    fail "$description: stays valid TOML" "$(cat "$test_tmp/case.toml")"
}

printf 'theme = "maitri"\n' >"$test_tmp/case.block"
toml_block_case "a single-quoted table header" "['tui']\nalt = 1\n" 0
[[ $(toml_value "$test_tmp/case.toml" tui.theme) == maitri ]] || fail "a single-quoted [tui] gets the block" "$(cat "$test_tmp/case.toml")"
toml_block_case "a spaced, single-quoted table header" "[ 'tui' ]\n" 0
[[ $(toml_value "$test_tmp/case.toml" tui.theme) == maitri ]] || fail "a spaced [ 'tui' ] gets the block" "$(cat "$test_tmp/case.toml")"
toml_block_case "a single-quoted key the user sets" "[tui]\n'theme' = \"own\"\n" 0
[[ $(toml_value "$test_tmp/case.toml" tui.theme) == own && $(cat "$test_tmp/case.dropped") == theme ]] ||
  fail "a single-quoted theme key stays the user's" "$(cat "$test_tmp/case.toml")"
toml_block_case "a quoted key with spaced dots in the table" "[tui]\n\"theme\" . 'x' = 1\n" 0
[[ $(cat "$test_tmp/case.dropped") == theme ]] || fail "a spaced dotted theme key counts as the user's" "$(cat "$test_tmp/case.toml")"
toml_block_case "a top-level dotted key with spaces" "tui . theme = \"x\"\n" 3
toml_block_case "a quoted top-level dotted key" "'tui'.theme = \"x\"\n" 3
toml_block_case "a table whose quoted name has a dot" "[\"tui.x\"]\na = 1\n" 0
[[ $(toml_value "$test_tmp/case.toml" tui.theme) == maitri ]] || fail "a [\"tui.x\"] table isn't taken for [tui]" "$(cat "$test_tmp/case.toml")"
toml_block_case "a key spelled with escapes" "[tui]\n\"th\\\\u0065me\" = \"own\"\n" 3
toml_block_case "maitri's markers inside a multi-line string" "[tui]\nnote = \"\"\"\n# >>> maitri theme (rewritten by maitri theme set) >>>\nkept\n# <<< maitri theme <<<\n\"\"\"\n" 0
python3 -c 'import sys, tomllib; assert "kept" in tomllib.load(open(sys.argv[1], "rb"))["tui"]["note"]' "$test_tmp/case.toml" ||
  fail "markers inside a multi-line string stay part of it" "$(cat "$test_tmp/case.toml")"
pass "the TOML block reads quoted and dotted keys whole and leaves files with escaped keys alone"

if command -v mpv >/dev/null 2>&1; then
  home=$(new_home real-mpv daybreak)
  run_hook "$home" maitri-theme-set-mpv "$PATH" || fail "maitri-theme-set-mpv runs with the real mpv"
  got=$(isolated "$home" mpv --vo=null --ao=null --frames=1 --msg-level=all=v 'av://lavfi:color=d=1' 2>&1 || true)
  ! grep -qiE 'error parsing|setting option .* failed' <<<"$got" && grep -q "Setting option 'osd-color' = '#1F1F1F'" <<<"$got" ||
    fail "mpv loads the maitri colours without errors" "$(grep -iE 'osd|sub|error' <<<"$got")"
  pass "mpv loads the maitri OSD and subtitle colours"
else
  skip "mpv loads the maitri OSD and subtitle colours (mpv is not installed)"
fi

if command -v eza >/dev/null 2>&1 && [[ -n $has_fish ]]; then
  home=$(new_home real-eza amethyst)
  run_hook "$home" maitri-theme-set-eza "$PATH" || fail "maitri-theme-set-eza runs with the real eza"
  got=$(isolated "$home" fish -c "eza --color=always -d $ROOT/bin" | cat -v)
  [[ $got == *'[1;38;2;141;179;255mbin'* ]] || fail "eza draws directories in the theme's blue" "$got"
  pass "eza takes the maitri colours from fish"
else
  skip "eza takes the maitri colours from fish (eza or fish is not installed)"
fi
