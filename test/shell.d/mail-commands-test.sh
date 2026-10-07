#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

require_command jq

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

home="$TMPDIR/home"
stub_bin="$TMPDIR/bin"
calls="$TMPDIR/calls"
mkdir -p "$stub_bin"

for command in sudo hyprctl; do
  cat >"$stub_bin/$command" <<SH
#!/bin/bash
printf '$command %s\n' "\$*" >>"\$MAITRI_TEST_CALLS"
exit 1
SH
done

cat >"$stub_bin/maitri-pkg-add" <<'SH'
#!/bin/bash
printf 'pkg-add %s\n' "$*" >>"$MAITRI_TEST_CALLS"
exit "${MAITRI_TEST_PKG_STATUS:-0}"
SH

cat >"$stub_bin/maitri-pkg-drop" <<'SH'
#!/bin/bash
printf 'pkg-drop %s\n' "$*" >>"$MAITRI_TEST_CALLS"
SH

cat >"$stub_bin/maitri-shell" <<'SH'
#!/bin/bash
quiet=0
if [[ $1 == "-q" ]]; then
  quiet=1
  shift
fi
printf 'shell %s\n' "$*" >>"$MAITRI_TEST_CALLS"
if [[ ${MAITRI_TEST_SHELL_DOWN:-0} == "1" ]]; then
  (( quiet )) && exit 0
  echo "maitri-shell is not running" >&2
  exit 1
fi
case "$2" in
  listShellConfig) printf '%s\n' '{"bar":{"layout":{"center":[{"id":"maitri.clock"},{"id":"maitri.weather"},{"id":"maitri.system-update"}]}}}' ;;
  *) echo ok ;;
esac
SH

chmod +x "$stub_bin"/*

# Every path the commands can reach resolves inside the test home, and nothing
# can find the session the suite runs in.
run() {
  rm -f "$calls"
  env -u WAYLAND_DISPLAY -u HYPRLAND_INSTANCE_SIGNATURE -u DBUS_SESSION_BUS_ADDRESS \
    HOME="$home" MAITRI_PATH="$ROOT" MAITRI_TEST_CALLS="$calls" MAITRI_SHELL_ABSENT_ATTEMPTS=1 \
    XDG_CONFIG_HOME="$home/.config" XDG_CACHE_HOME="$home/.cache" \
    XDG_STATE_HOME="$home/.local/state" XDG_DATA_HOME="$home/.local/share" \
    XDG_RUNTIME_DIR="$TMPDIR/run" PATH="$stub_bin:$ROOT/bin:$PATH" "$@"
}

assert_no_escalation() {
  ! grep -q '^sudo\|^hyprctl' "$calls" || fail "$1 leaves sudo and Hyprland to the helpers it calls" "$(cat "$calls")"
}

output=$(run maitri-install-mail)
grep -qx 'pkg-add maitri-mail' "$calls" || fail "install adds the maitri-mail package" "$(cat "$calls")"
pass "install adds the maitri-mail package"

rescan=$(grep -nx 'shell shell rescanPlugins' "$calls" | cut -d: -f1)
put=$(grep -nx 'shell shell putBarWidget maitri.mail {"section":"center","index":3}' "$calls" | cut -d: -f1)
[[ -n $rescan && -n $put ]] && (( rescan < put )) ||
  fail "install rescans plugins, then puts Mail at the end of the bar's center" "$(cat "$calls")"
pass "install rescans plugins, then puts Mail at the end of the bar's center"
[[ $output == *"maitri.mail is on the bar"* ]] || fail "install reports Mail on the bar" "$output"
pass "install reports Mail on the bar"
assert_no_escalation "install"

if run env MAITRI_TEST_PKG_STATUS=1 maitri-install-mail >/dev/null 2>&1; then
  fail "install fails when the package does not install"
fi
! grep -q 'putBarWidget' "$calls" || fail "install leaves the bar alone when the package does not install"
pass "install fails without touching the bar when the package does not install"

output=$(run env MAITRI_TEST_SHELL_DOWN=1 maitri-install-mail 2>&1)
[[ $output == *"maitri.mail was not put on the bar"* ]] ||
  fail "install says so when no shell is running to put Mail on the bar" "$output"
pass "install says so when no shell is running to put Mail on the bar"

mkdir -p "$home/.config/maitri-mail" "$home/.cache/maitri-mail" "$home/.local/state/maitri-mail" "$home/.local/share/applications"
touch "$home/.config/maitri-mail/accounts.json" "$home/.local/share/applications/maitri-mail.desktop"
output=$(run maitri-remove-mail)
grep -qx 'shell shell setPluginEnabled maitri.mail false' "$calls" || fail "remove takes Mail off the bar" "$(cat "$calls")"
pass "remove takes Mail off the bar"
grep -qx 'pkg-drop maitri-mail' "$calls" || fail "remove drops the maitri-mail package" "$(cat "$calls")"
pass "remove drops the maitri-mail package"
drop=$(grep -nx 'pkg-drop maitri-mail' "$calls" | cut -d: -f1)
rescan=$(grep -nx 'shell shell rescanPlugins' "$calls" | tail -1 | cut -d: -f1)
(( rescan > drop )) || fail "remove rescans plugins after the package is gone" "$(cat "$calls")"
pass "remove rescans plugins after the package is gone"
[[ -f $home/.config/maitri-mail/accounts.json && -d $home/.cache/maitri-mail && -d $home/.local/state/maitri-mail ]] ||
  fail "remove keeps the user's mail data"
[[ $output == *"~/.config/maitri-mail"* ]] || fail "remove says where the mail data lives" "$output"
pass "remove keeps the user's mail data and says where it lives"
[[ ! -e $home/.local/share/applications/maitri-mail.desktop ]] || fail "remove drops the mailto handler that pointed into the package"
pass "remove drops the mailto handler that pointed into the package"
assert_no_escalation "remove"

output=$(run env MAITRI_TEST_SHELL_DOWN=1 maitri-remove-mail 2>&1)
grep -qx 'pkg-drop maitri-mail' "$calls" || fail "remove still drops the package without a running shell" "$output"
pass "remove still drops the package without a running shell"
