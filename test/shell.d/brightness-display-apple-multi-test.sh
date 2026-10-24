#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

require_command jq

# Hiddev nodes need real character devices, which a user and mount namespace can
# fake by bind mounting /dev/null.
if (( EUID == 0 )) || ! unshare -rm true 2>/dev/null; then
  skip "mount namespaces unavailable; skipping the two-display brightness tests"
  exit 0
fi

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

stub_bin="$test_tmp/bin"
mkdir -p "$stub_bin" "$test_tmp/run" "$test_tmp/state"

cat >"$stub_bin/sudo" <<'SH'
#!/bin/bash
exec "$@"
SH

cat >"$stub_bin/hyprctl" <<'SH'
#!/bin/bash
cat "$MAITRI_TEST_MONITORS"
SH

cat >"$stub_bin/asdcontrol" <<'SH'
#!/bin/bash
printf '%s\n' "$*" >>"$MAITRI_TEST_CALLS"
if [[ $1 == "--detect" ]]; then
  shift
  for device in "$@"; do
    printf '%s: USB Monitor - SUPPORTED.\tVendor= 0x5ac (Apple)\n' "$device"
  done
  exit 0
fi
(( $# == 1 )) && printf '%s: BRIGHTNESS=30000\n' "$1"
exit 0
SH

# Each hiddev's USB serial lives in the file next to its interface directory.
cat >"$stub_bin/readlink" <<'SH'
#!/bin/bash
if [[ $2 == /sys/class/usbmisc/*/device ]]; then
  node="${2#/sys/class/usbmisc/}"
  node="${node%/device}"
  [[ -d $MAITRI_TEST_USB/$node/interface ]] || exit 1
  printf '%s\n' "$MAITRI_TEST_USB/$node/interface"
  exit 0
fi
exec /usr/bin/readlink "$@"
SH

cat >"$stub_bin/maitri-osd" <<'SH'
#!/bin/bash
SH

cat >"$stub_bin/sleep" <<'SH'
#!/bin/bash
SH
chmod +x "$stub_bin"/*

usb="$test_tmp/usb"
for node in hiddev6:SER-A hiddev11:SER-B; do
  mkdir -p "$usb/${node%%:*}/interface"
  printf '%s\n' "${node##*:}" >"$usb/${node%%:*}/serial"
done

monitors='[{"name":"eDP-1","make":"Samsung Display Corp.","model":"ATNA40HQ09-0","serial":"1","focused":false},{"name":"DP-2","make":"Apple Computer Inc","model":"StudioDisplay","serial":"0x13A5CD6F","focused":true},{"name":"DP-3","make":"Apple Computer Inc","model":"StudioDisplay","serial":"0x6D787EF2","focused":false}]'
printf '%s\n' "$monitors" >"$test_tmp/monitors.json"
calls="$test_tmp/asdcontrol.log"
pairs="$test_tmp/state/maitri/apple-displays"

run_apple() {
  : >"$calls"
  unshare -rm bash -c '
    set -e
    tmp=$1 root=$2
    shift 2
    touch "$tmp/null" && mount --bind /dev/null "$tmp/null"
    mount -t tmpfs tmpfs /dev
    ln -s /proc/self/fd /dev/fd
    : >/dev/null
    mkdir -p /dev/usb
    for n in 6 11; do
      touch /dev/usb/hiddev$n && mount --bind "$tmp/null" /dev/usb/hiddev$n
    done
    env XDG_RUNTIME_DIR="$tmp/run" XDG_STATE_HOME="$tmp/state" MAITRI_TEST_MONITORS="$tmp/monitors.json" \
      MAITRI_TEST_CALLS="$tmp/asdcontrol.log" MAITRI_TEST_USB="$tmp/usb" \
      PATH="$tmp/bin:$root/bin:$PATH" "$root/bin/maitri-brightness-display-apple" "$@"
  ' _ "$test_tmp" "$ROOT" "$@"
}

sets() {
  grep -- ' -- ' "$calls" | paste -sd ';' || true
}

# --- Two displays with no pairing: refuse instead of dimming the wrong one -----
status=0
output=$(run_apple --no-osd 50% 2>&1) || status=$?
(( status != 0 )) || fail "an unpaired second display is refused"
[[ -z $(sets) ]] || fail "nothing is set while the displays can't be told apart" "$(sets)"
[[ $output == *"--pair"* ]] || fail "the refusal points at --pair" "$output"
pass "two unpaired displays are refused with a hint to pair them"

# --- --monitor picks that monitor's own device -------------------------------
mkdir -p "${pairs%/*}"
printf '0x13A5CD6F SER-A\n0x6D787EF2 SER-B\n' >"$pairs"

run_apple --no-osd --monitor DP-2 50% >/dev/null
[[ $(sets) == "/dev/usb/hiddev6 -- 50%" ]] || fail "--monitor DP-2 sets only its own display" "$(sets)"
run_apple --no-osd --monitor DP-3 80% >/dev/null
[[ $(sets) == "/dev/usb/hiddev11 -- 80%" ]] || fail "--monitor DP-3 sets only its own display" "$(sets)"
pass "--monitor sets the display paired to that monitor"

# --- Reading goes to the same device -----------------------------------------
run_apple --monitor DP-3 >/dev/null
grep -qx '/dev/usb/hiddev11' "$calls" || fail "reading DP-3 reads its own display" "$(cat "$calls")"
! grep -qx '/dev/usb/hiddev6' "$calls" || fail "reading DP-3 leaves DP-2's display alone" "$(cat "$calls")"
pass "reading brightness uses the monitor's own display"

# --- With no --monitor the focused display is targeted -----------------------
run_apple --no-osd 20% >/dev/null
[[ $(sets) == "/dev/usb/hiddev6 -- 20%" ]] || fail "the focused display is the default target" "$(sets)"
pass "without --monitor the focused display is targeted"

# --- The runtime cache keeps one entry per display ---------------------------
[[ $(wc -l <"$test_tmp/run/maitri-brightness-display-apple.devices") == 2 ]] ||
  fail "the device cache holds both displays" "$(cat "$test_tmp/run/maitri-brightness-display-apple.devices")"
pass "the device cache keeps one entry per display"

# --- Reapply fixes every connected display, or just the named one ------------
run_apple --reapply >/dev/null
[[ $(sets) == "/dev/usb/hiddev6 -- -1%;/dev/usb/hiddev6 -- +1%;/dev/usb/hiddev11 -- -1%;/dev/usb/hiddev11 -- +1%" ]] ||
  fail "reapply steps each display away and back" "$(sets)"
run_apple --reapply --monitor DP-3 >/dev/null
[[ $(sets) == "/dev/usb/hiddev11 -- -1%;/dev/usb/hiddev11 -- +1%" ]] ||
  fail "reapply with --monitor touches only that display" "$(sets)"
pass "reapply covers every connected display"

# --- A display paired already leaves the other one its device ----------------
printf '0x13A5CD6F SER-A\n' >"$pairs"
run_apple --no-osd --monitor DP-3 40% >/dev/null
[[ $(sets) == "/dev/usb/hiddev11 -- 40%" ]] || fail "the unclaimed display goes to the unpaired monitor" "$(sets)"
grep -qx '0x6D787EF2 SER-B' "$pairs" || fail "the inferred pairing is stored" "$(cat "$pairs")"
pass "the remaining display is paired to the remaining monitor"

# --- A replugged display renumbers its hiddev; the pairing follows the serial -
rm -rf "$usb/hiddev6" "$usb/hiddev7"
mkdir -p "$usb/hiddev7/interface"
printf 'SER-A\n' >"$usb/hiddev7/serial"
rm -f "$test_tmp/run/maitri-brightness-display-apple.devices"
unshare -rm bash -c '
  set -e
  tmp=$1 root=$2
  touch "$tmp/null" && mount --bind /dev/null "$tmp/null"
  mount -t tmpfs tmpfs /dev
  ln -s /proc/self/fd /dev/fd
  : >/dev/null
  mkdir -p /dev/usb
  for n in 7 11; do
    touch /dev/usb/hiddev$n && mount --bind "$tmp/null" /dev/usb/hiddev$n
  done
  : >"$tmp/asdcontrol.log"
  env XDG_RUNTIME_DIR="$tmp/run" XDG_STATE_HOME="$tmp/state" MAITRI_TEST_MONITORS="$tmp/monitors.json" \
    MAITRI_TEST_CALLS="$tmp/asdcontrol.log" MAITRI_TEST_USB="$tmp/usb" \
    PATH="$tmp/bin:$root/bin:$PATH" "$root/bin/maitri-brightness-display-apple" --no-osd --monitor DP-2 60%
' _ "$test_tmp" "$ROOT" >/dev/null
[[ $(sets) == "/dev/usb/hiddev7 -- 60%" ]] || fail "a renumbered display is found by its USB serial" "$(sets)"
pass "a renumbered hiddev still maps to its monitor by USB serial"

# --- One display needs no pairing --------------------------------------------
printf '%s\n' '[{"name":"DP-2","make":"Apple Computer Inc","model":"StudioDisplay","serial":"0x13A5CD6F","focused":true}]' >"$test_tmp/monitors.json"
rm -rf "$usb/hiddev11" "$test_tmp/state/maitri"
rm -f "$test_tmp/run/maitri-brightness-display-apple.devices"
unshare -rm bash -c '
  set -e
  tmp=$1 root=$2
  touch "$tmp/null" && mount --bind /dev/null "$tmp/null"
  mount -t tmpfs tmpfs /dev
  ln -s /proc/self/fd /dev/fd
  : >/dev/null
  mkdir -p /dev/usb
  touch /dev/usb/hiddev7 && mount --bind "$tmp/null" /dev/usb/hiddev7
  : >"$tmp/asdcontrol.log"
  env XDG_RUNTIME_DIR="$tmp/run" XDG_STATE_HOME="$tmp/state" MAITRI_TEST_MONITORS="$tmp/monitors.json" \
    MAITRI_TEST_CALLS="$tmp/asdcontrol.log" MAITRI_TEST_USB="$tmp/usb" \
    PATH="$tmp/bin:$root/bin:$PATH" "$root/bin/maitri-brightness-display-apple" --no-osd 70%
' _ "$test_tmp" "$ROOT" >/dev/null
[[ $(sets) == "/dev/usb/hiddev7 -- 70%" ]] || fail "a lone display works without pairing" "$(sets)"
pass "a single display needs no pairing"
