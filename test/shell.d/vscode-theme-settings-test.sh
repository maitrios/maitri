#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

require_command python3

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

mock_bin="$test_tmp/bin"
test_home="$test_tmp/home"
theme_dir="$test_home/.local/state/maitri/current/theme"
settings="$test_home/.config/Code/User/settings.json"
mkdir -p "$mock_bin" "$theme_dir" "$(dirname "$settings")"

cat >"$mock_bin/maitri-cmd-present" <<'SH'
#!/bin/bash
[[ $1 == "code" ]]
SH
printf '#!/bin/bash\nexit 1\n' >"$mock_bin/maitri-toggle-enabled"
printf '#!/bin/bash\necho publisher.theme\n' >"$mock_bin/code"
chmod +x "$mock_bin"/*

theme_set() {
  HOME="$test_home" PATH="$mock_bin:$ROOT/bin:$PATH" bash "$ROOT/bin/maitri-theme-set-vscode" >/dev/null 2>"$test_tmp/stderr"
}

use_theme() {
  jq -n --arg name "$1" '{name: $name, extension: "publisher.theme"}' >"$theme_dir/vscode.json"
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

has_key() {
  python3 -c '
import json, re, sys
text = open(sys.argv[1]).read()
text = re.sub(r"/\*.*?\*/|//[^\n]*", "", text, flags=re.S)
text = re.sub(r",(\s*[}\]])", r"\1", text)
pairs = json.loads(text, object_pairs_hook=lambda pairs: pairs)
sys.exit(0 if any(key == sys.argv[2] for key, _ in pairs) else 1)
' "$settings" "$1"
}

use_theme "Tokyo Night"
rm -f "$settings"
theme_set || fail "maitri-theme-set-vscode creates a missing settings.json"
python3 -c 'import json, sys; json.load(open(sys.argv[1]))' "$settings" ||
  fail "a new settings.json is strict JSON" "$(cat "$settings")"
[[ $(json_value workbench.colorTheme) == "Tokyo Night" ]] || fail "a new settings.json gets the theme" "$(cat "$settings")"
[[ $(cat "$settings") == $'{\n  "workbench.colorTheme": "Tokyo Night"\n}' ]] || fail "a new settings.json has no stray blank line" "$(cat "$settings")"
pass "maitri-theme-set-vscode writes the theme into a new settings.json"

printf '{\n  "[python]": {\n    "workbench.colorTheme": "Python Theme"\n  },\n  "editor.fontSize": 14\n}\n' >"$settings"
theme_set
[[ $(json_value workbench.colorTheme) == "Tokyo Night" ]] ||
  fail "maitri-theme-set-vscode sets the top-level theme beside a language override" "$(cat "$settings")"
[[ $(json_value '[python]' workbench.colorTheme) == "Python Theme" ]] ||
  fail "maitri-theme-set-vscode leaves a language override alone" "$(cat "$settings")"
before=$(cat "$settings")
theme_set
[[ $(cat "$settings") == "$before" ]] || fail "a second run leaves the settings as they are" "$(cat "$settings")"
pass "maitri-theme-set-vscode sets the top-level theme and leaves a language override alone"

printf '{\n  // "workbench.colorTheme": "Old Theme",\n  "editor.fontSize": 14,\n}\n' >"$settings"
theme_set
grep -Fxq '  // "workbench.colorTheme": "Old Theme",' "$settings" ||
  fail "maitri-theme-set-vscode keeps a commented-out key as it is" "$(cat "$settings")"
[[ $(json_value workbench.colorTheme) == "Tokyo Night" ]] ||
  fail "a commented-out key doesn't block the insert" "$(cat "$settings")"
pass "maitri-theme-set-vscode adds the theme when only a commented-out copy exists"

printf '{\n  "workbench.colorTheme": "Old Theme"\n  "editor.fontSize": 14\n}\n' >"$settings"
cp "$settings" "$test_tmp/invalid.json"
theme_set || fail "maitri-theme-set-vscode carries on past invalid settings"
cmp -s "$settings" "$test_tmp/invalid.json" || fail "invalid settings stay byte-identical" "$(cat "$settings")"
(( $(wc -l <"$test_tmp/stderr") == 1 )) && grep -Fq "isn't valid JSON" "$test_tmp/stderr" ||
  fail "invalid settings get a one-line notice" "$(cat "$test_tmp/stderr")"
pass "maitri-theme-set-vscode leaves invalid settings byte-identical with a notice"

use_theme 'Quote "Theme" \ Dark'
printf '{\n  "workbench.colorTheme": "Has \\"escaped\\" quotes",\n  "editor.fontSize": 14\n}\n' >"$settings"
theme_set
[[ $(json_value workbench.colorTheme) == 'Quote "Theme" \ Dark' ]] ||
  fail "maitri-theme-set-vscode escapes a theme name with quotes" "$(cat "$settings")"
[[ $(json_value editor.fontSize) == 14 ]] || fail "an escaped quote doesn't corrupt the rest of the file" "$(cat "$settings")"
pass "maitri-theme-set-vscode escapes quotes in the theme name and replaces escaped values whole"

use_theme "Tokyo Night"
cp "$ROOT/config/Code/User/settings.json" "$test_tmp/dotfile.json"
ln -sfn "$test_tmp/dotfile.json" "$settings"
theme_set
[[ -L $settings ]] || fail "a symlinked settings.json stays a symlink"
[[ $(json_value workbench.colorTheme) == "Tokyo Night" ]] || fail "a symlinked settings.json gets the theme"
[[ -z $(find "$test_tmp" -name '.settings.json.*') ]] || fail "maitri-theme-set-vscode leaves no temp file"
pass "maitri-theme-set-vscode writes through a symlinked settings.json"
rm -f "$settings"

rm -f "$theme_dir/vscode.json"
printf '{\n  "workbench.colorTheme": "Old Theme", // set by maitri\n  "[python]": {\n    "workbench.colorTheme": "Python Theme"\n  },\n  "editor.fontSize": 14\n}\n' >"$settings"
theme_set
has_key workbench.colorTheme && fail "a theme without VS Code colors drops the top-level theme" "$(cat "$settings")"
[[ $(json_value '[python]' workbench.colorTheme) == "Python Theme" && $(json_value editor.fontSize) == 14 ]] ||
  fail "dropping the theme leaves the rest alone" "$(cat "$settings")"
grep -Fq '// set by maitri' "$settings" || fail "dropping the theme keeps a comment beside it" "$(cat "$settings")"
pass "maitri-theme-set-vscode drops only the top-level theme when the theme has no VS Code colors"

printf '{\n  "editor.fontSize": 14,\n  "workbench.colorTheme": "Old Theme"\n}\n' >"$settings"
theme_set
python3 -c 'import json, sys; json.load(open(sys.argv[1]))' "$settings" ||
  fail "dropping the last key leaves strict JSON" "$(cat "$settings")"
[[ $(cat "$settings") == $'{\n  "editor.fontSize": 14\n}' ]] || fail "dropping the last key removes its line" "$(cat "$settings")"
pass "maitri-theme-set-vscode drops a last-member theme without leaving a dangling comma"

printf '{\n  "workbench.colorTheme": "Old Theme"\n  "editor.fontSize": 14\n}\n' >"$settings"
theme_set
cmp -s "$settings" "$test_tmp/invalid.json" || fail "invalid settings stay byte-identical when dropping the theme" "$(cat "$settings")"
pass "maitri-theme-set-vscode leaves invalid settings byte-identical when dropping the theme"

unset_case() {
  local description="$1" input="$2" expected="$3"
  printf '%b' "$input" >"$test_tmp/unset.json"
  "$ROOT/bin/maitri-vscode-settings-set" "$test_tmp/unset.json" --unset workbench.colorTheme 2>"$test_tmp/stderr" ||
    fail "$description: the helper runs"
  [[ $(cat "$test_tmp/unset.json") == "$(printf '%b' "$expected")" ]] || fail "$description" "$(cat "$test_tmp/unset.json")"
  [[ ! -s $test_tmp/stderr ]] || fail "$description: no notice" "$(cat "$test_tmp/stderr")"
}

unset_case "the only key goes" '{\n  "workbench.colorTheme": "Old"\n}\n' '{\n}\n'
unset_case "the only key goes with its trailing comma" '{\n  "workbench.colorTheme": "Old",\n}\n' '{\n}\n'
unset_case "the only key on one line goes with its trailing comma" '{"workbench.colorTheme":"Old",}' '{}'
unset_case "a first key goes with its comma" '{\n  "workbench.colorTheme": "Old",\n  "a": 1\n}\n' '{\n  "a": 1\n}\n'
unset_case "a middle key goes with its comma" '{\n  "a": 1,\n  "workbench.colorTheme": "Old",\n  "b": 2\n}\n' '{\n  "a": 1,\n  "b": 2\n}\n'
unset_case "a last key takes the comma before it" '{\n  "a": 1,\n  "workbench.colorTheme": "Old"\n}\n' '{\n  "a": 1\n}\n'
unset_case "a last key with a trailing comma keeps the file's trailing comma" '{\n  "a": 1,\n  "workbench.colorTheme": "Old",\n}\n' '{\n  "a": 1,\n}\n'
unset_case "duplicate keys with a trailing comma all go" '{\n  "workbench.colorTheme": "A",\n  "workbench.colorTheme": "B",\n}\n' '{\n}\n'
unset_case "duplicate keys around another all go" '{\n  "workbench.colorTheme": "A",\n  "a": 1,\n  "workbench.colorTheme": "B"\n}\n' '{\n  "a": 1\n}\n'
unset_case "line comments before a last key stay" '{\n  "a": 1, // keep size\n  // note\n  "workbench.colorTheme": "Old"\n}\n' '{\n  "a": 1 // keep size\n  // note\n}\n'
unset_case "a block comment before a last key stays" '{\n  "a": 1,\n  /* block */\n  "workbench.colorTheme": "Old"\n}\n' '{\n  "a": 1\n  /* block */\n}\n'
unset_case "a first key on one line goes" '{"workbench.colorTheme": "Old", "a": 1}' '{"a": 1}'
unset_case "a middle key on one line goes" '{"a": 1, "workbench.colorTheme": "Old", "b": 2}' '{"a": 1, "b": 2}'
unset_case "a last key on one line goes" '{"a": 1, "workbench.colorTheme": "Old"}' '{"a": 1}'
pass "maitri-vscode-settings-set removes a key and its separator in every position and keeps comments"
