#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

writers=$(grep -rnE 'hyprctl (keyword|-[a-z]+ keyword) monitor|hyprctl eval .*hl\.monitor\(|\["hyprctl", "(keyword|eval)"' \
  "$ROOT/bin" "$ROOT/default" "$ROOT/shell" 2>/dev/null || true)
[[ -z $writers ]] || fail "nothing but hyprmoncfgd writes monitor config" "$writers"
pass "nothing but hyprmoncfgd writes monitor config"

! grep -q 'monitor-watch' "$ROOT/default/hypr/autostart.lua" ||
  fail "autostart launches no monitor watcher"
pass "autostart launches no monitor watcher"

for command in maitri-system-lid-close maitri-system-sleep-lock maitri-system-wake; do
  ! grep -qE 'maitri-hyprland-monitor-|monitor-clamshell' "$ROOT/bin/$command" ||
    fail "$command leaves displays to hyprmoncfgd"
done
pass "lid close, sleep lock and wake leave displays to hyprmoncfgd"

! grep -rqE '\.config/hypr' "$ROOT/shell/plugins/panels/display"/*.qml "$ROOT/shell/plugins/panels/display"/*.js ||
  fail "the Display panel never touches Hyprland config files"
pass "the Display panel never touches Hyprland config files"
