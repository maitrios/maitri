#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

home="$tmpdir/home"
user_apps="$home/.local/share/applications"
system_apps="$tmpdir/system/applications"
state="$home/.local/state/maitri/icons"
mkdir -p "$user_apps" "$system_apps"

run_icons() {
  HOME="$home" XDG_DATA_HOME="" XDG_DATA_DIRS="$tmpdir/system" MAITRI_PATH="${maitri_path:-$ROOT}" PATH="$ROOT/bin:$PATH" \
    "$ROOT/bin/maitri-icons-$1" >"$tmpdir/out" 2>"$tmpdir/err" ||
    fail "maitri-icons-$1 exits cleanly" "$(cat "$tmpdir/err")"
}

desktop_entry() {
  printf '[Desktop Entry]\nType=Application\nName=%s\nExec=%s\nIcon=%s\n' "$1" "$2" "$3"
}

vscode_icon="$ROOT/default/icons/vscode.png"
slack_icon="$ROOT/default/icons/slack.png"
[[ -f $vscode_icon && -f $slack_icon ]] || fail "maitri ships the icons this test uses"

for icon in "$ROOT"/default/icons/*; do
  [[ -f $icon && ! -L $icon ]] || fail "default/icons holds only regular files" "$icon"
  [[ $icon == *.png || $icon == *.svg ]] || fail "default/icons holds only png and svg icons" "$icon"
done
pass "default/icons holds png and svg files"

{
  desktop_entry "Visual Studio Code" "code %F" "vscode"
  printf '\n[Desktop Action new-empty-window]\nName=New Empty Window\nExec=code --new-window %%F\nIcon=vscode\n'
} >"$system_apps/code.desktop"
desktop_entry "Slack" "slack %U" "slack" >"$system_apps/slack.desktop"
desktop_entry "Slack" "slack-launch %U" "slack" >"$user_apps/slack.desktop"
chmod 755 "$user_apps/slack.desktop"
desktop_entry "Foot" "foot" "foot" >"$system_apps/foot.desktop"
{
  desktop_entry "Code URL Handler" "code --open-url %U" "vscode"
  printf 'NoDisplay=true\n'
} >"$system_apps/code-url-handler.desktop"

cp "$user_apps/slack.desktop" "$tmpdir/slack-original.desktop"
cp -r "$system_apps" "$tmpdir/system-before"

run_icons set

[[ -f $user_apps/code.desktop ]] || fail "set writes a user override for a system launcher"
(( $(grep -c "^Icon=$vscode_icon\$" "$user_apps/code.desktop") == 2 )) ||
  fail "set points every Icon line of the override at the maitri icon" "$(cat "$user_apps/code.desktop")"
grep -Fxq 'Exec=code %F' "$user_apps/code.desktop" || fail "set keeps the rest of the launcher"
pass "set overrides a system launcher in the user applications dir"

grep -Fxq "Icon=$slack_icon" "$user_apps/slack.desktop" ||
  fail "set swaps the icon of a user launcher" "$(cat "$user_apps/slack.desktop")"
grep -Fxq 'Exec=slack-launch %U' "$user_apps/slack.desktop" || fail "set edits the user launcher, not the system one"
[[ -x $user_apps/slack.desktop ]] || fail "set keeps the user launcher's mode"
pass "set swaps the icon of a launcher already in the user dir"

[[ ! -e $user_apps/foot.desktop ]] || fail "set leaves launchers without a maitri icon alone"
[[ ! -e $user_apps/code-url-handler.desktop ]] || fail "set skips hidden launchers"
diff -r "$tmpdir/system-before" "$system_apps" >/dev/null || fail "set never writes to the system applications dir"
pass "set leaves other launchers and the system dir untouched"

[[ -f $state/manifest ]] || fail "set keeps a restore manifest"
grep -Fxq "code.desktop"$'\t'"created"$'\t'"$vscode_icon" "$state/manifest" ||
  fail "manifest records the created override" "$(cat "$state/manifest")"
grep -Fxq "slack.desktop"$'\t'"replaced"$'\t'"$slack_icon" "$state/manifest" ||
  fail "manifest records the replaced launcher" "$(cat "$state/manifest")"
cmp -s "$state/originals/slack.desktop" "$tmpdir/slack-original.desktop" ||
  fail "set keeps the original user launcher"
pass "set records what it changed"

cp "$state/manifest" "$tmpdir/manifest-first"
run_icons set
cmp -s "$state/manifest" "$tmpdir/manifest-first" || fail "a second set leaves the manifest as it was" "$(cat "$state/manifest")"
cmp -s "$state/originals/slack.desktop" "$tmpdir/slack-original.desktop" ||
  fail "a second set keeps the real original"
pass "set is idempotent"

run_icons restore

[[ ! -e $user_apps/code.desktop ]] || fail "restore removes the overrides it created"
cmp -s "$user_apps/slack.desktop" "$tmpdir/slack-original.desktop" ||
  fail "restore puts the original user launcher back" "$(cat "$user_apps/slack.desktop")"
[[ -x $user_apps/slack.desktop ]] || fail "restore keeps the original launcher's mode"
[[ ! -e $state ]] || fail "restore clears its state"
diff -r "$tmpdir/system-before" "$system_apps" >/dev/null || fail "restore never writes to the system applications dir"
[[ -z $(ls -A "$user_apps" | grep -vx 'slack.desktop' | grep -v '^mimeinfo.cache$' || true) ]] ||
  fail "restore leaves the user applications dir clean" "$(ls -A "$user_apps")"
pass "restore round-trips to the original launchers"

run_icons set
desktop_entry "Visual Studio Code" "code --custom %F" "my-code-icon" >"$user_apps/code.desktop"
run_icons restore
grep -Fxq 'Icon=my-code-icon' "$user_apps/code.desktop" || fail "restore keeps launchers changed after set"
pass "restore leaves launchers that no longer point at a maitri icon"

rm "$user_apps/code.desktop"
run_icons restore
grep -Fq 'No swapped icons' "$tmpdir/out" || fail "restore with nothing to do says so" "$(cat "$tmpdir/out")"
pass "restore with nothing swapped is a no-op"

maitri_path="$tmpdir/maitri"
mkdir -p "$maitri_path/default/icons"
printf '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1"/>\n' >"$maitri_path/default/icons/foot.svg"
run_icons set
grep -Fxq "Icon=$maitri_path/default/icons/foot.svg" "$user_apps/foot.desktop" ||
  fail "set uses an svg icon when there is no png" "$(cat "$user_apps/foot.desktop" 2>/dev/null)"
run_icons restore
[[ ! -e $user_apps/foot.desktop ]] || fail "restore removes the svg override"
pass "set and restore handle svg icons"
