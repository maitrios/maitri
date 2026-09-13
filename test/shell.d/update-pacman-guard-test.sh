#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

run_guard() {
  MAITRI_PACMAN_CMDLINE="$1" "$ROOT/bin/maitri-update-pacman-guard"
}

if run_guard "pacman -Syu --noconfirm" >"$test_tmp/direct.out" 2>"$test_tmp/direct.err"; then
  fail "pacman guard blocks direct system upgrades"
fi
grep -q 'maitri update' "$test_tmp/direct.err" || fail "pacman guard explains maitri update entrypoint"
pass "pacman guard blocks direct pacman -Syu"

if run_guard "pacman --sync --refresh --sysupgrade" >"$test_tmp/long.out" 2>"$test_tmp/long.err"; then
  fail "pacman guard blocks long-form system upgrades"
fi
pass "pacman guard blocks long-form pacman sysupgrade"

MAITRI_UPDATE_PACMAN=1 run_guard "pacman -Syu --noconfirm" >"$test_tmp/maitri.out" 2>"$test_tmp/maitri.err"
[[ ! -s $test_tmp/maitri.err ]] || fail "pacman guard stays quiet for maitri update pacman call"
pass "pacman guard allows maitri update pacman call"

MAITRI_ALLOW_DIRECT_PACMAN=1 run_guard "pacman -Syu --noconfirm" >"$test_tmp/override.out" 2>"$test_tmp/override.err"
[[ ! -s $test_tmp/override.err ]] || fail "pacman guard stays quiet for explicit direct pacman override"
pass "pacman guard allows explicit direct pacman override"

run_guard "pacman -S firefox" >"$test_tmp/install.out" 2>"$test_tmp/install.err"
[[ ! -s $test_tmp/install.err ]] || fail "pacman guard stays quiet for non-sysupgrade pacman command"
pass "pacman guard ignores non-system-upgrade transactions"
