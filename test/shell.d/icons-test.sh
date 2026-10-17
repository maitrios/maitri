#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

home="$tmpdir/home"
user_apps="$home/.local/share/applications"
system_apps="$tmpdir/system/applications"
second_apps="$tmpdir/second/applications"
state="$home/.local/state/maitri/icons"
icons="$ROOT/default/icons"

for icon in "$icons"/*; do
  [[ -f $icon && ! -L $icon ]] || fail "default/icons holds only regular files" "$icon"
  [[ $icon == *.png || $icon == *.svg ]] || fail "default/icons holds only png and svg icons" "$icon"
done
pass "default/icons holds png and svg files"

run_icons() {
  local command="$1"
  shift

  HOME="$home" XDG_DATA_HOME="${data_home-}" XDG_DATA_DIRS="$tmpdir/system:$tmpdir/second" \
    MAITRI_PATH="${maitri_path:-$ROOT}" PATH="$ROOT/bin:$PATH" \
    "$ROOT/bin/maitri-icons-$command" "$@" >"$tmpdir/out" 2>"$tmpdir/err" ||
    fail "maitri-icons-$command exits cleanly" "$(cat "$tmpdir/err")"
}

desktop_entry() {
  printf '[Desktop Entry]\nType=Application\nName=%s\nExec=%s\nIcon=%s\n' "$1" "$2" "$3"
}

hash_of() {
  sha256sum <"$1" | cut -d' ' -f1
}

reset_fixture() {
  rm -rf "$home" "$tmpdir/system" "$tmpdir/second" "$tmpdir/elsewhere"
  mkdir -p "$user_apps" "$system_apps" "$second_apps" "$tmpdir/elsewhere"

  {
    desktop_entry "Visual Studio Code" "code %F" "vscode"
    printf '\n[Desktop Action new-empty-window]\nName=New Empty Window\nExec=code --new-window %%F\nIcon=vscode\n'
  } >"$system_apps/code.desktop"
  desktop_entry "Slack" "slack %U" "slack" >"$system_apps/slack.desktop"
  desktop_entry "Foot" "foot" "foot" >"$system_apps/foot.desktop"
  {
    desktop_entry "Code URL Handler" "code --open-url %U" "vscode"
    printf 'NoDisplay=true\n'
  } >"$system_apps/code-url-handler.desktop"
  {
    printf '[Desktop Entry]\nType=Application\nName=Firefox\nExec=firefox %%u\nIcon = firefox\n'
    printf '\n[Desktop Action private]\nName=Private Window\nExec=firefox --private-window\nNoDisplay=true\n'
  } >"$system_apps/firefox.desktop"
  desktop_entry "Chrome" "google-chrome-stable %U" "google-chrome.png" >"$system_apps/google-chrome.desktop"
  desktop_entry "Bundled" "bundled" "/opt/bundled/slack.png" >"$system_apps/bundled.desktop"
  desktop_entry "GVim" "gvim -f %F" "gvim" >"$system_apps/gvim.desktop"

  desktop_entry "GVim" "gvim-shadowed %F" "gvim" >"$second_apps/gvim.desktop"
  desktop_entry "Sublime Text" "subl %F" "sublime-text" >"$second_apps/sublime_text.desktop"

  desktop_entry "Slack" "slack-launch %U" "slack" >"$user_apps/slack.desktop"
  chmod 755 "$user_apps/slack.desktop"
  desktop_entry "Alacritty" "alacritty" "Alacritty" >"$tmpdir/elsewhere/Alacritty.desktop"
  ln -s "$tmpdir/elsewhere/Alacritty.desktop" "$user_apps/Alacritty.desktop"

  cp "$user_apps/slack.desktop" "$tmpdir/slack-original.desktop"
  rm -rf "$tmpdir/system-before"
  mkdir -p "$tmpdir/system-before"
  cp -r "$tmpdir/system" "$tmpdir/second" "$tmpdir/system-before/"
}

system_untouched() {
  diff -r "$tmpdir/system-before/system" "$tmpdir/system" >/dev/null &&
    diff -r "$tmpdir/system-before/second" "$tmpdir/second" >/dev/null
}

reset_fixture
run_icons set

(( $(grep -c "^Icon=$icons/vscode.png\$" "$user_apps/code.desktop") == 2 )) ||
  fail "set points every Icon line of the override at the maitri icon" "$(cat "$user_apps/code.desktop")"
grep -Fxq 'Exec=code %F' "$user_apps/code.desktop" || fail "set keeps the rest of the launcher"
pass "set overrides a system launcher in the user applications dir"

grep -Fxq "Icon=$icons/slack.png" "$user_apps/slack.desktop" ||
  fail "set swaps the icon of a user launcher" "$(cat "$user_apps/slack.desktop")"
grep -Fxq 'Exec=slack-launch %U' "$user_apps/slack.desktop" || fail "set edits the user launcher, not the system one"
[[ -x $user_apps/slack.desktop ]] || fail "set keeps the user launcher's mode"
[[ -L $state/originals/Alacritty.desktop ]] || fail "set saves a symlinked user launcher as a symlink"
grep -Fxq "Icon=$icons/Alacritty.png" "$user_apps/Alacritty.desktop" || fail "set swaps a symlinked user launcher"
grep -Fxq 'Icon=Alacritty' "$tmpdir/elsewhere/Alacritty.desktop" || fail "set never edits a symlink's target"
pass "set swaps launchers already in the user dir, symlinks included"

grep -Fxq "Icon=$icons/firefox.png" "$user_apps/firefox.desktop" ||
  fail "set reads a spaced Icon key and ignores NoDisplay in an action group" "$(cat "$user_apps/firefox.desktop" 2>/dev/null)"
grep -Fxq "Icon=$icons/google-chrome.png" "$user_apps/google-chrome.desktop" ||
  fail "set matches an Icon key with a file extension" "$(cat "$user_apps/google-chrome.desktop" 2>/dev/null)"
grep -Fxq 'Exec=gvim -f %F' "$user_apps/gvim.desktop" || fail "set copies the first launcher in XDG_DATA_DIRS"
grep -Fxq "Icon=$icons/sublime-text.png" "$user_apps/sublime_text.desktop" || fail "set reads every XDG_DATA_DIRS entry"
pass "set reads only the Desktop Entry group and walks XDG_DATA_DIRS in order"

[[ ! -e $user_apps/foot.desktop ]] || fail "set leaves launchers without a maitri icon alone"
[[ ! -e $user_apps/code-url-handler.desktop ]] || fail "set skips hidden launchers"
[[ ! -e $user_apps/bundled.desktop ]] || fail "set leaves absolute Icon paths alone"
system_untouched || fail "set never writes to the system applications dirs"
ls "$state" | grep -q '^write\.' && fail "set leaves no temp files behind"
pass "set leaves other launchers and the system dirs untouched"

grep -Fxq "code.desktop"$'\t'"created"$'\t'"$icons/vscode.png"$'\t'"$(hash_of "$user_apps/code.desktop")" "$state/manifest" ||
  fail "manifest records the created override and its hash" "$(cat "$state/manifest")"
grep -Fxq "slack.desktop"$'\t'"replaced"$'\t'"$icons/slack.png"$'\t'"$(hash_of "$user_apps/slack.desktop")" "$state/manifest" ||
  fail "manifest records the replaced launcher and its hash" "$(cat "$state/manifest")"
cmp -s "$state/originals/slack.desktop" "$tmpdir/slack-original.desktop" || fail "set keeps the original user launcher"
pass "set records what it changed"

cp "$state/manifest" "$tmpdir/manifest-first"
run_icons set
cmp -s "$state/manifest" "$tmpdir/manifest-first" || fail "a second set leaves the manifest as it was" "$(cat "$state/manifest")"
cmp -s "$state/originals/slack.desktop" "$tmpdir/slack-original.desktop" || fail "a second set keeps the real original"
pass "set is idempotent"

sed -i 's/^Exec=code %F$/Exec=code --enable-features=new %F/' "$system_apps/code.desktop"
rm "$second_apps/sublime_text.desktop"
run_icons set
grep -Fxq 'Exec=code --enable-features=new %F' "$user_apps/code.desktop" ||
  fail "set refreshes a created override from its updated system launcher" "$(cat "$user_apps/code.desktop")"
grep -Fxq "Icon=$icons/vscode.png" "$user_apps/code.desktop" || fail "a refreshed override keeps the maitri icon"
[[ ! -e $user_apps/sublime_text.desktop ]] || fail "set drops an override whose app is gone"
grep -q '^sublime_text.desktop' "$state/manifest" && fail "set forgets an override whose app is gone"
pass "set follows package updates and removals"

rm -rf "$tmpdir/system-before"
mkdir -p "$tmpdir/system-before"
cp -r "$tmpdir/system" "$tmpdir/second" "$tmpdir/system-before/"

sed -i 's/^Exec=gvim -f %F$/Exec=gvim -f --my-flag %F/' "$user_apps/gvim.desktop"
run_icons restore gvim.desktop
grep -Fxq 'Exec=gvim -f --my-flag %F' "$user_apps/gvim.desktop" || fail "restore keeps an edited override"
grep -Fxq 'Icon=gvim' "$user_apps/gvim.desktop" || fail "restore reverts the icon of an edited override"
grep -q '^gvim.desktop' "$state/manifest" && fail "restore of one launcher drops its manifest line"
grep -q '^code.desktop' "$state/manifest" || fail "restore of one launcher keeps the others"
[[ -e $user_apps/code.desktop ]] || fail "restore of one launcher leaves the others swapped"
pass "restore of one launcher keeps user edits and the other swaps"

run_icons restore

[[ ! -e $user_apps/code.desktop && ! -e $user_apps/firefox.desktop && ! -e $user_apps/google-chrome.desktop ]] ||
  fail "restore removes the overrides it created"
cmp -s "$user_apps/slack.desktop" "$tmpdir/slack-original.desktop" ||
  fail "restore puts the original user launcher back" "$(cat "$user_apps/slack.desktop")"
[[ -x $user_apps/slack.desktop ]] || fail "restore keeps the original launcher's mode"
[[ -L $user_apps/Alacritty.desktop && $(readlink "$user_apps/Alacritty.desktop") == "$tmpdir/elsewhere/Alacritty.desktop" ]] ||
  fail "restore puts a symlinked launcher back as the same symlink"
[[ ! -e $state ]] || fail "restore clears its state"
system_untouched || fail "restore never writes to the system applications dirs"
leftover=$(ls -A "$user_apps" | grep -vxE 'slack\.desktop|Alacritty\.desktop|gvim\.desktop|mimeinfo\.cache' || true)
[[ -z $leftover ]] || fail "restore leaves the user applications dir clean" "$leftover"
pass "restore round-trips to the original launchers"

reset_fixture
run_icons set
desktop_entry "Visual Studio Code" "code --custom %F" "my-code-icon" >"$user_apps/code.desktop"
rm "$state/originals/slack.desktop"
run_icons restore
grep -Fxq 'Icon=my-code-icon' "$user_apps/code.desktop" || fail "restore keeps launchers changed after set"
grep -Fxq 'Exec=slack-launch %U' "$user_apps/slack.desktop" || fail "restore keeps a replaced launcher whose original is missing"
grep -Fxq 'Icon=slack' "$user_apps/slack.desktop" || fail "restore reverts the icon when the original is missing"
pass "restore leaves changed launchers and reverts icons it can't restore"

run_icons restore
grep -Fq 'No swapped icons' "$tmpdir/out" || fail "restore with nothing to do says so" "$(cat "$tmpdir/out")"
pass "restore with nothing swapped is a no-op"

reset_fixture
run_icons set
awk -F'\t' -v OFS='\t' '{ print $1, $2, $3 }' "$state/manifest" >"$tmpdir/legacy" && mv "$tmpdir/legacy" "$state/manifest"
run_icons set
grep -Fxq "code.desktop"$'\t'"created"$'\t'"$icons/vscode.png"$'\t'"$(hash_of "$user_apps/code.desktop")" "$state/manifest" ||
  fail "set upgrades a manifest without hashes" "$(cat "$state/manifest")"
awk -F'\t' -v OFS='\t' '{ print $1, $2, $3 }' "$state/manifest" >"$tmpdir/legacy" && mv "$tmpdir/legacy" "$state/manifest"
run_icons restore
[[ ! -e $user_apps/code.desktop ]] || fail "restore reads a manifest without hashes"
pass "manifests without hashes still set and restore"

reset_fixture
data_home="$tmpdir/data"
run_icons set
grep -Fxq "Icon=$icons/vscode.png" "$data_home/applications/code.desktop" || fail "set writes overrides under XDG_DATA_HOME"
[[ ! -e $user_apps/code.desktop ]] || fail "set ignores ~/.local/share when XDG_DATA_HOME is set"
run_icons restore
[[ ! -e $data_home/applications/code.desktop ]] || fail "restore reads overrides under XDG_DATA_HOME"
unset data_home
pass "set and restore follow XDG_DATA_HOME"

reset_fixture
maitri_path="$tmpdir/maitri"
mkdir -p "$maitri_path/default/icons"
printf '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1"/>\n' >"$maitri_path/default/icons/foot.svg"
run_icons set
grep -Fxq "Icon=$maitri_path/default/icons/foot.svg" "$user_apps/foot.desktop" ||
  fail "set uses an svg icon when there is no png" "$(cat "$user_apps/foot.desktop" 2>/dev/null)"
run_icons restore
[[ ! -e $user_apps/foot.desktop ]] || fail "restore removes the svg override"
unset maitri_path
pass "set and restore handle svg icons"

reset_fixture
run_icons set
mkdir -p "$tmpdir/stubs"
cat >"$tmpdir/stubs/pacman" <<'SCRIPT'
#!/bin/bash
[[ $1 == "-Qqo" && $2 == */system/applications/code.desktop ]] && printf 'code\n'
SCRIPT
cat >"$tmpdir/stubs/maitri-launch-floating-terminal-with-presentation" <<'SCRIPT'
#!/bin/bash
printf '%s\n' "$*" >>"$TEST_LOG"
SCRIPT
chmod +x "$tmpdir/stubs/pacman" "$tmpdir/stubs/maitri-launch-floating-terminal-with-presentation"
HOME="$home" XDG_DATA_HOME="" XDG_DATA_DIRS="$tmpdir/system:$tmpdir/second" TEST_LOG="$tmpdir/remove.log" \
  MAITRI_PATH="$ROOT" PATH="$tmpdir/stubs:$ROOT/bin:$PATH" \
  "$ROOT/bin/maitri-remove-launcher-entry" code.desktop Code >"$tmpdir/out" 2>"$tmpdir/err" ||
  fail "launcher remove handles a swapped app" "$(cat "$tmpdir/err")"
grep -Fxq 'echo Uninstalling Code...; sudo pacman -Rns code' "$tmpdir/remove.log" ||
  fail "launcher remove uninstalls the app behind a swapped icon" "$(cat "$tmpdir/remove.log" 2>/dev/null)"
[[ ! -e $user_apps/code.desktop ]] || fail "launcher remove drops the icon override"
grep -q '^code.desktop' "$state/manifest" && fail "launcher remove forgets the icon override"
grep -q '^slack.desktop' "$state/manifest" || fail "launcher remove keeps the other swaps"
pass "launcher remove uninstalls an app whose icon was swapped"
