#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

require_command jq

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

stub_bin="$test_tmp/bin"
mkdir -p "$stub_bin" "$test_tmp/run"
calls="$test_tmp/asdcontrol.log"

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
[[ $1 == "--detect" ]] && exit 0
(( $# == 1 )) && printf '%s: BRIGHTNESS=%s\n' "$1" "$MAITRI_TEST_BRIGHTNESS"
exit 0
SH

cat >"$stub_bin/sleep" <<'SH'
#!/bin/bash
SH
chmod +x "$stub_bin"/*

apple_monitors='[{"name":"eDP-1","make":"Samsung Display Corp.","model":"ATNA40HQ09-0"},{"name":"DP-1","make":"Apple Computer Inc","model":"StudioDisplay"}]'
other_monitors='[{"name":"eDP-1","make":"Samsung Display Corp.","model":"ATNA40HQ09-0"},{"name":"DP-2","make":"Dell Inc.","model":"U2723QE"}]'

reapply() {
  printf '%s\n' "$1" >"$test_tmp/monitors.json"
  : >"$calls"
  env XDG_RUNTIME_DIR="$test_tmp/run" MAITRI_TEST_MONITORS="$test_tmp/monitors.json" \
    MAITRI_TEST_CALLS="$calls" MAITRI_TEST_BRIGHTNESS="${2:-60000}" \
    PATH="$stub_bin:$ROOT/bin:$PATH" "$ROOT/bin/maitri-brightness-display-apple" --reapply
}

reapply "$other_monitors" || fail "reapply without an Apple display succeeds"
[[ ! -s $calls ]] || fail "reapply leaves other displays alone" "$(cat "$calls")"
pass "reapply does nothing, not even sudo, without an Apple display"

reapply "$apple_monitors" || fail "reapply without the display's HID device succeeds"
! grep -q -- ' -- ' "$calls" || fail "reapply sets nothing without a HID device" "$(cat "$calls")"
pass "reapply sets nothing when the display's HID device is missing"

# The set path needs a hiddev character device. A user and mount namespace can
# bind /dev/null to that path without root; the namespace's own /dev/null is a
# plain file, since device nodes there can't be opened.
if (( EUID == 0 )) || ! unshare -rm true 2>/dev/null; then
  skip "mount namespaces unavailable; skipping the reapply steps"
  exit 0
fi

steps_at() {
  unshare -rm bash -c '
    set -e
    tmp=$1 brightness=$2
    touch "$tmp/null" && mount --bind /dev/null "$tmp/null"
    mount -t tmpfs tmpfs /dev
    ln -s /proc/self/fd /dev/fd
    : >/dev/null
    mkdir -p /dev/usb && touch /dev/usb/hiddev0 && mount --bind "$tmp/null" /dev/usb/hiddev0
    printf "/dev/usb/hiddev0\n" >"$tmp/run/maitri-brightness-display-apple.device"
    : >"$tmp/asdcontrol.log"
    env XDG_RUNTIME_DIR="$tmp/run" MAITRI_TEST_MONITORS="$tmp/monitors.json" \
      MAITRI_TEST_CALLS="$tmp/asdcontrol.log" MAITRI_TEST_BRIGHTNESS="$brightness" \
      PATH="$tmp/bin:$3/bin:$PATH" "$3/bin/maitri-brightness-display-apple" --reapply
  ' _ "$test_tmp" "$1" "$ROOT"
  grep -- ' -- ' "$calls" | sed 's/^.* -- //' | paste -sd ' '
}

printf '%s\n' "$apple_monitors" >"$test_tmp/monitors.json"
[[ $(steps_at 60000) == "-1% +1%" ]] || fail "reapply steps down, then back up" "$(cat "$calls")"
pass "reapply steps one notch down and back up to the saved brightness"

[[ $(steps_at 400) == "+1% -1%" ]] || fail "reapply at the minimum steps up, then back down" "$(cat "$calls")"
pass "reapply at the minimum steps up and back down"
