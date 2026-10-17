#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

require_command node

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

mock_bin="$test_tmp/bin"
test_home="$test_tmp/home"
mkdir -p "$mock_bin" "$test_home/.config/Code/User"

cat >"$mock_bin/fc-list" <<'SH'
#!/bin/bash
printf '/usr/share/fonts/TTF/CaskaydiaCoveNerdFont-Regular.ttf: CaskaydiaCove Nerd Font,CaskaydiaCove NF:style=Regular\n'
SH

for command in maitri-cmd-present pgrep; do
  printf '#!/bin/bash\nexit 1\n' >"$mock_bin/$command"
done
for command in maitri-restart-shell maitri-hook maitri-notification-send pkill; do
  printf '#!/bin/bash\nexit 0\n' >"$mock_bin/$command"
done
chmod +x "$mock_bin"/*

cp "$ROOT/config/Code/User/settings.json" "$test_home/.config/Code/User/settings.json"

HOME="$test_home" PATH="$mock_bin:$PATH" bash "$ROOT/bin/maitri-font-set" "CaskaydiaCove Nerd Font" >/dev/null ||
  fail "maitri-font-set switches to an installed font"

settings="$test_home/.config/Code/User/settings.json"
grep -Fxq "  \"editor.fontFamily\": \"'CaskaydiaCove Nerd Font', 'monospace'\"," "$settings" ||
  fail "maitri-font-set sets the VS Code editor font" "$(cat "$settings")"
grep -Fxq "  \"terminal.integrated.fontFamily\": \"'CaskaydiaCove Nerd Font'\"" "$settings" ||
  fail "maitri-font-set sets the VS Code terminal font" "$(cat "$settings")"
grep -Fxq '  "update.mode": "none",' "$settings" ||
  fail "maitri-font-set leaves the rest of the VS Code settings alone" "$(cat "$settings")"
node -e 'JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"))' "$settings" ||
  fail "VS Code settings stay valid JSON"
pass "maitri-font-set sets the VS Code editor and terminal font"

assert_font_keys_added() {
  local description="$1"

  HOME="$test_home" PATH="$mock_bin:$PATH" bash "$ROOT/bin/maitri-font-set" "CaskaydiaCove Nerd Font" >/dev/null ||
    fail "$description: maitri-font-set runs"
  grep -Fq "\"editor.fontFamily\": \"'CaskaydiaCove Nerd Font', 'monospace'\"" "$settings" ||
    fail "$description: editor font added" "$(cat "$settings")"
  grep -Fq "\"terminal.integrated.fontFamily\": \"'CaskaydiaCove Nerd Font'\"" "$settings" ||
    fail "$description: terminal font added" "$(cat "$settings")"
  (( $(grep -c '"editor.fontFamily"' "$settings") == 1 )) ||
    fail "$description: editor font key added once" "$(cat "$settings")"
}

printf '{\n  "update.mode": "none"\n}\n' >"$settings"
assert_font_keys_added "minimal VS Code settings"
node -e 'JSON.parse(require("fs").readFileSync(process.argv[1], "utf8"))' "$settings" ||
  fail "minimal VS Code settings stay valid JSON" "$(cat "$settings")"
grep -Fq '"update.mode": "none"' "$settings" ||
  fail "minimal VS Code settings keep update.mode" "$(cat "$settings")"
assert_font_keys_added "minimal VS Code settings on a second run"
pass "maitri-font-set adds the font keys to VS Code settings that lack them"

printf '{\n  // mine\n  "editor.fontSize": 14,\n}\n' >"$settings"
assert_font_keys_added "VS Code settings with comments"
grep -Fxq '  // mine' "$settings" && grep -Fxq '  "editor.fontSize": 14,' "$settings" ||
  fail "maitri-font-set keeps comments and other VS Code settings" "$(cat "$settings")"
pass "maitri-font-set adds the font keys without disturbing comments"
