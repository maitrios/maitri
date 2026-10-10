#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

hook="$ROOT/default/systemd/system-sleep/wwan-wake"

[[ -x $hook ]] ||
  fail "the WWAN wake hook is executable" "mode: $(stat -c '%A' "$hook")"
pass "the WWAN wake hook is executable"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

fake=$tmpdir/root
pci=$fake/sys/devices/pci0000:00
state=$fake/run/maitri-wwan-wake

add_pci() {
  local path=$1 class=$2 wakeup=$3
  mkdir -p "$path/power"
  printf '%s\n' "$class" >"$path/class"
  printf '%s\n' "$wakeup" >"$path/power/wakeup"
}

add_wwan() {
  local name=$1 target=$2
  mkdir -p "$fake/sys/class/wwan/$name" "$target"
  ln -s "$target" "$fake/sys/class/wwan/$name/device"
}

wakeup_of() {
  printf '%s' "$(<"$1/power/wakeup")"
}

run_hook() {
  MAITRI_SLEEP_HOOK_ROOT=$fake "$hook" "$@"
}

# The X1 Carbon: a T99W696 on its own root port. The modem has wake off; the
# port's wake is what fires.
reset_x1() {
  rm -rf "$fake"
  mkdir -p "$fake/run"
  add_pci "$pci/0000:00:1c.0" 0x060400 enabled
  mkdir -p "$pci/0000:00:1c.0/0000:00:1c.0:pcie001"
  add_pci "$pci/0000:00:1c.0/0000:08:00.0" 0x0d4000 disabled
  add_wwan wwan0 "$pci/0000:00:1c.0/0000:08:00.0/mhi0"
  add_wwan wwan0mbim0 "$pci/0000:00:1c.0/0000:08:00.0/mhi0"
  add_pci "$pci/0000:00:14.0" 0x0c0330 enabled
}

reset_x1
run_hook pre suspend
[[ $(wakeup_of "$pci/0000:00:1c.0") == "disabled" ]] ||
  fail "suspend takes wake away from the port behind the modem"
pass "suspend takes wake away from the port behind the modem"

[[ $(<"$state") == "$pci/0000:00:1c.0" ]] ||
  fail "a modem seen through several WWAN ports is recorded once, only where wake changed" "state: $(<"$state")"
pass "a modem seen through several WWAN ports is recorded once, only where wake changed"

[[ $(wakeup_of "$pci/0000:00:14.0") == "enabled" ]] ||
  fail "the USB controller keeps its wake"
pass "the USB controller keeps its wake"

run_hook post suspend
[[ $(wakeup_of "$pci/0000:00:1c.0") == "enabled" && $(wakeup_of "$pci/0000:00:1c.0/0000:08:00.0") == "disabled" ]] ||
  fail "resume hands wake back only where the hook took it"
[[ ! -e $state ]] || fail "resume clears the record"
pass "resume hands wake back only where the hook took it"

# A port shared with another device keeps its wake; the modem's own goes.
reset_x1
printf 'enabled\n' >"$pci/0000:00:1c.0/0000:08:00.0/power/wakeup"
add_pci "$pci/0000:00:1c.0/0000:09:00.0" 0x020000 enabled
run_hook pre suspend
[[ $(wakeup_of "$pci/0000:00:1c.0/0000:08:00.0") == "disabled" ]] ||
  fail "the modem's own wake goes"
[[ $(wakeup_of "$pci/0000:00:1c.0") == "enabled" ]] ||
  fail "a port shared with another device keeps its wake"
pass "a port shared with another device keeps its wake"

# A USB modem's nearest PCI device is the USB controller.
reset_x1
rm -rf "$fake/sys/class/wwan"
add_wwan wwan1 "$pci/0000:00:14.0/usb3/3-2/3-2:1.0/wwan1"
run_hook pre suspend
[[ $(wakeup_of "$pci/0000:00:14.0") == "enabled" && ! -e $state ]] ||
  fail "a USB modem leaves the USB controller alone"
pass "a USB modem leaves the USB controller alone"

# A modem straight on the root bus has no port of its own.
reset_x1
rm -rf "$fake/sys/class/wwan"
add_pci "$pci/0000:00:1d.0" 0x0d4000 enabled
add_wwan wwan0 "$pci/0000:00:1d.0/wwan0"
run_hook pre suspend
[[ $(wakeup_of "$pci/0000:00:1d.0") == "disabled" && $(<"$state") == "$pci/0000:00:1d.0" ]] ||
  fail "a modem on the root bus loses its own wake"
pass "a modem on the root bus loses its own wake"

reset_x1
rm -rf "$fake/sys/class/wwan"
run_hook pre suspend
[[ $(wakeup_of "$pci/0000:00:1c.0") == "enabled" && ! -e $state ]] ||
  fail "a machine without a modem is left alone"
pass "a machine without a modem is left alone"

reset_x1
printf '%s\n' "$tmpdir/elsewhere" >"$state"
mkdir -p "$tmpdir/elsewhere/power"
printf 'disabled\n' >"$tmpdir/elsewhere/power/wakeup"
run_hook post suspend
[[ $(<"$tmpdir/elsewhere/power/wakeup") == "disabled" ]] ||
  fail "resume only writes under sysfs devices"
pass "resume only writes under sysfs devices"
