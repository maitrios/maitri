#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

hook="$ROOT/default/systemd/system-sleep/lid-input-wake"

[[ -x $hook ]] ||
  fail "the lid input wake hook is executable" "mode: $(stat -c '%A' "$hook")"
pass "the lid input wake hook is executable"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

fake=$tmpdir/root
devices=$fake/sys/bus/i2c/devices
lid=$fake/proc/acpi/button/lid/LID/state
state=$fake/run/maitri-lid-input-wake

add_device() {
  local name=$1 modalias=$2 wakeup=$3
  mkdir -p "$devices/$name/power"
  printf '%s\n' "$modalias" >"$devices/$name/modalias"
  printf '%s\n' "$wakeup" >"$devices/$name/power/wakeup"
}

wakeup_of() {
  printf '%s' "$(<"$devices/$1/power/wakeup")"
}

reset_root() {
  rm -rf "$fake"
  mkdir -p "$fake/run" "${lid%/*}"
  add_device i2c-ELAN06B6:00 acpi:ELAN06B6:PNP0C50: enabled
  add_device i2c-WACF2200:00 acpi:WACF2200:ACPI0C50: disabled
  add_device i2c-INT3472:01 acpi:INT3472: enabled
}

run_hook() {
  MAITRI_SLEEP_HOOK_ROOT=$fake "$hook" "$@"
}

reset_root
printf 'state:      closed\n' >"$lid"
run_hook pre suspend
[[ $(wakeup_of i2c-ELAN06B6:00) == "disabled" ]] ||
  fail "a lid-closed suspend takes wake away from the touchpad" "wakeup: $(wakeup_of i2c-ELAN06B6:00)"
pass "a lid-closed suspend takes wake away from the touchpad"

[[ $(wakeup_of i2c-INT3472:01) == "enabled" ]] ||
  fail "devices that are not HID over I2C keep their wake"
pass "devices that are not HID over I2C keep their wake"

[[ $(<"$state") == "i2c-ELAN06B6:00" ]] ||
  fail "only the devices the hook turned off are recorded" "state: $(<"$state")"
pass "only the devices the hook turned off are recorded"

run_hook post suspend
[[ $(wakeup_of i2c-ELAN06B6:00) == "enabled" ]] ||
  fail "resume hands wake back to the touchpad" "wakeup: $(wakeup_of i2c-ELAN06B6:00)"
pass "resume hands wake back to the touchpad"

[[ $(wakeup_of i2c-WACF2200:00) == "disabled" ]] ||
  fail "resume leaves wake off where someone else turned it off"
pass "resume leaves wake off where someone else turned it off"

[[ ! -e $state ]] ||
  fail "resume clears the record"
pass "resume clears the record"

reset_root
printf 'state:      open\n' >"$lid"
run_hook pre suspend
[[ $(wakeup_of i2c-ELAN06B6:00) == "enabled" && ! -e $state ]] ||
  fail "an open-lid suspend leaves the touchpad able to wake the machine"
pass "an open-lid suspend leaves the touchpad able to wake the machine"

reset_root
rm -rf "$fake/proc"
run_hook pre suspend
[[ $(wakeup_of i2c-ELAN06B6:00) == "enabled" && ! -e $state ]] ||
  fail "a machine without a lid is left alone"
pass "a machine without a lid is left alone"

reset_root
run_hook post suspend
[[ $(wakeup_of i2c-WACF2200:00) == "disabled" ]] ||
  fail "a resume with no record turns nothing on"
pass "a resume with no record turns nothing on"
