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

printf '{\n  // mine\n  "editor.fontSize": 14,\n}\n' >"$settings"
HOME="$test_home" PATH="$mock_bin:$PATH" bash "$ROOT/bin/maitri-font-set" "CaskaydiaCove Nerd Font" >/dev/null ||
  fail "maitri-font-set runs over VS Code settings without font keys"
[[ $(cat "$settings") == $'{\n  // mine\n  "editor.fontSize": 14,\n}' ]] ||
  fail "maitri-font-set leaves VS Code settings without font keys untouched" "$(cat "$settings")"
pass "maitri-font-set leaves VS Code settings without font keys untouched"
