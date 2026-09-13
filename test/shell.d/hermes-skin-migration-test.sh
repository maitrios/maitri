#!/bin/bash

set -euo pipefail

# The migration hands an existing Hermes Desktop install the maitri skin. It
# is exercised here with the package probe and the skin hook stubbed, so a
# migration that reached a Hermes maitri did not install, or that marked a
# failed hand-over done, shows up in what it ran.

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

migration="$ROOT/migrations/1788619462.sh"
[[ -f $migration ]] || fail "Hermes skin migration exists"
[[ $(stat -c %a "$migration") == "644" ]] || fail "migration is a plain 0644 file"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

mock_bin="$test_tmp/bin"
calls="$test_tmp/calls"
mkdir -p "$mock_bin"

cat >"$mock_bin/maitri-pkg-present" <<'SH'
#!/bin/bash
[[ $1 == "hermes-desktop" && ${MAITRI_TEST_DESKTOP_INSTALLED:-0} == 1 ]]
SH

cat >"$mock_bin/maitri-theme-set-hermes" <<'SH'
#!/bin/bash
echo "maitri-theme-set-hermes $*" >>"$MAITRI_TEST_CALLS"
[[ ${MAITRI_TEST_HOOK_FAILS:-0} == 0 ]]
SH

chmod +x "$mock_bin"/*

run_migration() {
  : >"$calls"
  MAITRI_TEST_DESKTOP_INSTALLED="${MAITRI_TEST_DESKTOP_INSTALLED:-1}" \
    MAITRI_TEST_HOOK_FAILS="${MAITRI_TEST_HOOK_FAILS:-0}" \
    MAITRI_TEST_CALLS="$calls" \
    PATH="$mock_bin:$PATH" \
    HOME="$test_tmp/home" \
    MAITRI_PATH="$ROOT" \
    bash -euo pipefail "$migration" >/dev/null
}

MAITRI_TEST_DESKTOP_INSTALLED=0 run_migration || fail "migration exits clean without Hermes Desktop"
[[ ! -s $calls ]] || fail "a machine without Hermes Desktop is left alone" "$(cat "$calls")"
pass "migration only applies where maitri installed Hermes Desktop"

run_migration || fail "migration exits clean with Hermes Desktop installed"
[[ $(cat "$calls") == "maitri-theme-set-hermes --activate" ]] ||
  fail "the skin is rendered, published and activated through the hook's deliberate form" "$(cat "$calls")"
pass "migration hands the skin over through the hook"

if MAITRI_TEST_HOOK_FAILS=1 run_migration; then
  fail "a hand-over that failed on maitri's side stays pending"
fi
pass "migration stays pending when the hand-over fails"
