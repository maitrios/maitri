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

  [[ -f $next_theme/chatgpt.txt ]] || fail "$theme renders chatgpt.txt"
  ! grep -q '{{' "$next_theme/chatgpt.txt" || fail "$theme leaves no placeholders in chatgpt.txt" "$(grep -n '{{' "$next_theme/chatgpt.txt")"
  themes+=("$theme")
done

(( ${#themes[@]} == 6 )) || fail "all six themes are rendered" "rendered: ${themes[*]}"

python3 -I - "$test_tmp" "${themes[@]}" <<'PY'
import json, re, sys

root, themes = sys.argv[1], sys.argv[2:]
failed = False

def luminance(color):
    channels = []
    for i in (1, 3, 5):
        c = int(color[i:i + 2], 16) / 255
        channels.append(c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4)
    return 0.2126 * channels[0] + 0.7152 * channels[1] + 0.0722 * channels[2]

def contrast(a, b):
    la, lb = sorted((luminance(a), luminance(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)

for theme in themes:
    palette = dict(line.rstrip("\n").split("\t", 1) for line in open(f"{root}/{theme}/palette.tsv"))
    text = open(f"{root}/{theme}/.local/state/maitri/current/next-theme/chatgpt.txt").read().strip()
    problems = []
    if not text.startswith("codex-theme-v1:"):
        problems.append(f"chatgpt.txt starts {text[:20]!r}, not codex-theme-v1:")
    else:
        data = json.loads(text[len("codex-theme-v1:"):])
        t = data["theme"]
        mode = palette["mode"]
        if data["variant"] != mode:
            problems.append(f"variant is {data['variant']}, not {mode}")
        if data["codeThemeId"] != f"github-{mode}":
            problems.append(f"codeThemeId is {data['codeThemeId']}")
        for key, want in (("surface", "background"), ("ink", "foreground"), ("accent", "accent")):
            if t[key].lower() != palette[want].lower():
                problems.append(f"{key} is {t[key]}, not {want} {palette[want]}")
        for key, want in (("diffAdded", "green"), ("diffRemoved", "red"), ("skill", "magenta")):
            if t["semanticColors"][key].lower() != palette[want].lower():
                problems.append(f"{key} is {t['semanticColors'][key]}, not {want}")
        if not 0 <= t["contrast"] <= 100:
            problems.append(f"contrast {t['contrast']} is out of range")
        if contrast(t["ink"], t["surface"]) < 4.5:
            problems.append("ink on surface is under 4.5:1")
    for problem in problems:
        print(f"FAIL\t{theme}\tchatgpt\t{problem}")
        failed = True
    if not problems:
        print(f"ok\t{theme}\tchatgpt")

sys.exit(1 if failed else 0)
PY
pass "ChatGPT renders a theme string for every theme that follows the palette"

sandbox="$test_tmp/sandbox-bin"
apps="$test_tmp/app-bin"
mkdir -p "$sandbox" "$apps"
for tool in cat grep jq mkdir mktemp mv tr; do
  ln -s "$(command -v "$tool")" "$sandbox/$tool"
done
printf '#!/bin/bash\n' >"$apps/chatgpt"
printf '#!/bin/bash\ncat >"$HOME/clipboard"\n' >"$apps/wl-copy"
chmod +x "$apps/chatgpt" "$apps/wl-copy"

run_hook() {
  local home="$1" hook="$2" path="$3"

  env -u XDG_CONFIG_HOME -u XDG_DATA_HOME HOME="$home" MAITRI_PATH="$ROOT" PATH="$ROOT/bin:$path" "$BASH" "$ROOT/bin/$hook" 2>>"$home/hook.stderr"
}

stage_theme() {
  local home="$1" theme="$2"

  mkdir -p "$home/.local/state/maitri/current"
  rm -rf "$home/.local/state/maitri/current/theme"
  cp -r "$test_tmp/$theme/.local/state/maitri/current/next-theme" "$home/.local/state/maitri/current/theme"
  : >"$home/hook.stderr"
}

home="$test_tmp/missing"
stage_theme "$home" amethyst
run_hook "$home" maitri-theme-set-chatgpt "$sandbox" || fail "maitri-theme-set-chatgpt exits cleanly when ChatGPT is missing"
[[ ! -s $home/hook.stderr ]] || fail "the ChatGPT hook stays quiet when the app is missing" "$(cat "$home/hook.stderr")"

for theme in amethyst daybreak; do
  home="$test_tmp/present-$theme"
  stage_theme "$home" "$theme"

  run_hook "$home" maitri-theme-set-chatgpt "$apps:$sandbox" || fail "maitri-theme-set-chatgpt runs with ChatGPT present"
  grep -q "maitri theme chatgpt-copy" "$home/hook.stderr" && grep -q "Settings > Appearance" "$home/hook.stderr" ||
    fail "theme set tells a ChatGPT user how to paste the colours" "$(cat "$home/hook.stderr")"
  (( $(wc -l <"$home/hook.stderr") == 1 )) || fail "the ChatGPT hint is one line" "$(cat "$home/hook.stderr")"
  [[ ! -e $home/.config ]] || fail "the ChatGPT hook writes nothing"

  output=$(run_hook "$home" maitri-theme-chatgpt-copy "$apps:$sandbox") || fail "maitri-theme-chatgpt-copy copies the $theme theme"
  [[ $(<"$home/clipboard") == "$(tr -d '\n' <"$home/.local/state/maitri/current/theme/chatgpt.txt")" ]] ||
    fail "the clipboard holds the $theme ChatGPT theme string" "$(cat "$home/clipboard")"
  [[ $output == *"Settings > Appearance"* ]] || fail "maitri-theme-chatgpt-copy says where to paste" "$output"
done

printf 'codex-theme-v1:{nope\n' >"$home/.local/state/maitri/current/theme/chatgpt.txt"
rm -f "$home/clipboard"
! run_hook "$home" maitri-theme-chatgpt-copy "$apps:$sandbox" >/dev/null || fail "maitri-theme-chatgpt-copy refuses a chatgpt.txt that isn't a theme string"
[[ ! -e $home/clipboard ]] || fail "a chatgpt.txt that isn't a theme string never reaches the clipboard"

broken="$test_tmp/broken-bin"
mkdir -p "$broken"
printf '#!/bin/bash\nexit 1\n' >"$broken/wl-copy"
chmod +x "$broken/wl-copy"
cp "$test_tmp/amethyst/.local/state/maitri/current/next-theme/chatgpt.txt" "$home/.local/state/maitri/current/theme/chatgpt.txt"
! output=$(run_hook "$home" maitri-theme-chatgpt-copy "$broken:$apps:$sandbox") || fail "maitri-theme-chatgpt-copy fails when wl-copy does"
[[ $output != *Copied* ]] || fail "maitri-theme-chatgpt-copy never says it copied when wl-copy failed" "$output"

pass "the ChatGPT hook installs only when the app is present and says what a user has to do"
