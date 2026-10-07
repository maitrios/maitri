#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

require_command script

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

stub_bin="$test_tmp/bin"
calls="$test_tmp/calls"
mkdir -p "$stub_bin"

write_stub() {
  cat >"$stub_bin/$1" <<SH
#!/bin/bash
$2
SH
  chmod +x "$stub_bin/$1"
}

pending() {
  local list=""
  (( $# )) && list="printf '%s\\n' $*;"
  write_stub pacdiff 'if [[ $1 == "--output" ]]; then '"$list"' exit 0; fi; echo "pacdiff $*" >>"'"$calls"'"'
}

run_checker() {
  : >"$calls"
  PATH="$stub_bin:$PATH" "$ROOT/bin/maitri-update-pacnew"
}

run_in_terminal() {
  : >"$calls"
  script -qec "env PATH='$stub_bin:$PATH' ${1:-} '$ROOT/bin/maitri-update-pacnew'" /dev/null
}

write_stub sudo 'echo "sudo should not be called directly" >&2; exit 99'

pending
run_checker >"$test_tmp/none.out"
[[ ! -s $test_tmp/none.out && ! -s $calls ]] || fail "the checker stays quiet when nothing needs review"
pass "the checker stays quiet when nothing needs review"

pending /etc/pacman.conf.pacnew /etc/ssh/sshd_config.pacsave
write_stub gum 'echo "gum should not be called" >&2; exit 99'
run_checker >"$test_tmp/report.out" </dev/null
grep -qx '  /etc/pacman.conf.pacnew' "$test_tmp/report.out" || fail "the checker lists files left as .pacnew"
grep -qx '  /etc/ssh/sshd_config.pacsave' "$test_tmp/report.out" || fail "the checker lists files left as .pacsave"
grep -q 'Run maitri-update-pacnew in a terminal' "$test_tmp/report.out" || fail "the checker explains how to review later"
[[ ! -s $calls ]] || fail "the checker merges nothing without a terminal" "$(cat "$calls")"
pass "without a terminal the checker only reports"

run_in_terminal MAITRI_UPDATE_UNATTENDED=1 >"$test_tmp/unattended.out"
grep -q 'Run maitri-update-pacnew in a terminal' "$test_tmp/unattended.out" || fail "maitri update -y does not ask"
[[ ! -s $calls ]] || fail "maitri update -y merges nothing" "$(cat "$calls")"
pass "maitri update -y reports instead of asking"

write_stub gum 'exit 1'
run_in_terminal >/dev/null
[[ ! -s $calls ]] || fail "declining the review merges nothing" "$(cat "$calls")"
pass "declining the review merges nothing"

write_stub gum 'exit 0'
run_in_terminal >/dev/null
grep -qx 'pacdiff --sudo' "$calls" || fail "accepting the review merges through pacdiff --sudo" "$(cat "$calls")"
pass "accepting the review merges through pacdiff --sudo"

update="$ROOT/bin/maitri-update"
orphans_line=$(grep -n '^  maitri-update-orphan-pkgs$' "$update" | cut -d: -f1)
pacnew_line=$(grep -n '^  maitri-update-pacnew$' "$update" | cut -d: -f1)
[[ -n $orphans_line && -n $pacnew_line ]] && (( pacnew_line > orphans_line )) ||
  fail "maitri update reviews configuration files after the package steps"
pass "maitri update reviews configuration files after the package steps"
