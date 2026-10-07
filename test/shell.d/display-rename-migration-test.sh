#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

require_command jq

migration="$ROOT/migrations/1791352296.sh"
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

mkdir -p "$test_dir/bin"

cat >"$test_dir/bin/maitri-restart-shell" <<'STUB'
#!/bin/bash

echo restart >>"$SHELL_RESTARTS"
STUB

chmod +x "$test_dir/bin/"*

export SHELL_RESTARTS="$test_dir/shell-restarts"

home="$test_dir/home"
config="$home/.config/maitri/shell.json"
output="$test_dir/output"

run_migration() {
  : >"$SHELL_RESTARTS"
  HOME="$home" PATH="$test_dir/bin:$PATH" bash -euo pipefail "$migration" >"$output"
}

# The shipped default with the old widget back in its place is what every
# machine installed before this migration has on disk.
write_config() {
  rm -rf "$home"
  mkdir -p "$home/.config/maitri"
  jq '(.bar.layout[][] | select((if type == "object" then .id else . end) == "maitri.display")) |= {id: "maitri.monitor"}' \
    "$ROOT/config/maitri/shell.json" | jq "${1:-.}" >"$config"
}

add_plugin() {
  mkdir -p "$home/.config/maitri/plugins/$1"
  printf '%s\n' "$2" >"$home/.config/maitri/plugins/$1/manifest.json"
}

ids() {
  jq -c --arg section "$1" '[.bar.layout[$section][]? | if type == "object" then .id else . end]' "$config"
}

all_ids() {
  jq -c '[.bar.layout[][] | if type == "object" then .id else . end]' "$config"
}

shipped_right='["maitri.tray","maitri.agents","maitri.bluetooth","maitri.network","maitri.audio","maitri.display","maitri.power"]'

# ------------------------------------------------------------------ shipped default

jq -e '[.bar.layout.right[].id] | index("maitri.display")' "$ROOT/config/maitri/shell.json" >/dev/null ||
  fail "shipped config puts the display widget in the bar"
jq -e '[.. | strings | select(. == "maitri.monitor")] | length == 0' "$ROOT/config/maitri/shell.json" >/dev/null ||
  fail "shipped config no longer mentions maitri.monitor"
pass "shipped config uses maitri.display"

write_config
run_migration
[[ $(ids right) == "$shipped_right" ]] || fail "migration swaps the widget in place" "$(ids right)"
pass "migration swaps the widget in place"

[[ ! -s $SHELL_RESTARTS ]] || fail "migration does not restart the shell"
pass "migration does not restart the shell"

before=$(cat "$config")
run_migration
[[ $(cat "$config") == "$before" ]] || fail "migration is idempotent"
pass "migration is idempotent"

# ------------------------------------------------------------------ entries

write_config '.bar.layout.left = ["maitri.monitor"] | .bar.layout.right |= map(select(.id != "maitri.monitor"))'
run_migration
[[ $(ids left) == '["maitri.display"]' ]] || fail "string entries are renamed" "$(ids left)"
pass "string entries are renamed"

write_config '(.bar.layout.right[] | select(.id == "maitri.monitor")) |= . + {settings: {compact: true}}'
run_migration
jq -e '.bar.layout.right[] | select(.id == "maitri.display") | .settings.compact == true' "$config" >/dev/null ||
  fail "entry settings survive the rename" "$(cat "$config")"
pass "entry settings survive the rename"

# ------------------------------------------------------------------ clones and the upstream plugin

write_config '(.bar.layout.right[] | select(.id == "maitri.monitor")) |= {id: "someone.monitor"}'
add_plugin someone.monitor '{"id":"someone.monitor","maitri":{"clonedFrom":"maitri.monitor"}}'
run_migration
[[ $(ids right) == "$shipped_right" ]] || fail "a clone of the old widget is replaced" "$(ids right)"
grep -q "maitri plugin remove someone.monitor" "$output" || fail "migration explains how to remove the clone" "$(cat "$output")"
[[ -d $home/.config/maitri/plugins/someone.monitor ]] || fail "migration leaves the clone on disk"
pass "a clone of the old widget is replaced and left on disk"

write_config '.bar.layout.center += [{"id": "crmne.hyprmoncfg"}]'
add_plugin crmne.hyprmoncfg '{"id":"crmne.hyprmoncfg"}'
run_migration
[[ $(all_ids | jq -c '[.[] | select(. == "maitri.display" or . == "crmne.hyprmoncfg" or . == "maitri.monitor")]') == '["maitri.display"]' ]] ||
  fail "the upstream hyprmoncfg plugin and the old widget become one display widget" "$(all_ids)"
grep -q "maitri plugin remove crmne.hyprmoncfg" "$output" || fail "migration explains how to remove the upstream plugin"
pass "the upstream hyprmoncfg plugin and the old widget become one display widget"

write_config '.bar.layout.left = ["maitri.display"]'
run_migration
[[ $(all_ids | jq -c '[.[] | select(. == "maitri.display")] | length') == 1 ]] || fail "an existing maitri.display is not duplicated" "$(all_ids)"
[[ $(ids left) == '["maitri.display"]' ]] || fail "the first display widget is the one kept" "$(ids left)"
pass "an existing maitri.display is not duplicated"

# ------------------------------------------------------------------ disabled plugins and bad configs

write_config '.disabledPlugins += ["maitri.monitor"]'
run_migration
jq -e '(.disabledPlugins | index("maitri.monitor")) == null and (.disabledPlugins | index("maitri.display")) == null' "$config" >/dev/null ||
  fail "the old id leaves disabledPlugins without disabling maitri.display" "$(jq -c .disabledPlugins "$config")"
pass "the old id leaves disabledPlugins without disabling maitri.display"

rm -rf "$home"
mkdir -p "$home/.config/maitri"
printf '{ not json' >"$config"
run_migration
[[ $(cat "$config") == "{ not json" ]] || fail "an unparsable config is left alone"
pass "an unparsable config is left alone"

rm -rf "$home"
mkdir -p "$home"
run_migration
[[ ! -e $config ]] || fail "a missing config stays missing"
pass "a missing config stays missing"
