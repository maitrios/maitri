#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

migration="$ROOT/migrations/1791352548.sh"
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

mkdir -p "$test_dir/bin"

cat >"$test_dir/bin/systemctl" <<'STUB'
#!/bin/bash

echo "systemctl $*" >>"$CALLS"
if [[ $* == "--user list-units --type=scope --all --plain --no-legend" ]]; then
  printf '%s\n' \
    'app-Hyprland-maitri\x2dhyprland\x2dmonitor\x2dwatch-bf6450d3.scope loaded active running maitri-hyprland-monitor-watch' \
    'app-Hyprland-udiskie-1a2b3c4d.scope loaded active running udiskie'
fi
STUB

for command in pkill hyprctl; do
  cat >"$test_dir/bin/$command" <<STUB
#!/bin/bash

echo "$command \$*" >>"\$CALLS"
STUB
done

chmod +x "$test_dir/bin/"*

export CALLS="$test_dir/calls"
home="$test_dir/home"
toggles="$home/.local/state/maitri/toggles/hypr"
wants="$home/.config/systemd/user/graphical-session-pre.target.wants/maitri-recover-internal-monitor.service"

run_migration() {
  : >"$CALLS"
  HOME="$home" XDG_STATE_HOME="$home/.local/state" PATH="$test_dir/bin:$PATH" bash -euo pipefail "$migration" >/dev/null
}

reset_home() {
  rm -rf "$home"
  mkdir -p "$toggles" "$(dirname "$wants")"
  printf -- '-- maitri toggles\n' >"$toggles/flags.lua"
  printf 'hl.monitor({ output = "eDP-1", disabled = true })\n' >"$toggles/internal-monitor-disable.lua"
  printf 'hl.monitor({ output = "DP-1", mirror = "eDP-1" })\n' >"$toggles/internal-monitor-mirror.lua"
  printf 'hl.monitor({ output = "eDP-1", disabled = true })\n' >"$toggles/internal-monitor-clamshell.lua"
  printf '2\n' >"$toggles/internal-monitor-scale"
  printf 'scaled\n' >"$home/.local/state/maitri/monitor-scaling.log"
  ln -s /usr/lib/systemd/user/maitri-recover-internal-monitor.service "$wants"
}

reset_home
run_migration

grep -qxF 'systemctl --user stop app-Hyprland-maitri\x2dhyprland\x2dmonitor\x2dwatch-bf6450d3.scope' "$CALLS" ||
  fail "migration stops the running monitor watcher" "$(cat "$CALLS")"
! grep -q 'stop app-Hyprland-udiskie' "$CALLS" || fail "migration leaves other app scopes alone"
grep -qxF 'pkill -f bin/maitri-hyprland-monitor-watch' "$CALLS" || fail "migration stops a watcher started outside uwsm"
pass "migration stops the monitor watcher and nothing else"

[[ $(ls "$toggles") == "flags.lua" ]] || fail "migration removes the monitor toggles and scale state" "$(ls "$toggles")"
[[ ! -e $home/.local/state/maitri/monitor-scaling.log ]] || fail "migration removes the scaling log"
pass "migration removes the monitor toggles and scale state"

[[ ! -L $wants ]] || fail "migration disables the retired recovery unit"
grep -qx 'systemctl --user daemon-reload' "$CALLS" || fail "migration reloads the user manager after removing the unit"
pass "migration disables the retired recovery unit"

grep -qx 'hyprctl reload' "$CALLS" || fail "migration reloads Hyprland after removing toggles"
pass "migration reloads Hyprland after removing toggles"

run_migration
! grep -q 'hyprctl reload' "$CALLS" || fail "a second run has nothing to reload"
! grep -q 'daemon-reload' "$CALLS" || fail "a second run has no unit to remove"
pass "migration is idempotent"

reset_home
: >"$CALLS"
HOME="$home" XDG_STATE_HOME="$home/.local/state" PATH="$test_dir/bin:$PATH" MAITRI_LEGACY_UPGRADE_LIVE=1 bash -euo pipefail "$migration" >/dev/null
! grep -q 'hyprctl reload' "$CALLS" || fail "a legacy upgrade does not reload a config mid-swap"
pass "a legacy upgrade does not reload a config mid-swap"

rm -rf "$home"
mkdir -p "$home"
run_migration
pass "migration runs on a home without any monitor state"

reset_home
: >"$CALLS"
HOME="$home" XDG_STATE_HOME="$test_dir/elsewhere" PATH="$test_dir/bin:$PATH" bash -euo pipefail "$migration" >/dev/null
[[ ! -e $toggles/internal-monitor-scale ]] || fail "migration cleans the state path the old monitor scripts wrote to"
pass "migration cleans the state path the old monitor scripts wrote to, whatever XDG_STATE_HOME says"
