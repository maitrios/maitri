#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

require_command jq

migration="$ROOT/migrations/1791368110.sh"
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

home="$test_dir/home"
stub_bin="$test_dir/bin"
calls="$test_dir/calls"
mailto="$test_dir/mailto"
pgrep_count="$test_dir/pgrep-count"
output="$test_dir/output"
shell_json="$home/.config/maitri/shell.json"
bindings="$home/.config/hypr/bindings.lua"
plugin="$home/.config/maitri/plugins/omamail"
backups="$home/.local/state/maitri/backups"
applications="$home/.local/share/applications"
mkdir -p "$stub_bin"

cat >"$stub_bin/sudo" <<'SH'
#!/bin/bash
printf 'sudo %s\n' "$*" >>"$MAITRI_TEST_CALLS"
exit 1
SH

cat >"$stub_bin/maitri-pkg-add" <<'SH'
#!/bin/bash
printf 'pkg-add %s\n' "$*" >>"$MAITRI_TEST_CALLS"
exit "${MAITRI_TEST_PKG_STATUS:-0}"
SH

cat >"$stub_bin/maitri-shell" <<'SH'
#!/bin/bash
printf 'maitri-shell %s\n' "$*" >>"$MAITRI_TEST_CALLS"
SH

cat >"$stub_bin/xdg-mime" <<'SH'
#!/bin/bash
case "$1 $2" in
  "query default") cat "$MAITRI_TEST_MAILTO" 2>/dev/null ;;
  "default "*)
    printf 'xdg-mime %s\n' "$*" >>"$MAITRI_TEST_CALLS"
    printf '%s\n' "$2" >"$MAITRI_TEST_MAILTO"
    ;;
esac
SH

# Answers "running" for the first MAITRI_TEST_OMAMAIL_RUNNING polls. Never the
# host's pgrep: the machine running this suite may well have a real omamail up.
cat >"$stub_bin/pgrep" <<'SH'
#!/bin/bash
[[ $* == "-u $UID -x omamail" ]] || exit 2
count=$(( $(cat "$MAITRI_TEST_PGREP_COUNT" 2>/dev/null || echo 0) + 1 ))
echo "$count" >"$MAITRI_TEST_PGREP_COUNT"
(( count <= ${MAITRI_TEST_OMAMAIL_RUNNING:-0} ))
SH

cat >"$stub_bin/hyprctl" <<'SH'
#!/bin/bash
printf 'hyprctl %s\n' "$*" >>"$MAITRI_TEST_CALLS"
SH

chmod +x "$stub_bin"/*

reset_home() {
  rm -rf "$home" "$calls" "$mailto" "$pgrep_count"
  mkdir -p "$home"
}

# Every path the migration can reach resolves inside the test home, and nothing
# can find the session it runs in.
run_migration() {
  env -u WAYLAND_DISPLAY -u HYPRLAND_INSTANCE_SIGNATURE -u DBUS_SESSION_BUS_ADDRESS \
    HOME="$home" MAITRI_PATH="$ROOT" PATH="$stub_bin:$ROOT/bin:$PATH" \
    XDG_CONFIG_HOME="$home/.config" XDG_CACHE_HOME="$home/.cache" \
    XDG_STATE_HOME="$home/.local/state" XDG_DATA_HOME="$home/.local/share" \
    XDG_RUNTIME_DIR="$test_dir/run" \
    MAITRI_TEST_CALLS="$calls" MAITRI_TEST_MAILTO="$mailto" MAITRI_TEST_PGREP_COUNT="$pgrep_count" \
    MAITRI_OMAMAIL_STOP_ATTEMPTS=5 bash -euo pipefail "$migration" >"$output" 2>&1
}

write_shell_json() {
  mkdir -p "$(dirname "$shell_json")"
  printf '%s\n' "$1" >"$shell_json"
  chmod 0600 "$shell_json"
}

# The stock bar from before Mail joined it.
stock_shell_json() {
  jq '.bar.layout.center |= map(select(.id != "maitri.mail"))' "$ROOT/config/maitri/shell.json"
}

# Andrew's setup: omamail last in the center section, carrying its settings.
andrews_shell_json() {
  stock_shell_json | jq '.bar.layout.center = [
    {id: "maitri.keyboard-layout"}, {id: "maitri.indicators"}, {id: "maitri.weather"},
    {id: "maitri.system-update"}, {id: "maitri.clock", format: "dddd HH:mm"}, {id: "maitri.agents"},
    {id: "omamail", notifyNewMail: "Off", unifiedMailboxes: true}
  ]'
}

write_omamail_plugin() {
  mkdir -p "$plugin/.git"
  echo "ref: refs/heads/main" >"$plugin/.git/HEAD"
  printf '{"schemaVersion": 1, "id": "omamail", "name": "Omamail"}\n' >"$plugin/manifest.json"
}

write_omamail_data() {
  mkdir -p "$home/.config/omamail" "$home/.cache/omamail" "$home/.local/state/omamail/drafts" "$applications"
  echo '{"accounts": ["me@example.com"]}' >"$home/.config/omamail/accounts.json"
  echo "cached mail" >"$home/.cache/omamail/mail.db"
  echo "draft" >"$home/.local/state/omamail/drafts/1.eml"
  printf '[Desktop Entry]\nExec=omamail\n' >"$applications/omamail.desktop"
  echo "omamail.desktop" >"$mailto"
}

# The block omamail's "Set as default" wrote, calling the given shell command.
omamail_bindings_block() {
  cat <<LUA
-- >>> omamail default mail client, do not edit by hand
hl.unbind("SUPER + SHIFT + E")
hl.unbind("SUPER + SHIFT + ALT + E")
o.bind("SUPER + SHIFT + E", "Email", "$1 shell summon omamail '{}'")
o.bind("SUPER + SHIFT + ALT + E", "New email", "$1 shell summon omamail '{\"compose\":true}'")
-- <<< omamail default mail client
LUA
}

mail_bindings_block() {
  cat <<'LUA'
-- >>> maitri-mail default mail client, do not edit by hand
hl.unbind("SUPER + SHIFT + E")
hl.unbind("SUPER + SHIFT + ALT + E")
o.bind("SUPER + SHIFT + E", "Email", "maitri-shell shell summon maitri.mail '{}'")
o.bind("SUPER + SHIFT + ALT + E", "New email", "maitri-shell shell summon maitri.mail '{\"compose\":true}'")
-- <<< maitri-mail default mail client
LUA
}

# Andrew's own bindings around a managed block, written to $1.
write_bindings() {
  mkdir -p "$(dirname "$1")"
  {
    printf '%s\n' 'o.bind("SUPER + RETURN", "Terminal", "uwsm-app -- xdg-terminal-exec")' ''
    printf '%s\n' "$2"
    printf '%s\n' '' '-- my keys' 'o.bind("SUPER + B", "Browser", "maitri-launch-browser")'
  } >"$1"
  chmod 0600 "$1"
}

center_ids() {
  jq -c '[.bar.layout.center[] | .id // .]' "$shell_json"
}

assert_no_sudo() {
  ! grep -q '^sudo' "$calls" 2>/dev/null || fail "$1 never calls sudo itself" "$(cat "$calls")"
}

# --- A machine that never had omamail -------------------------------------

reset_home
run_migration || fail "a machine without shell.json migrates" "$(cat "$output")"
grep -qx 'pkg-add maitri-mail' "$calls" || fail "the migration installs maitri-mail" "$(cat "$calls")"
[[ ! -e $shell_json ]] || fail "a machine on the default bar keeps no shell.json of its own"
! grep -q '^xdg-mime' "$calls" || fail "a machine without omamail keeps its mailto handler"
[[ ! -e $backups ]] || fail "a machine without omamail retires nothing"
assert_no_sudo "the migration"
pass "a machine on the default bar gets the package and nothing else"

reset_home
write_shell_json "$(stock_shell_json)"
expected=$(jq -c '.bar.layout.center += [{id: "maitri.mail"}]' "$shell_json")
run_migration || fail "a stock bar migrates" "$(cat "$output")"
[[ $(jq -c . "$shell_json") == "$expected" ]] ||
  fail "a stock bar gains Mail at the end of its center section and nothing else" "$(cat "$shell_json")"
[[ $(stat -c %a "$shell_json") == 600 ]] || fail "the migration keeps shell.json's mode"
pass "a stock bar gains Mail at the end of its center section, keeping the file's mode"

reset_home
mkdir -p "$home/dotfiles" "$(dirname "$shell_json")"
stock_shell_json >"$home/dotfiles/shell.json"
ln -s "$home/dotfiles/shell.json" "$shell_json"
run_migration || fail "a linked shell.json migrates" "$(cat "$output")"
[[ -L $shell_json ]] || fail "a linked shell.json stays a link"
jq -e '.bar.layout.center[-1].id == "maitri.mail"' "$home/dotfiles/shell.json" >/dev/null ||
  fail "a linked shell.json is edited where it lives"
pass "a shell.json linked in from dotfiles is edited in place and stays linked"

# --- Andrew's omamail setup ------------------------------------------------

reset_home
write_shell_json "$(andrews_shell_json)"
write_omamail_plugin
write_omamail_data
write_bindings "$bindings" "$(omamail_bindings_block omarchy-shell)"  # rebrand:keep
write_bindings "$test_dir/expected-bindings" "$(mail_bindings_block)"
MAITRI_TEST_OMAMAIL_RUNNING=2 run_migration || fail "an omamail setup migrates" "$(cat "$output")"

[[ $(center_ids) == '["maitri.keyboard-layout","maitri.indicators","maitri.weather","maitri.system-update","maitri.clock","maitri.agents","maitri.mail"]' ]] ||
  fail "omamail's bar entry becomes Mail's in the same place" "$(center_ids)"
[[ $(jq -c '.bar.layout.center[-1]' "$shell_json") == '{"id":"maitri.mail","notifyNewMail":"Off","unifiedMailboxes":true}' ]] ||
  fail "Mail's bar entry keeps omamail's settings" "$(jq -c '.bar.layout.center[-1]' "$shell_json")"
! grep -q omamail "$shell_json" || fail "no omamail entry is left in shell.json"
[[ $(stat -c %a "$shell_json") == 600 ]] || fail "the rename keeps shell.json's mode"
pass "omamail's bar entry becomes Mail's in place, settings and file mode kept"

grep -qx 'maitri-shell -q shell reloadConfig' "$calls" || fail "the migration asks the shell to reload the renamed config"
(( $(cat "$pgrep_count") == 3 )) || fail "the migration waits for omamail's backend to stop" "polled $(cat "$pgrep_count") times"
pass "the migration has the shell reload, then waits for omamail's backend to stop"

[[ $(cat "$home/.config/maitri-mail/accounts.json") == '{"accounts": ["me@example.com"]}' &&
  $(cat "$home/.cache/maitri-mail/mail.db") == "cached mail" &&
  $(cat "$home/.local/state/maitri-mail/drafts/1.eml") == "draft" ]] ||
  fail "omamail's config, cache and state move to the maitri-mail names"
[[ ! -e $home/.config/omamail && ! -e $home/.cache/omamail && ! -e $home/.local/state/omamail ]] ||
  fail "no omamail data directory is left behind"
pass "omamail's config, cache and state move to the maitri-mail names"

[[ ! -e $plugin ]] || fail "the omamail plugin is retired"
retired=("$backups"/omamail-plugin-*)
(( ${#retired[@]} == 1 )) && [[ -f ${retired[0]}/.git/HEAD && -f ${retired[0]}/manifest.json ]] ||
  fail "the omamail checkout is kept whole in a dated backup" "$(ls -la "$backups" 2>&1)"
pass "the omamail checkout moves whole to a dated backup under ~/.local/state/maitri"

[[ ! -e $applications/omamail.desktop ]] || fail "omamail's launcher is removed"
[[ $(cat "$mailto") == "maitri-mail.desktop" ]] || fail "mailto moves from omamail to Mail" "$(cat "$mailto")"
assert_no_sudo "the omamail migration"
pass "omamail's launcher goes and mailto points at Mail"

cmp -s "$bindings" "$test_dir/expected-bindings" ||
  fail "omamail's keybinding block becomes Mail's, and nothing else in bindings.lua changes" \
    "$(diff "$test_dir/expected-bindings" "$bindings")"
[[ $(stat -c %a "$bindings") == 600 ]] || fail "the rewrite keeps bindings.lua's mode"
grep -q "next login" "$output" || fail "the migration says when Hyprland picks up the keys" "$(cat "$output")"
! grep -q '^hyprctl' "$calls" || fail "the migration leaves Hyprland to reload at the next login"
pass "omamail's keybinding block becomes Mail's between its markers, the rest of bindings.lua byte for byte"

cp "$shell_json" "$test_dir/shell-before"
cp "$bindings" "$test_dir/bindings-before"
rm -f "$calls"
run_migration || fail "the migration re-runs cleanly" "$(cat "$output")"
cmp -s "$shell_json" "$test_dir/shell-before" || fail "a re-run leaves shell.json byte for byte"
cmp -s "$bindings" "$test_dir/bindings-before" || fail "a re-run leaves bindings.lua byte for byte"
! grep -q "keybindings\|SUPER+SHIFT+E" "$output" || fail "a re-run has nothing to say about the keys" "$(cat "$output")"
! grep -q '^xdg-mime' "$calls" || fail "a re-run leaves the mailto handler alone"
retired=("$backups"/omamail-plugin-*)
(( ${#retired[@]} == 1 )) || fail "a re-run retires nothing more"
[[ -f $home/.config/maitri-mail/accounts.json ]] || fail "a re-run keeps the moved data"
pass "a re-run changes nothing"

# --- omamail's keybinding block -------------------------------------------

reset_home
write_shell_json "$(andrews_shell_json)"
write_omamail_plugin
write_bindings "$home/dotfiles/bindings.lua" "$(omamail_bindings_block maitri-shell)"
truncate -s -1 "$home/dotfiles/bindings.lua"
mkdir -p "$(dirname "$bindings")"
ln -s "$home/dotfiles/bindings.lua" "$bindings"
write_bindings "$test_dir/expected-bindings" "$(mail_bindings_block)"
truncate -s -1 "$test_dir/expected-bindings"
run_migration || fail "a linked bindings.lua migrates" "$(cat "$output")"
[[ -L $bindings ]] || fail "a linked bindings.lua stays a link"
cmp -s "$home/dotfiles/bindings.lua" "$test_dir/expected-bindings" ||
  fail "a block calling maitri-shell is rewritten too, where the link points, without adding a final newline" \
    "$(diff "$test_dir/expected-bindings" "$home/dotfiles/bindings.lua")"
pass "a block already calling maitri-shell is rewritten through a link, final newline or not"

reset_home
write_shell_json "$(andrews_shell_json)"
write_omamail_plugin
write_bindings "$bindings" "-- no mail client here"
cp "$bindings" "$test_dir/bindings-before"
run_migration || fail "bindings.lua without the block migrates" "$(cat "$output")"
cmp -s "$bindings" "$test_dir/bindings-before" || fail "bindings.lua without omamail's block is left byte for byte"
! grep -q "keybindings\|SUPER+SHIFT+E" "$output" || fail "no block means nothing to say about the keys" "$(cat "$output")"
pass "bindings.lua without omamail's block is left alone"

reset_home
write_shell_json "$(andrews_shell_json)"
write_omamail_plugin
write_bindings "$bindings" "$(omamail_bindings_block omarchy-shell | sed 's/"SUPER + SHIFT + E", "Email"/"SUPER + E", "Email"/')"  # rebrand:keep
cp "$bindings" "$test_dir/bindings-before"
run_migration || fail "an edited keybinding block migrates" "$(cat "$output")"
cmp -s "$bindings" "$test_dir/bindings-before" || fail "a hand-edited block is left byte for byte"
grep -q "Leaving the omamail keybindings in $bindings alone: the block has been edited" "$output" ||
  fail "the migration says how to bind Mail by hand" "$(cat "$output")"
[[ ! -e $plugin ]] || fail "an edited keybinding block does not hold up the rest of the move"
pass "a hand-edited keybinding block is left alone with a hint, and the rest still moves"

mail_repo=${MAITRI_MAIL_PATH:-$ROOT/../maitri-mail}
if [[ -f $mail_repo/scripts/default-mail.sh ]]; then
  fork_block=$(
    eval "$(grep -E '^BLOCK_(BEGIN|END)=' "$mail_repo/scripts/default-mail.sh")"
    eval "$(sed -n '/^bindings_block() {$/,/^}$/p' "$mail_repo/scripts/default-mail.sh")"
    bindings_block
  )
  [[ $fork_block == "$(mail_bindings_block)" ]] ||
    fail "the migration writes the block maitri-mail's default-mail.sh writes" \
      "$(diff <(printf '%s\n' "$fork_block") <(mail_bindings_block))"
  pass "the migration writes the block maitri-mail's default-mail.sh writes"
else
  pass "no maitri-mail checkout (set MAITRI_MAIL_PATH); skipping the default-mail.sh cross-check"
fi

# --- shell.json that is not plain JSON ------------------------------------

reset_home
mkdir -p "$(dirname "$shell_json")"
printf '// my bar\n%s\n' "$(andrews_shell_json)" >"$shell_json"
write_omamail_plugin
write_omamail_data
before=$(cat "$shell_json")
run_migration || fail "a commented shell.json migrates" "$(cat "$output")"
[[ $(cat "$shell_json") == "$before" ]] || fail "a shell.json with comments is left alone"
grep -q '"maitri.mail"' "$output" || fail "the migration says how to keep Mail on the bar by hand" "$(cat "$output")"
[[ -f $home/.config/maitri-mail/accounts.json && ! -e $plugin ]] ||
  fail "the rest of the omamail move still happens"
pass "a shell.json with comments is left alone with a hint, and the rest still moves"

# --- Existing maitri-mail data --------------------------------------------

reset_home
write_shell_json "$(andrews_shell_json)"
write_omamail_plugin
write_omamail_data
mkdir -p "$home/.config/maitri-mail"
echo '{"accounts": ["new@example.com"]}' >"$home/.config/maitri-mail/accounts.json"
run_migration || fail "a machine with maitri-mail data migrates" "$(cat "$output")"
[[ $(cat "$home/.config/maitri-mail/accounts.json") == '{"accounts": ["new@example.com"]}' ]] ||
  fail "existing maitri-mail config is not overwritten"
[[ $(cat "$home/.config/omamail/accounts.json") == '{"accounts": ["me@example.com"]}' ]] ||
  fail "omamail config stays put when maitri-mail config exists"
grep -q "Leaving $home/.config/omamail" "$output" || fail "the migration says which omamail data it left" "$(cat "$output")"
[[ -f $home/.cache/maitri-mail/mail.db && ! -e $home/.cache/omamail ]] ||
  fail "omamail data without a maitri-mail counterpart still moves"
pass "existing maitri-mail data is never clobbered; the rest still moves"

# --- Mail started on empty directories before a retry ----------------------

reset_home
write_shell_json "$(andrews_shell_json)"
write_omamail_plugin
write_omamail_data
mkdir -p "$home/.config/maitri-mail" "$home/.cache/maitri-mail"
echo '{"width": 900}' >"$home/.config/maitri-mail/window.json"
echo "empty" >"$home/.cache/maitri-mail/mail.db"
run_migration || fail "a machine where Mail already started migrates" "$(cat "$output")"
[[ $(cat "$home/.config/maitri-mail/accounts.json") == '{"accounts": ["me@example.com"]}' &&
  $(cat "$home/.cache/maitri-mail/mail.db") == "cached mail" &&
  ! -e $home/.config/omamail && ! -e $home/.cache/omamail ]] ||
  fail "omamail data replaces directories Mail created without accounts" "$(find "$home" -path '*mail*' | sort)"
backup=$(find "$home/.local/state/maitri/backups" -maxdepth 1 -name 'maitri-mail-before-omamail-*' | head -1)
[[ -n $backup && $(cat "$backup/.config/window.json") == '{"width": 900}' && $(cat "$backup/.cache/mail.db") == "empty" ]] ||
  fail "the empty Mail directories are kept in a backup" "$(find "$home/.local/state/maitri" | sort)"
pass "omamail data takes over directories Mail created before a retry"

# --- Mail already on the bar ----------------------------------------------

reset_home
write_shell_json "$(stock_shell_json | jq '.bar.layout.right += [{id: "maitri.mail", refreshIntervalSec: 300}]')"
before=$(cat "$shell_json")
run_migration || fail "a bar that has Mail migrates" "$(cat "$output")"
[[ $(cat "$shell_json") == "$before" ]] || fail "a bar that has Mail is left as it is"
pass "a bar that already has Mail is left as it is"

reset_home
write_shell_json "$(andrews_shell_json | jq '.bar.layout.right += [{id: "maitri.mail", refreshIntervalSec: 300, notifyNewMail: "On"}]')"
write_omamail_plugin
run_migration || fail "a bar with both omamail and Mail migrates" "$(cat "$output")"
[[ $(jq -cS '[.bar.layout[][] | select((.id // .) == "maitri.mail")]' "$shell_json") == \
  '[{"id":"maitri.mail","notifyNewMail":"On","refreshIntervalSec":300,"unifiedMailboxes":true}]' ]] ||
  fail "omamail folds into the Mail entry already on the bar" "$(jq -c '.bar.layout' "$shell_json")"
! grep -q omamail "$shell_json" || fail "no omamail entry is left beside Mail"
pass "omamail folds into a Mail entry already on the bar; Mail's own settings win"

# --- Failures that leave the migration pending ----------------------------

reset_home
write_shell_json "$(andrews_shell_json)"
write_omamail_plugin
write_omamail_data
before=$(cat "$shell_json")
if MAITRI_TEST_PKG_STATUS=1 run_migration; then
  fail "a failed package install fails the migration"
fi
[[ $(cat "$shell_json") == "$before" && -d $plugin && -d $home/.config/omamail && $(cat "$mailto") == "omamail.desktop" ]] ||
  fail "a failed package install changes nothing else"
pass "a failed package install fails the migration, leaving it pending and everything in place"

if MAITRI_TEST_OMAMAIL_RUNNING=100 run_migration; then
  fail "an omamail that will not stop fails the migration"
fi
[[ -d $home/.config/omamail && -d $plugin ]] || fail "an omamail that will not stop keeps its data and plugin"
grep -q "pkill -x omamail" "$output" || fail "the migration says how to stop omamail" "$(cat "$output")"
rm -f "$pgrep_count"
run_migration || fail "the pending migration finishes once omamail stops" "$(cat "$output")"
[[ -f $home/.config/maitri-mail/accounts.json && ! -e $plugin ]] ||
  fail "the retry finishes the move"
[[ $(jq -c '.bar.layout.center[-1]' "$shell_json") == '{"id":"maitri.mail","notifyNewMail":"Off","unifiedMailboxes":true}' ]] ||
  fail "the retry keeps the renamed entry"
pass "an omamail that will not stop leaves the migration pending, and the retry finishes it"
