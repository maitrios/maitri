#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

lid_close="$ROOT/bin/maitri-system-lid-close"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# closed/docked are the two facts logind uses to decide whether a lid close
# suspends, so each scenario pins them and records what the lid handler did.
setup_scenario() {
  scenario_dir="$tmpdir/$1"
  mock_bin="$scenario_dir/bin"
  call_log="$scenario_dir/calls"
  mkdir -p "$mock_bin"
  : >"$call_log"

  local closed="$2" docked="$3"

  cat >"$mock_bin/maitri-hw-laptop-closed" <<SH
#!/bin/bash
exit $closed
SH
  cat >"$mock_bin/maitri-hw-external-monitors" <<SH
#!/bin/bash
exit $docked
SH
  cat >"$mock_bin/maitri-system-lock" <<SH
#!/bin/bash
echo maitri-system-lock >>"\$CALL_LOG"
SH
  chmod +x "$mock_bin"/*
}

run_lid_close() {
  CALL_LOG="$call_log" PATH="$mock_bin:$PATH" "$lid_close"
  mapfile -t calls <"$call_log"
}

# An undocked lid close is about to suspend, and logind's inhibitor window is a
# timer rather than a promise, so the lock has to start now instead of waiting
# for PrepareForSleep.
setup_scenario undocked 0 1
run_lid_close

[[ ${calls[*]} == "maitri-system-lock" ]] ||
  fail "undocked lid close locks the session and does nothing else" "calls: ${calls[*]}"
pass "undocked lid close locks the session and does nothing else"

# A docked lid close is clamshell mode: logind leaves the machine awake and the
# session stays in use on the external display, so locking it would be wrong.
# hyprmoncfgd turns the laptop panel off.
setup_scenario docked 0 0
run_lid_close

(( ${#calls[@]} == 0 )) ||
  fail "docked lid close leaves the session and displays alone" "calls: ${calls[*]}"
pass "docked lid close leaves the session and displays alone"

# Hyprland can replay a switch binding when the lid is already open, and an
# open lid must never lock the machine the user is sitting at.
setup_scenario open 1 1
run_lid_close

(( ${#calls[@]} == 0 )) ||
  fail "an open lid never locks the session" "calls: ${calls[*]}"
pass "an open lid never locks the session"

# The lid handler runs from a Hyprland binding, so a failing lock must not make
# the handler itself fail.
setup_scenario failing_lock 0 1
cat >"$mock_bin/maitri-system-lock" <<'SH'
#!/bin/bash
echo maitri-system-lock >>"$CALL_LOG"
exit 1
SH
chmod +x "$mock_bin/maitri-system-lock"
run_lid_close || fail "a failing lock does not fail the lid handler"
pass "a failing lock does not fail the lid handler"

grep -F '/proc/acpi/button/lid/*/state' "$ROOT/bin/maitri-hw-laptop-closed" >/dev/null ||
  fail "the lid helper reads the ACPI lid state"
pass "the lid helper reads the ACPI lid state"

utilities="$ROOT/default/hypr/bindings/utilities.lua"
grep -F 'switch:on:Lid Switch", nil, "maitri-system-lid-close"' "$utilities" >/dev/null ||
  fail "closing the lid runs the lid handler"
! grep -F 'switch:off:Lid Switch' "$utilities" >/dev/null ||
  fail "opening the lid is left to hyprmoncfgd"
pass "closing the lid locks, and hyprmoncfgd handles the displays"
