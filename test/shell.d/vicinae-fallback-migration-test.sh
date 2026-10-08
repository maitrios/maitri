#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

require_command jq

migration="$ROOT/migrations/1791364354.sh"
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

home="$test_dir/home"
settings="$home/.config/vicinae/settings.json"

run_migration() {
  HOME="$home" bash -euo pipefail "$migration" >"$test_dir/output"
}

write_settings() {
  rm -rf "$home"
  mkdir -p "$(dirname "$settings")"
  printf '%s\n' "$1" >"$settings"
  chmod 0644 "$settings"
}

[[ $(jq -c .fallbacks "$ROOT/config/vicinae/settings.json") == '["@maitrios/maitri:maitri-menu","files:search"]' ]] ||
  fail "new installs offer the maitri menu as a Vicinae fallback"
pass "new installs offer the maitri menu as a Vicinae fallback"

write_settings '{"close_on_focus_loss": true, "font": {"normal": {"size": 10.5}}}'
run_migration
[[ $(jq -c .fallbacks "$settings") == '["@maitrios/maitri:maitri-menu","files:search"]' ]] ||
  fail "migration adds the maitri menu fallback" "$(cat "$settings")"
[[ $(jq -c .font "$settings") == '{"normal":{"size":10.5}}' && $(jq .close_on_focus_loss "$settings") == true ]] ||
  fail "migration keeps the rest of the settings"
[[ $(stat -c %a "$settings") == 644 ]] || fail "migration keeps the settings file's mode"
pass "migration adds the fallback and keeps the rest of the settings"

before=$(cat "$settings")
run_migration
[[ $(cat "$settings") == "$before" ]] || fail "migration is idempotent"
pass "migration is idempotent"

write_settings '{"fallbacks": ["files:search"]}'
run_migration
[[ $(jq -c .fallbacks "$settings") == '["files:search"]' ]] || fail "a user's own fallbacks are left alone"
pass "a user's own fallbacks are left alone"

write_settings '// This configuration is merged with the default vicinae configuration file.
//
// Learn more about configuration at https://docs.vicinae.com/config

{
  "$schema": "https://vicinae.com/schemas/config.json",
  "close_on_focus_loss": false
}'
run_migration
[[ $(head -n 4 "$settings") == "$(printf '%s\n' '// This configuration is merged with the default vicinae configuration file.' '//' '// Learn more about configuration at https://docs.vicinae.com/config' '')" ]] ||
  fail "migration keeps the header Vicinae writes" "$(cat "$settings")"
[[ $(grep -v '^//' "$settings" | jq -c '[.fallbacks, .close_on_focus_loss, ."$schema"]') == '[["@maitrios/maitri:maitri-menu","files:search"],false,"https://vicinae.com/schemas/config.json"]' ]] ||
  fail "migration adds the fallback under the header Vicinae writes" "$(cat "$settings")"
pass "settings Vicinae wrote, comment header and all, get the fallback"

write_settings '{
  // my settings
  "close_on_focus_loss": false
}'
before=$(cat "$settings")
run_migration
[[ $(cat "$settings") == "$before" ]] || fail "settings with comments inside the JSON are left alone"
grep -q '@maitrios/maitri:maitri-menu' "$test_dir/output" || fail "migration says how to add the fallback by hand"
pass "settings with comments inside the JSON are left alone, with a hint"

write_settings '// only a header'
before=$(cat "$settings")
run_migration
[[ $(cat "$settings") == "$before" ]] || fail "a settings file that is only comments is left alone"
pass "a settings file that is only comments is left alone"

rm -rf "$home"
mkdir -p "$home"
run_migration
[[ ! -e $settings ]] || fail "a user without Vicinae settings gets none"
pass "a user without Vicinae settings gets none"
