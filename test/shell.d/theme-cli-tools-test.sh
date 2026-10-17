#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

require_command python3

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

files=(lazygit.yml bat.tmTheme delta.gitconfig fzf.fish yazi.toml)

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
import plistlib, re, sys, tomllib

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
    return a is not None and b is not None and a.lstrip("#").lower() == b.lstrip("#").lower()


SYNTAX = {
    "Comment": "comment", "String": "yellow", "Constant": "blue", "Character": "magenta", "Keyword": "magenta",
    "Function": "green", "Builtin function": "cyan", "Type": "cyan", "Parameter": "orange", "Property": "orange",
    "Attribute": "green", "Regexp": "red", "Punctuation": "light_foreground", "Tag": "cyan", "Inserted": "green",
    "Deleted": "red", "Changed": "blue", "Invalid": "red", "Link text": "link",
}
ITALIC = {"Comment", "Type", "Parameter", "Attribute"}
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


def bat(theme, p, path):
    c = Check(theme, "bat", p)
    doc = plistlib.load(open(path, "rb"))
    c.expect(doc["name"] == "maitri", "the bat theme is not named maitri")
    settings = doc["settings"][0]["settings"]
    scopes = {r["name"]: r["scope"] for r in doc["settings"][1:]}
    rules = {r["name"]: r["settings"] for r in doc["settings"][1:]}
    c.role("background", settings["background"], "background")
    c.role("foreground", settings["foreground"], "foreground")
    c.role("gutterForeground", settings["gutterForeground"], "comment")
    c.role("selection", settings["selection"], "selection")
    c.floor("line numbers and grid", settings["gutterForeground"], settings["background"])
    for name, style in rules.items():
        if "foreground" in style:
            for surface in ("background", "lineHighlight"):
                c.floor(f"{name} on {surface}", style["foreground"], settings[surface])
    for name, role in SYNTAX.items():
        c.role(name, rules[name]["foreground"], role)
    for name in ITALIC:
        c.expect("italic" in rules[name].get("fontStyle", ""), f"{name} is not italic")
    c.expect("underline" in rules["Link text"].get("fontStyle", ""), "links are not underlined")
    for level in range(1, 7):
        rule = rules["Heading" if level == 1 else f"Heading {level}"]
        expected = mix(p["accent"], p["foreground"], (level - 1) * 0.13)
        c.expect(same(rule["foreground"], expected), f"H{level} is {rule['foreground']}, expected {expected}")
        c.expect("bold" in rule.get("fontStyle", ""), f"H{level} is not bold")
        c.expect(f"markup.heading.{level}" in scopes["Heading" if level == 1 else f"Heading {level}"], f"H{level} does not cover markup.heading.{level}")
    c.report()
    return [style["foreground"] for style in rules.values() if "foreground" in style]


def delta(theme, p, path, syntax):
    c = Check(theme, "delta", p)
    keys = {}
    section = None
    for line in open(path):
        line = line.strip()
        if line.startswith("["):
            section = line
        elif line and section == "[delta]":
            key, value = (part.strip() for part in line.split("=", 1))
            keys[key] = value.replace('"', "")
    colors = {key: re.findall(r"#[0-9A-Fa-f]{6}", value) for key, value in keys.items()}
    c.expect(keys["syntax-theme"] == "maitri", "delta does not use the maitri syntax theme")

    for kind, role in (("minus", "red"), ("plus", "green")):
        style, emph = keys[f"{kind}-style"], colors[f"{kind}-emph-style"]
        c.expect(style.startswith("syntax "), f"{kind}-style does not keep syntax colours")
        fill = colors[f"{kind}-style"][0]
        c.expect(same(fill, mix(p["background"], p[role], 0.08)), f"{kind}-style fill is {fill}, expected an 8% {role} tint")
        c.expect(same(emph[1], mix(p["background"], p[role], 0.30)), f"{kind}-emph-style fill is {emph[1]}, expected a 30% {role} tint")
        c.role(f"{kind}-emph-style text", emph[0], "foreground")
        c.floor(f"{kind}-emph-style", emph[0], emph[1])
        for color in syntax:
            c.floor(f"syntax {color} on {kind}-style", color, fill)
        c.role(f"line-numbers-{kind}-style", colors[f"line-numbers-{kind}-style"][0], role)
        c.floor(f"line-numbers-{kind}-style", colors[f"line-numbers-{kind}-style"][0], p["background"])
    for fill in colors["map-styles"]:
        for color in syntax:
            c.floor(f"syntax {color} on moved line {fill}", color, fill)
    for fill in colors["blame-palette"]:
        for color in syntax:
            c.floor(f"syntax {color} on blame {fill}", color, fill)
    c.role("line-numbers-zero-style", colors["line-numbers-zero-style"][0], "comment")
    c.role("file-style", colors["file-style"][0], "accent")
    c.expect("bold" in keys["file-style"], "file names are not bold")
    for key in ("line-numbers-zero-style", "file-style", "hunk-header-file-style", "hunk-header-line-number-style", "inline-hint-style"):
        c.floor(key, colors[key][0], p["background"])
    for key in ("line-numbers-left-style", "line-numbers-right-style", "file-decoration-style",
                "hunk-header-decoration-style", "commit-decoration-style"):
        c.role(key, colors[key][0], "border")
        c.floor(key, colors[key][0], p["background"], LINE)
    c.report()


def lazygit(theme, p, path):
    c = Check(theme, "lazygit", p)
    theme_keys, key = {}, None
    for line in open(path):
        m = re.fullmatch(r"    ([A-Za-z]+):\n", line)
        if m:
            key = m.group(1)
            theme_keys[key] = []
        elif key and (m := re.fullmatch(r'      - "?([^"\n]+)"?\n', line)):
            theme_keys[key].append(m.group(1))
    bg = p["background"]
    c.role("activeBorderColor", theme_keys["activeBorderColor"][0], "border_focus")
    c.expect("bold" in theme_keys["activeBorderColor"], "the active border is not bold")
    c.role("inactiveBorderColor", theme_keys["inactiveBorderColor"][0], "border")
    for key in ("activeBorderColor", "inactiveBorderColor", "searchingActiveBorderColor"):
        c.floor(key, theme_keys[key][0], bg, LINE)
    c.role("optionsTextColor", theme_keys["optionsTextColor"][0], "accent")
    c.role("unstagedChangesColor", theme_keys["unstagedChangesColor"][0], "red")
    c.role("defaultFgColor", theme_keys["defaultFgColor"][0], "foreground")
    for key in ("optionsTextColor", "unstagedChangesColor", "defaultFgColor"):
        c.floor(key, theme_keys[key][0], bg)
    for key in ("selectedLineBgColor", "inactiveViewSelectedLineBgColor"):
        for role in ANSI:
            c.floor(f"{role} on {key}", p[role], theme_keys[key][0])
    for kind in ("cherryPickedCommit", "markedBaseCommit"):
        c.floor(kind, theme_keys[f"{kind}FgColor"][0], theme_keys[f"{kind}BgColor"][0])
    c.report()


def fzf(theme, p, path):
    c = Check(theme, "fzf", p)
    spec = re.search(r'--color=([^" ]+)', open(path).read()).group(1)
    colors = dict(part.split(":", 1) for part in spec.split(","))
    colors = {k: p["background"] if v == "-1" else v for k, v in colors.items()}
    c.role("gutter", colors["gutter"], "background")
    c.role("bg+", colors["bg+"], "lighter_background")
    c.role("selected-bg", colors["selected-bg"], "selection")
    c.role("hl", colors["hl"], "accent")
    c.role("info", colors["info"], "comment")
    c.role("border", colors["border"], "border")
    for key in ("fg", "hl", "query", "disabled", "ghost", "info", "prompt", "pointer", "marker", "spinner", "header",
                "label", "preview-label"):
        c.floor(key, colors[key], colors["bg"])
    for key in ("fg+", "hl+", "pointer"):
        c.floor(f"{key} on bg+", colors[key], colors["bg+"])
    for key in ("selected-fg", "selected-hl"):
        c.floor(f"{key} on selected-bg", colors[key], colors["selected-bg"])
    for key in ("border", "separator", "scrollbar", "preview-border"):
        c.floor(key, colors[key], colors["bg"], LINE)
    c.report()


def yazi(theme, p, path):
    c = Check(theme, "yazi", p)
    doc = tomllib.load(open(path, "rb"))
    bg, hovered = p["background"], doc["indicator"]["current"]["bg"]

    def style(label, s, rows=(bg,)):
        fg, fill = s.get("fg"), s.get("bg")
        if fg and fg.startswith("#") and fill and fill.startswith("#"):
            if same(fg, fill):
                c.floor(f"{label} bar", fill, bg, LINE)
            else:
                c.floor(label, fg, fill)
        elif fg and fg.startswith("#"):
            minimum = LINE if "border" in label else TEXT
            for row in rows:
                c.floor(f"{label} on {row}", fg, row, minimum)
        elif fill and fill.startswith("#"):
            c.floor(f"text on {label}", p["foreground"], fill)

    for table, entries in doc.items():
        if table in ("filetype", "icon"):
            continue
        for key, value in entries.items():
            if isinstance(value, dict):
                style(f"{table}.{key}", value, (bg, hovered) if table == "mgr" and key.startswith("find") else (bg,))
    for i, rule in enumerate(doc["filetype"]["rules"]):
        style(f"filetype rule {i}", rule, (bg, hovered))
    for group in ("dirs", "conds"):
        for rule in doc["icon"][group]:
            style(f"icon {rule.get('name') or rule.get('if')}", rule, (bg, hovered))

    c.role("mgr.border_style", doc["mgr"]["border_style"]["fg"], "border")
    for table in ("which", "confirm", "spot", "pick", "input", "cmp", "tasks", "help"):
        c.role(f"{table}.border", doc[table]["border"]["fg"], "border_focus")
    c.role("indicator.current", hovered, "lighter_background")
    c.role("input.selected", doc["input"]["selected"]["bg"], "selection")
    c.role("notify.title_warn", doc["notify"]["title_warn"]["fg"], "orange")
    c.role("notify.title_error", doc["notify"]["title_error"]["fg"], "red")
    c.role("tabs.active", doc["tabs"]["active"]["bg"], "accent")
    c.role("directories", doc["filetype"]["rules"][-1]["fg"], "blue")
    c.report()


for theme in themes:
    palette = dict(line.rstrip("\n").split("\t", 1) for line in open(f"{root}/{theme}/palette.tsv"))
    rendered = f"{root}/{theme}/.local/state/maitri/current/next-theme"
    syntax = bat(theme, palette, f"{rendered}/bat.tmTheme")
    delta(theme, palette, f"{rendered}/delta.gitconfig", syntax)
    lazygit(theme, palette, f"{rendered}/lazygit.yml")
    fzf(theme, palette, f"{rendered}/fzf.fish")
    yazi(theme, palette, f"{rendered}/yazi.toml")

sys.exit(1 if failed else 0)
PY

pass "lazygit, bat, delta, fzf and yazi render for every theme with readable contrast and the shared mapping"

if command -v fish >/dev/null 2>&1; then
  snippet="$test_tmp/amethyst/.local/state/maitri/current/next-theme/fzf.fish"
  got=$(env -u FZF_DEFAULT_OPTS -u MAITRI_FZF_COLORS fish --no-config -c "
    set -gx FZF_DEFAULT_OPTS '--cycle --height=90%'
    source $snippet
    source $snippet
    echo \$FZF_DEFAULT_OPTS")
  [[ $got == "--cycle --height=90% --color=fg:#E6E9F0,"* ]] || fail "fzf.fish adds the colours to FZF_DEFAULT_OPTS" "$got"
  (( $(grep -o -- '--color=' <<<"$got" | wc -l) == 1 )) || fail "sourcing fzf.fish again doesn't repeat the colours" "$got"
  pass "fzf.fish adds the theme colours to FZF_DEFAULT_OPTS once"
else
  skip "fzf.fish adds the theme colours to FZF_DEFAULT_OPTS once (fish is not installed)"
fi

sandbox="$test_tmp/sandbox-bin"
apps="$test_tmp/app-bin"
mkdir -p "$sandbox" "$apps"
for tool in awk cat cmp cp dirname flock grep head mkdir mktemp mv rm sed sort touch uniq; do
  ln -s "$(command -v "$tool")" "$sandbox/$tool"
done
for app in lazygit delta fzf yazi; do
  printf '#!/bin/bash\n' >"$apps/$app"
done
cat >"$apps/bat" <<'SH'
#!/bin/bash
case $1 in
  --config-dir) echo "$HOME/.config/bat" ;;
  --config-file) echo "$HOME/.config/bat/config" ;;
  cache) echo "$*" >>"$HOME/bat.log" ;;
esac
SH
printf '#!/bin/bash\n[[ $2 == yazi ]]\n' >"$apps/pgrep"
chmod +x "$apps"/*

hooks=(maitri-theme-set-lazygit maitri-theme-set-bat maitri-theme-set-fzf maitri-theme-set-yazi)

isolated() {
  local home="$1"
  shift

  env -u XDG_CONFIG_HOME -u XDG_CACHE_HOME -u YAZI_CONFIG_HOME -u BAT_CONFIG_DIR -u BAT_CONFIG_PATH -u BAT_CACHE_PATH \
    -u BAT_THEME -u LG_CONFIG_FILE -u CONFIG_DIR HOME="$home" XDG_RUNTIME_DIR="$test_tmp" "$@"
}

run_hook() {
  local home="$1" hook="$2" path="$3"

  isolated "$home" MAITRI_PATH="$ROOT" PATH="$ROOT/bin:$path" "$BASH" "$ROOT/bin/$hook" 2>>"$home/hook.stderr"
}

new_home() {
  local home="$test_tmp/hooks-$1"

  mkdir -p "$home/.local/state/maitri/current"
  cp -r "$test_tmp/$2/.local/state/maitri/current/next-theme" "$home/.local/state/maitri/current/theme"
  : >"$home/hook.stderr"
  printf '%s' "$home"
}

home=$(new_home missing amethyst)
for hook in "${hooks[@]}"; do
  run_hook "$home" "$hook" "$sandbox" || fail "$hook exits cleanly when its app is missing"
done
[[ ! -e $home/.config ]] || fail "the CLI tool hooks write nothing when the tools are missing" "$(find "$home/.config")"
[[ ! -s $home/hook.stderr ]] || fail "the CLI tool hooks stay quiet when the tools are missing" "$(cat "$home/hook.stderr")"

for theme in amethyst daybreak; do
  home=$(new_home "$theme" "$theme")
  rendered="$home/.local/state/maitri/current/theme"
  config="$home/.config"
  mkdir -p "$config/git" "$config/lazygit" "$config/fish" "$config/bat" "$config/yazi" "$home/dotfiles"

  cp "$ROOT/config/fish/config.fish" "$config/fish/config.fish"
  { cat "$ROOT/config/git/config"; printf '[delta]\n\tside-by-side = true\n'; } >"$home/dotfiles/gitconfig"
  ln -s "$home/dotfiles/gitconfig" "$config/git/config"
  printf -- '--style=numbers\n' >"$config/bat/config"
  printf '[status]\noverall = {}\n' >"$config/yazi/theme.toml"
  cat >"$config/lazygit/config.yml" <<'YAML'
gui:
    showIcons: true
    # keep this comment
git:
    autoFetch: false
YAML

  for pass in first second; do
    for hook in "${hooks[@]}"; do
      run_hook "$home" "$hook" "$apps:$sandbox" || fail "$hook applies the $theme theme ($pass run)"
    done
    find "$config" -type f -exec md5sum {} + | sort >"$home/$pass.sums"
  done
  diff "$home/first.sums" "$home/second.sums" >/dev/null || fail "running the hooks again for $theme changes nothing" "$(diff "$home/first.sums" "$home/second.sums")"

  [[ $(<"$rendered/bat.tmTheme") == "$(<"$config/bat/themes/maitri.tmTheme")" ]] || fail "bat gets the $theme theme in its themes dir"
  grep -q '^cache --build$' "$home/bat.log" || fail "the bat hook rebuilds bat's theme cache"
  [[ $(sed -n 2p "$config/bat/config") == '--theme="maitri"' && $(tail -n 1 "$config/bat/config") == '--style=numbers' ]] ||
    fail "bat's config selects maitri above the user's own options" "$(cat "$config/bat/config")"

  [[ -L $config/git/config ]] || fail "a symlinked git config stays a symlink"
  git_config=$(<"$home/dotfiles/gitconfig")
  [[ $git_config == *$'\n[delta]\n\tsyntax-theme = maitri\n'* ]] || fail "git's config gets the [delta] block" "$git_config"
  [[ $git_config == *$'# <<< maitri theme <<<\n\n[alias]'* ]] || fail "the [delta] block sits above the user's sections" "$git_config"
  [[ $git_config == *$'[delta]\n\tside-by-side = true' ]] || fail "the user's own [delta] settings stay below and win" "$git_config"
  delta_keys=$(awk '/^\[delta\]/ { on = 1; next } /^[[#]/ { on = 0 } on' "$home/dotfiles/gitconfig" | head -n -1)
  [[ $delta_keys == "$(tail -n +2 "$rendered/delta.gitconfig")" ]] || fail "the [delta] block is the rendered $theme delta theme" "$delta_keys"

  lazygit_config=$(<"$config/lazygit/config.yml")
  [[ $lazygit_config == $'gui:\n    # >>> maitri theme (rewritten by maitri theme set) >>>\n    theme:\n        activeBorderColor:\n            - "#'* ]] ||
    fail "lazygit's theme goes under the user's gui key at its indentation" "$lazygit_config"
  [[ $lazygit_config == *$'    # <<< maitri theme <<<\n    showIcons: true\n    # keep this comment\ngit:\n    autoFetch: false' ]] ||
    fail "lazygit keeps the user's other settings" "$lazygit_config"
  border_focus=$(awk -F'\t' '$1 == "border_focus" { print $2 }' "$test_tmp/$theme/palette.tsv")
  grep -qF "            - \"$border_focus\"" "$config/lazygit/config.yml" || fail "lazygit's active border is the $theme border_focus"

  fish_config=$(<"$config/fish/config.fish")
  fish_block=$({ echo "if command -q fzf"; sed 's/^/    /' "$rendered/fzf.fish"; echo "end"; echo "set -gx BAT_THEME maitri"; })
  [[ $fish_config == *$'and the look. Add your own aliases, functions and exports below.\n\n# >>> maitri theme (rewritten by maitri theme set) >>>\n'"$fish_block"$'\n# <<< maitri theme <<<\n\n# MAITRI_PATH:'* ]] ||
    fail "config.fish gets the $theme fzf colours and BAT_THEME after its header" "$fish_config"

  flavor="$config/yazi/flavors/maitri.yazi"
  [[ $(<"$rendered/yazi.toml") == "$(<"$flavor/flavor.toml")" ]] || fail "yazi gets the $theme theme as the maitri flavor"
  [[ $(<"$rendered/bat.tmTheme") == "$(<"$flavor/tmtheme.xml")" ]] || fail "yazi's flavor highlights code with the bat theme"
  [[ $(<"$config/yazi/theme.toml") == $'[status]\noverall = {}\n\n# >>> maitri theme (rewritten by maitri theme set) >>>\n[flavor]\ndark = "maitri"\nlight = "maitri"\n# <<< maitri theme <<<' ]] ||
    fail "yazi's theme.toml picks the maitri flavor below the user's own tables" "$(cat "$config/yazi/theme.toml")"
  [[ -z $(find "$config" -name '.maitri-theme.*') ]] || fail "the hooks leave no staging files behind"

  (( $(grep -c "New fish shells pick up the maitri fzf and bat colours" "$home/hook.stderr") == 1 )) ||
    fail "the fzf hook says once that open shells keep their colours" "$(cat "$home/hook.stderr")"
  grep -q "yazi picks up the new maitri colours after a restart" "$home/hook.stderr" || fail "the yazi hook says a running yazi needs a restart"
  ! grep -vqE "New fish shells|yazi picks up" "$home/hook.stderr" || fail "the hooks print nothing else" "$(cat "$home/hook.stderr")"
done

pass "the CLI tool hooks install only for tools that are present, keep the user's settings and run idempotently"

home="$test_tmp/hooks-daybreak"
rm -rf "$home/.local/state/maitri/current/theme"
cp -r "$test_tmp/amethyst/.local/state/maitri/current/next-theme" "$home/.local/state/maitri/current/theme"
for hook in "${hooks[@]}"; do
  run_hook "$home" "$hook" "$apps:$sandbox" || fail "$hook switches daybreak to amethyst"
done
for file in "$home/dotfiles/gitconfig" "$home/.config/lazygit/config.yml" "$home/.config/fish/config.fish" "$home/.config/bat/config" "$home/.config/yazi/theme.toml"; do
  (( $(grep -c '# >>> maitri theme' "$file") == 1 )) || fail "a theme change leaves one block in $(basename "$file")" "$(cat "$file")"
  ! grep -q '#644AC9' "$file" || fail "a theme change drops daybreak's colours from $(basename "$file")" "$(cat "$file")"
done
grep -q '#B08CFF' "$home/dotfiles/gitconfig" && grep -q '#B08CFF' "$home/.config/fish/config.fish" &&
  grep -q '#7058A3' "$home/.config/lazygit/config.yml" || fail "a theme change brings in amethyst's colours"
pass "switching themes replaces each block rather than adding another"

if command -v fish >/dev/null 2>&1; then
  printf '#!/bin/bash\n' >"$test_tmp/fzf"
  chmod +x "$test_tmp/fzf"
  block=$(awk '/^# >>> maitri theme/ { on = 1; next } /^# <<< maitri theme/ { on = 0 } on' "$home/.config/fish/config.fish")
  got=$(env -u FZF_DEFAULT_OPTS -u MAITRI_FZF_COLORS PATH="$test_tmp:$PATH" fish --no-config -c "
    set -gx FZF_DEFAULT_OPTS '--cycle'
    set -gx BAT_THEME ansi
    $block
    echo \$BAT_THEME \$FZF_DEFAULT_OPTS")
  [[ $got == "maitri --cycle --color=fg:#E6E9F0,"* ]] || fail "the config.fish block sets BAT_THEME and the fzf colours in fish" "$got"
  pass "the config.fish block runs in fish after the vendor settings"
else
  skip "the config.fish block runs in fish after the vendor settings (fish is not installed)"
fi

home=$(new_home empty amethyst)
mkdir -p "$home/.config/lazygit" "$home/.config/jesseduffield/lazygit"
: >"$home/.config/jesseduffield/lazygit/config.yml"
run_hook "$home" maitri-theme-set-lazygit "$apps:$sandbox" || fail "maitri-theme-set-lazygit fills an empty config"
[[ $(head -n 3 "$home/.config/jesseduffield/lazygit/config.yml") == $'gui:\n  # >>> maitri theme (rewritten by maitri theme set) >>>\n  theme:' ]] ||
  fail "an empty lazygit config, in the directory lazygit still prefers, gets gui.theme" "$(cat "$home/.config/jesseduffield/lazygit/config.yml")"
[[ ! -e $home/.config/lazygit/config.yml ]] || fail "the lazygit hook writes where lazygit reads"
printf 'gui:\n  # >>> maitri theme (rewritten by maitri theme set) >>>\n  showIcons: true\ncustomCommands:\n  - key: x\n' >"$home/.config/jesseduffield/lazygit/config.yml"
run_hook "$home" maitri-theme-set-lazygit "$apps:$sandbox" || fail "maitri-theme-set-lazygit handles a block without its end marker"
grep -q 'showIcons: true' "$home/.config/jesseduffield/lazygit/config.yml" && grep -q '  - key: x' "$home/.config/jesseduffield/lazygit/config.yml" ||
  fail "a start marker without an end loses none of the user's lines" "$(cat "$home/.config/jesseduffield/lazygit/config.yml")"
pass "the lazygit hook writes where lazygit reads and never drops the user's lines"

home=$(new_home own amethyst)
config="$home/.config"
mkdir -p "$config/lazygit" "$config/bat" "$config/yazi"
printf 'gui:\n  theme:\n    activeBorderColor:\n      - red\n' >"$config/lazygit/config.yml"
printf -- '--theme="Nord"\n' >"$config/bat/config"
printf '[flavor]\ndark = "mine"\n' >"$config/yazi/theme.toml"
cp "$config/lazygit/config.yml" "$home/lazygit.before"
for hook in maitri-theme-set-lazygit maitri-theme-set-bat maitri-theme-set-yazi; do
  run_hook "$home" "$hook" "$apps:$sandbox" || fail "$hook leaves a user's own theme in place"
done
cmp -s "$config/lazygit/config.yml" "$home/lazygit.before" || fail "lazygit keeps the user's own gui.theme" "$(cat "$config/lazygit/config.yml")"
[[ $(<"$config/bat/config") == '--theme="Nord"' ]] || fail "bat keeps the user's own --theme" "$(cat "$config/bat/config")"
[[ $(<"$config/yazi/theme.toml") == $'[flavor]\ndark = "mine"' ]] || fail "yazi keeps the user's own flavor" "$(cat "$config/yazi/theme.toml")"
grep -q "sets its own gui.theme" "$home/hook.stderr" || fail "the lazygit hook says why it left the config alone"
grep -q "picks its own flavor" "$home/hook.stderr" || fail "the yazi hook says why it left theme.toml alone"
pass "the hooks leave a theme the user chose in place and say so"

home=$(new_home hostile amethyst)
rendered="$home/.local/state/maitri/current/theme"
printf 'gui:\n  theme:\n    activeBorderColor:\n      - "#ffffff"\n    x: !!binary aGk=\nos:\n  edit: "touch pwned"\n' >"$rendered/lazygit.yml"
printf '[delta]\n\tsyntax-theme = maitri\n\tpager = sh -c "touch pwned"\n[core]\n\tpager = touch pwned\n' >"$rendered/delta.gitconfig"
printf '<plist>{{ accent }}</plist>\n' >"$rendered/bat.tmTheme"
printf '[mgr]\ncwd = { fg = "{{ accent }}" }\n' >"$rendered/yazi.toml"
for hook in "${hooks[@]}"; do
  run_hook "$home" "$hook" "$apps:$sandbox" || fail "$hook skips a rendered file it won't apply"
done
! grep -rq pwned "$home/.config" || fail "nothing from a rendered file beyond colours reaches the configs" "$(grep -rn pwned "$home/.config")"
[[ ! -e $home/.config/lazygit/config.yml && ! -e $home/.config/git/config && ! -e $home/.config/bat && ! -e $home/.config/yazi ]] ||
  fail "the hooks write nothing from a rendered file they skip" "$(find "$home/.config" -type f)"
for app in lazygit delta bat yazi; do
  grep -qi "Skipping $app theme" "$home/hook.stderr" || fail "the $app hook says why it skipped" "$(cat "$home/hook.stderr")"
done
pass "the hooks apply only colour settings and skip files with unresolved colours"

home=$(new_home filtered amethyst)
rendered="$home/.local/state/maitri/current/theme"
printf 'gui:\n  theme:\n    activeBorderColor:\n      - "#123456"\n  showIcons: true\nos:\n  edit: "touch pwned"\n' >"$rendered/lazygit.yml"
printf '[delta]\n\tfile-style = bold "#123456"\n[core]\n\tpager = touch pwned\n' >"$rendered/delta.gitconfig"
sed -i 's/^set -gx MAITRI_FZF_COLORS "--color=fg:#[0-9A-Fa-f]*,/set -gx MAITRI_FZF_COLORS "--color=fg:#ffffff --preview pwned,/' "$rendered/fzf.fish"
for hook in "${hooks[@]}"; do
  run_hook "$home" "$hook" "$apps:$sandbox" || fail "$hook filters a rendered file"
done
! grep -rq pwned "$home/.config" || fail "only the theme's colour settings reach the configs" "$(grep -rn pwned "$home/.config")"
grep -q '      - "#123456"' "$home/.config/lazygit/config.yml" && ! grep -q showIcons "$home/.config/lazygit/config.yml" ||
  fail "lazygit gets gui.theme and nothing else" "$(cat "$home/.config/lazygit/config.yml")"
[[ $(awk '/^\[/ { section = $0 } /^\t/ { print section $0 }' "$home/.config/git/config") == $'[delta]\tfile-style = bold "#123456"' ]] ||
  fail "git's config gets the [delta] styles and nothing else" "$(cat "$home/.config/git/config")"
! grep -q 'MAITRI_FZF_COLORS' "$home/.config/fish/config.fish" && grep -q 'set -gx BAT_THEME maitri' "$home/.config/fish/config.fish" ||
  fail "fzf colours that would add an option never reach config.fish" "$(cat "$home/.config/fish/config.fish")"
grep -q "Skipping fzf theme" "$home/hook.stderr" || fail "the fzf hook says why it skipped" "$(cat "$home/hook.stderr")"

home=$(new_home quotes amethyst)
printf '[delta]\n\tminus-style = "#ff0000\n' >"$home/.local/state/maitri/current/theme/delta.gitconfig"
run_hook "$home" maitri-theme-set-bat "$apps:$sandbox" || fail "maitri-theme-set-bat skips an unbalanced quote"
! grep -q 'minus-style' "$home/.config/git/config" 2>/dev/null || fail "an unbalanced quote never reaches git's config"
grep -q "Skipping delta theme" "$home/hook.stderr" || fail "the bat hook says why it skipped the delta theme"
pass "the hooks keep a rendered file's colours and drop everything else"

if command -v bat >/dev/null 2>&1 && command -v delta >/dev/null 2>&1; then
  home=$(new_home real daybreak)
  run_hook "$home" maitri-theme-set-bat "$PATH" || fail "maitri-theme-set-bat runs with the real bat and delta"
  isolated "$home" bat --list-themes --color=never | grep -qx maitri || fail "bat lists the maitri theme"
  printf 'x = 1\n' >"$home/a.py"
  got=$(cd "$home" && isolated "$home" git diff --no-index --color=never /dev/null a.py | isolated "$home" delta --color-only 2>&1 >/dev/null || true)
  [[ -z $got ]] || fail "delta loads the maitri syntax theme without warnings" "$got"
  pass "bat builds and delta loads the maitri theme"
else
  skip "bat builds and delta loads the maitri theme (bat or delta is not installed)"
fi
