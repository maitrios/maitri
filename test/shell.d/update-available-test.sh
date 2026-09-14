#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

stub_bin="$test_tmp/bin"
git_log="$test_tmp/git.log"
mkdir -p "$stub_bin"

cat >"$stub_bin/checkupdates" <<'SH'
#!/bin/bash
case "${TEST_CHECKUPDATES:-updates}" in
  updates)
    printf 'linux 6.1-1 -> 6.1-2\nmaitri 4.0.0-1 -> 4.0.1-1\nmaitri-settings 4.0.0-1 -> 4.0.1-1\nmaitri-dev 4.1.0-1 -> 4.1.1-1\nmaitri-settings-dev 4.1.0-1 -> 4.1.1-1\n'
    exit 0
    ;;
  none)
    exit 2
    ;;
  fail)
    echo "check failed" >&2
    exit 1
    ;;
esac
SH
chmod +x "$stub_bin/checkupdates"

cat >"$stub_bin/pacman" <<'SH'
#!/bin/bash
case "$1" in
  -Qq)
    case "${TEST_INSTALLED_PACKAGE:-maitri}" in
      maitri)
        [[ $2 == "maitri" ]]; exit $?
        ;;
      maitri-dev)
        [[ $2 == "maitri-dev" ]]; exit $?
        ;;
      both)
        [[ $2 == "maitri" || $2 == "maitri-dev" ]]; exit $?
        ;;
      none)
        exit 1
        ;;
    esac
    ;;
esac
exit 0
SH
chmod +x "$stub_bin/pacman"

cat >"$stub_bin/git" <<'SH'
#!/bin/bash

printf '%s\n' "$*" >>"$TEST_GIT_LOG"

[[ $1 == "-C" ]] || exit 1
shift 2

case "$1" in
  fetch)
    [[ ${TEST_GIT_FETCH:-ok} == "ok" ]]
    ;;
  rev-parse)
    case "$2" in
      --is-inside-work-tree)
        [[ ${TEST_GIT_CHECKOUT:-yes} == "yes" ]] || exit 1
        echo true
        ;;
      --abbrev-ref)
        [[ ${TEST_GIT_UPSTREAM:-origin/main} != "none" ]] || exit 1
        echo "${TEST_GIT_UPSTREAM:-origin/main}"
        ;;
      *)
        exit 1
        ;;
    esac
    ;;
  rev-list)
    echo "${TEST_GIT_BEHIND:-0}"
    ;;
  *)
    exit 1
    ;;
esac
SH
chmod +x "$stub_bin/git"

run_checker() {
  MAITRI_PATH="${TEST_MAITRI_PATH:-/usr/share/maitri}" \
    TEST_GIT_LOG="$git_log" \
    PATH="$stub_bin:$PATH" \
    "$ROOT/bin/maitri-update-available"
}

capture_checker() {
  local stdout_file="$1"
  local stderr_file="$2"
  shift 2

  set +e
  (
    export "$@"
    run_checker
  ) >"$stdout_file" 2>"$stderr_file"
  local status=$?
  set -e
  return "$status"
}

stdout="$test_tmp/stdout"
stderr="$test_tmp/stderr"

if capture_checker "$stdout" "$stderr" TEST_CHECKUPDATES=updates TEST_INSTALLED_PACKAGE=maitri; then
  status=0
else
  status=$?
fi
[[ $status -eq 0 ]] || fail "update checker exits successfully when maitri update is available"
grep -q '^maitri ' "$stdout" || fail "update checker prints maitri updates"
! grep -q '^maitri-settings ' "$stdout" || fail "update checker ignores maitri-settings updates"
! grep -q '^linux ' "$stdout" || fail "update checker ignores non-maitri package updates"
! grep -q '^maitri-dev ' "$stdout" || fail "update checker ignores maitri-dev when maitri is installed"
pass "update checker detects installed maitri package updates"

if capture_checker "$stdout" "$stderr" TEST_CHECKUPDATES=updates TEST_INSTALLED_PACKAGE=maitri-dev; then
  status=0
else
  status=$?
fi
[[ $status -eq 0 ]] || fail "update checker exits successfully when maitri-dev update is available"
grep -q '^maitri-dev ' "$stdout" || fail "update checker prints maitri-dev updates"
! grep -q '^maitri-settings-dev ' "$stdout" || fail "update checker ignores maitri-settings-dev updates"
! grep -q '^maitri ' "$stdout" || fail "update checker ignores maitri when maitri-dev is installed"
pass "update checker detects installed maitri-dev package updates"

if capture_checker "$stdout" "$stderr" TEST_CHECKUPDATES=updates TEST_INSTALLED_PACKAGE=both; then
  status=0
else
  status=$?
fi
[[ $status -eq 0 ]] || fail "update checker prefers maitri-dev when both packages are installed"
grep -q '^maitri-dev ' "$stdout" || fail "update checker prints maitri-dev when both packages are installed"
! grep -q '^maitri ' "$stdout" || fail "update checker ignores maitri when maitri-dev is installed"
pass "update checker prefers maitri-dev over maitri"

if capture_checker "$stdout" "$stderr" TEST_CHECKUPDATES=updates TEST_INSTALLED_PACKAGE=none; then
  status=0
else
  status=$?
fi
[[ $status -eq 1 ]] || fail "update checker exits non-zero when no maitri package is installed"
[[ ! -s $stderr ]] || fail "update checker is quiet when no maitri package is installed"
pass "update checker ignores systems without maitri or maitri-dev installed"

if capture_checker "$stdout" "$stderr" TEST_CHECKUPDATES=none TEST_INSTALLED_PACKAGE=maitri; then
  status=0
else
  status=$?
fi
[[ $status -eq 1 ]] || fail "update checker exits non-zero when no updates are available"
grep -q '^maitri is up to date$' "$stdout" || fail "update checker prints up-to-date message"
pass "update checker reports up-to-date maitri packages"

: >"$git_log"
if capture_checker "$stdout" "$stderr" \
  TEST_CHECKUPDATES=none \
  TEST_INSTALLED_PACKAGE=none \
  TEST_MAITRI_PATH="$test_tmp/checkout" \
  TEST_GIT_BEHIND=2; then
  status=0
else
  status=$?
fi
[[ $status -eq 0 ]] || fail "update checker exits successfully when dev commits are available"
grep -Fx 'maitri-dev-checkout 2 new commits on origin/main' "$stdout" >/dev/null ||
  fail "update checker reports available dev commits" "$(cat "$stdout")"
grep -Fx -- "-C $test_tmp/checkout fetch --quiet" "$git_log" >/dev/null ||
  fail "update checker fetches the dev checkout upstream" "$(cat "$git_log")"
pass "update checker detects new commits in the dev checkout"

if capture_checker "$stdout" "$stderr" \
  TEST_CHECKUPDATES=none \
  TEST_INSTALLED_PACKAGE=none \
  TEST_MAITRI_PATH="$test_tmp/checkout" \
  TEST_GIT_BEHIND=0; then
  status=0
else
  status=$?
fi
[[ $status -eq 1 ]] || fail "update checker exits non-zero when the dev checkout is current"
grep -q '^maitri is up to date$' "$stdout" || fail "update checker reports a current dev checkout"
pass "update checker ignores a current dev checkout"

if capture_checker "$stdout" "$stderr" \
  TEST_CHECKUPDATES=none \
  TEST_INSTALLED_PACKAGE=none \
  TEST_MAITRI_PATH="$test_tmp/checkout" \
  TEST_GIT_BEHIND=1 \
  TEST_GIT_FETCH=fail; then
  status=0
else
  status=$?
fi
[[ $status -eq 0 ]] || fail "update checker uses cached upstream state when fetch fails"
grep -Fx 'maitri-dev-checkout 1 new commit on origin/main' "$stdout" >/dev/null ||
  fail "update checker reports cached dev commits after a fetch failure" "$(cat "$stdout")"
[[ ! -s $stderr ]] || fail "update checker keeps dev fetch failures quiet" "$(cat "$stderr")"
pass "update checker uses cached dev state when fetching is unavailable"
