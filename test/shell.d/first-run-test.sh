#!/bin/bash

source "$(dirname "$0")/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

mock_bin="$test_tmp/bin"
mkdir -p "$mock_bin" "$test_tmp/home"

cat >"$mock_bin/maitri-done" <<'SH'
#!/bin/bash
[[ $1 == "check" && $2 == "first-run-user" ]]
SH
cat >"$mock_bin/maitri-provision-user" <<'SH'
#!/bin/bash
touch "$MAITRI_TEST_FINALIZE_CALLED"
SH
chmod +x "$mock_bin/maitri-done" "$mock_bin/maitri-provision-user"

finalize_called="$test_tmp/finalize-called"
HOME="$test_tmp/home" PATH="$mock_bin:$PATH" MAITRI_TEST_FINALIZE_CALLED="$finalize_called" \
  bash "$ROOT/bin/maitri-provision-first-run" >"$test_tmp/output"

[[ ! -e $finalize_called ]] || fail "completed first-run exits before any setup step"
grep -F 'First-run already complete' "$test_tmp/output" >/dev/null || fail "completed first-run reports its lifecycle gate"

if grep -F 'user-migration-notify-watch-enabled' "$ROOT/bin/maitri-provision-first-run" >/dev/null; then
  fail "first-run does not track the migration watcher separately"
fi
if grep -F 'skip-first-run-update-notification' "$ROOT/install/user/first-run/wifi.sh" >/dev/null; then
  fail "first-run does not track update notifications separately"
fi

pass "first-run uses one lifecycle completion marker"

# First run offers an update only when there is one. A fresh install from
# current media is already current, and a critical toast that leads to
# "nothing to do" teaches people to dismiss the next one.
cat >"$mock_bin/nm-online" <<'SH'
#!/bin/bash
exit 0
SH
# Like the real one, it looks for maitri's package with checkupdates.
cat >"$mock_bin/maitri-update-available" <<'SH'
#!/bin/bash
checkupdates >/dev/null
exit "$MAITRI_TEST_MAITRI_UPDATE"
SH
cat >"$mock_bin/checkupdates" <<'SH'
#!/bin/bash
echo checkupdates >>"$MAITRI_TEST_CALLS"
exit "$MAITRI_TEST_CHECKUPDATES"
SH
cat >"$mock_bin/maitri-notification-send" <<'SH'
#!/bin/bash
printf '%s\n' "$*" >>"$MAITRI_TEST_CALLS"
SH
chmod +x "$mock_bin/nm-online" "$mock_bin/maitri-update-available" \
  "$mock_bin/checkupdates" "$mock_bin/maitri-notification-send"

# Arguments: MAITRI_PATH, maitri-update-available's exit status, then
# checkupdates'.
offers_update() {
  : >"$test_tmp/calls"
  MAITRI_PATH="$1" PATH="$mock_bin:$PATH" MAITRI_TEST_CALLS="$test_tmp/calls" \
    MAITRI_TEST_MAITRI_UPDATE="$2" MAITRI_TEST_CHECKUPDATES="$3" \
    bash -c 'source "$1"; wait' _ "$ROOT/install/user/first-run/wifi.sh"
  grep -Fq 'Update System' "$test_tmp/calls"
}

installed=/usr/share/maitri
checkout="$test_tmp/maitri-checkout"

if offers_update "$installed" 1 2; then
  fail "first run offers no update when nothing is pending"
fi
[[ $(grep -c '^checkupdates$' "$test_tmp/calls") == 1 ]] ||
  fail "first run syncs the package databases once"
offers_update "$installed" 1 0 || fail "first run offers an update when packages are pending"
offers_update "$installed" 1 1 || fail "first run offers an update when it cannot tell whether one is pending"
offers_update "$checkout" 0 2 || fail "first run offers an update when a development checkout is behind"
if offers_update "$checkout" 1 2; then
  fail "first run offers no update when a current checkout has nothing pending"
fi
pass "first run offers an update only when there is one"
