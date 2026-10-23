#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

stub_bin="$test_tmp/bin"
log="$test_tmp/refresh.log"
mkdir -p "$stub_bin"

write_stub() {
  cat >"$stub_bin/$1" <<<"$2"
  chmod +x "$stub_bin/$1"
}

write_stub sudo '#!/bin/bash
echo "sudo $*" >>"$REFRESH_TEST_LOG"'
write_stub maitri-hook '#!/bin/bash
echo "hook $*" >>"$REFRESH_TEST_LOG"'
write_stub maitri-update-pacman '#!/bin/bash
echo "update-pacman $*" >>"$REFRESH_TEST_LOG"'
write_stub maitri-channel-current '#!/bin/bash
echo "channel-current" >>"$REFRESH_TEST_LOG"
[[ ${REFRESH_TEST_CHANNEL_FAIL:-0} != "1" ]] || exit 1
echo "${REFRESH_TEST_CHANNEL:-unknown}"'

refresh() {
  : >"$log"
  MAITRI_PATH="$ROOT" REFRESH_TEST_LOG="$log" PATH="$stub_bin:$PATH" "$ROOT/bin/maitri-refresh-pacman" "$@" >"$test_tmp/output" 2>&1
}

copied() {
  grep -Fxq "sudo cp -f $ROOT/default/pacman/pacman-$1.conf /etc/pacman.conf" "$log" &&
    grep -Fxq "sudo cp -f $ROOT/default/pacman/mirrorlist-$1 /etc/pacman.d/mirrorlist" "$log"
}

for channel in stable edge dev unknown; do
  expected=$channel
  [[ $channel != "dev" ]] || expected=edge
  [[ $channel != "unknown" ]] || expected=stable
  REFRESH_TEST_CHANNEL=$channel refresh || fail "refresh on $channel completes" "$(cat "$test_tmp/output")"
  copied "$expected" || fail "refresh on $channel uses $expected" "$(cat "$log")"
  grep -Fxq "update-pacman -Syyuu --noconfirm" "$log" || fail "refresh on $channel updates" "$(cat "$log")"
done
pass "a refresh with no channel keeps stable and edge, uses edge for a dev checkout and stable when unknown"

REFRESH_TEST_CHANNEL=edge REFRESH_TEST_CHANNEL_FAIL=1 refresh stable || fail "explicit stable completes" "$(cat "$test_tmp/output")"
copied stable || fail "explicit stable overrides edge" "$(cat "$log")"
! grep -Fxq "channel-current" "$log" || fail "explicit channel skips detection" "$(cat "$log")"
pass "an explicit channel overrides the current one without querying it"

for case in failed weird; do
  if [[ $case == "failed" ]]; then
    ! REFRESH_TEST_CHANNEL_FAIL=1 refresh || fail "failed channel detection is refused"
  else
    ! REFRESH_TEST_CHANNEL=$case refresh || fail "unexpected channel is refused"
  fi
  ! grep -q '^sudo\|^update-pacman' "$log" || fail "$case channel detection changes nothing" "$(cat "$log")"
done
pass "failed or unexpected channel detection changes nothing"

! refresh rc || fail "invalid explicit channel is refused"
! grep -q '^sudo\|^update-pacman' "$log" || fail "invalid explicit channel changes nothing" "$(cat "$log")"
pass "an invalid explicit channel changes nothing"
