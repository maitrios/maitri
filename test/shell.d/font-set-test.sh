#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

require_command python3

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

mock_bin="$test_tmp/bin"
test_home="$test_tmp/home"
settings="$test_home/.config/Code/User/settings.json"
odd_font='Odd "Quote" O'"'"'Mono\Font'
mkdir -p "$mock_bin" "$(dirname "$settings")"

cat >"$mock_bin/fc-list" <<SH
#!/bin/bash
cat <<'FONTS'
/usr/share/fonts/TTF/a.ttf: CaskaydiaCove Nerd Font,CaskaydiaCove NF:style=Regular
/usr/share/fonts/TTF/b.ttf: $odd_font:style=Regular
FONTS
SH

for command in maitri-cmd-present pgrep; do
  printf '#!/bin/bash\nexit 1\n' >"$mock_bin/$command"
done
for command in maitri-restart-shell maitri-hook maitri-notification-send pkill; do
  printf '#!/bin/bash\nexit 0\n' >"$mock_bin/$command"
done
chmod +x "$mock_bin"/*

font_set() {
  HOME="$test_home" PATH="$mock_bin:$PATH" bash "$ROOT/bin/maitri-font-set" "${1:-CaskaydiaCove Nerd Font}" >/dev/null 2>"$test_tmp/stderr"
}

json_value() {
  python3 -c '
import json, re, sys
text = open(sys.argv[1]).read()
text = re.sub(r"/\*.*?\*/|//[^\n]*", "", text, flags=re.S)
text = re.sub(r",(\s*[}\]])", r"\1", text)
value = json.loads(text)
for key in sys.argv[2:]:
    value = value[key]
print(value)
' "$settings" "$@"
}

assert_fonts() {
  local description="$1"
  [[ $(json_value editor.fontFamily) == "'CaskaydiaCove Nerd Font', 'monospace'" ]] ||
    fail "$description: editor font" "$(cat "$settings")"
  [[ $(json_value terminal.integrated.fontFamily) == "'CaskaydiaCove Nerd Font'" ]] ||
    fail "$description: terminal font" "$(cat "$settings")"
}

cp "$ROOT/config/Code/User/settings.json" "$settings"
font_set || fail "maitri-font-set switches to an installed font"
assert_fonts "maitri's VS Code settings"
[[ $(json_value update.mode) == none && $(json_value window.titleBarStyle) == custom ]] ||
  fail "maitri-font-set leaves the rest of the VS Code settings alone" "$(cat "$settings")"
[[ ! -s $test_tmp/stderr ]] || fail "maitri-font-set edits valid settings quietly" "$(cat "$test_tmp/stderr")"
pass "maitri-font-set sets the VS Code editor and terminal font"

printf '{\n  "update.mode": "none"\n}\n' >"$settings"
font_set
assert_fonts "minimal VS Code settings"
python3 -c 'import json, sys; json.load(open(sys.argv[1]))' "$settings" ||
  fail "minimal VS Code settings stay strict JSON" "$(cat "$settings")"
[[ $(json_value update.mode) == none ]] || fail "minimal VS Code settings keep update.mode" "$(cat "$settings")"
before=$(cat "$settings")
font_set
[[ $(cat "$settings") == "$before" ]] || fail "a second run leaves the settings as they are" "$(cat "$settings")"
pass "maitri-font-set adds the font keys to VS Code settings that lack them"

printf '{\n  "[python]": {\n    "editor.fontFamily": "Python Font"\n  },\n  "editor.fontSize": 14\n}\n' >"$settings"
font_set
assert_fonts "VS Code settings with a language override"
[[ $(json_value '[python]' editor.fontFamily) == "Python Font" ]] ||
  fail "maitri-font-set leaves a language override alone" "$(cat "$settings")"
pass "maitri-font-set sets the top-level font and leaves a language override alone"

printf '{\n  // "editor.fontFamily": "Old Font",\n  /* "terminal.integrated.fontFamily": "Old Font", */\n  "editor.fontSize": 14,\n}\n' >"$settings"
font_set
grep -Fxq '  // "editor.fontFamily": "Old Font",' "$settings" &&
  grep -Fxq '  /* "terminal.integrated.fontFamily": "Old Font", */' "$settings" ||
  fail "maitri-font-set keeps commented-out keys as they are" "$(cat "$settings")"
assert_fonts "VS Code settings with commented-out font keys"
[[ $(json_value editor.fontSize) == 14 ]] || fail "maitri-font-set keeps settings beside comments" "$(cat "$settings")"
pass "maitri-font-set adds the font keys when only commented-out copies exist"

printf '{\n  "editor.fontFamily": "Old Font"\n  "editor.fontSize": 14\n}\n' >"$settings"
cp "$settings" "$test_tmp/invalid.json"
font_set || fail "maitri-font-set carries on past invalid VS Code settings"
cmp -s "$settings" "$test_tmp/invalid.json" || fail "invalid VS Code settings stay byte-identical" "$(cat "$settings")"
(( $(wc -l <"$test_tmp/stderr") == 1 )) && grep -Fq "isn't valid JSON" "$test_tmp/stderr" ||
  fail "invalid VS Code settings get a one-line notice" "$(cat "$test_tmp/stderr")"
pass "maitri-font-set leaves invalid VS Code settings byte-identical with a notice"

printf '{\n  "editor.fontFamily": "Has \\"escaped\\" quotes",\n  "terminal.integrated.fontFamily": "x"\n}\n' >"$settings"
font_set "$odd_font"
[[ $(json_value editor.fontFamily) == "'Odd \"Quote\" O\\'Mono\\\\Font', 'monospace'" ]] ||
  fail "maitri-font-set escapes a font name with quotes for the editor" "$(cat "$settings")"
[[ $(json_value terminal.integrated.fontFamily) == "'Odd \"Quote\" O\\'Mono\\\\Font'" ]] ||
  fail "maitri-font-set escapes a font name with quotes for the terminal" "$(cat "$settings")"
pass "maitri-font-set escapes quotes in the font name and replaces escaped values whole"

cp "$ROOT/config/Code/User/settings.json" "$test_tmp/dotfile.json"
ln -sfn "$test_tmp/dotfile.json" "$settings"
font_set
[[ -L $settings ]] || fail "a symlinked settings.json stays a symlink"
assert_fonts "a symlinked settings.json"
[[ -z $(find "$test_tmp" -name '.settings.json.*') ]] || fail "maitri-font-set leaves no temp file"
pass "maitri-font-set writes through a symlinked settings.json"
