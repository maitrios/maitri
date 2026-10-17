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
theme_icons="$home/.local/share/icons/hicolor"
icons="$ROOT/default/icons"

for icon in "$icons"/*; do
  if [[ -d $icon && ! -L $icon ]]; then
    [[ -d $ROOT/themes/${icon##*/} ]] || fail "default/icons holds folders only for maitri themes" "$icon"
    for variant in "$icon"/*; do
      [[ -f $variant && ! -L $variant ]] || fail "a theme's icon folder holds only regular files" "$variant"
      [[ $variant == *.png || $variant == *.svg ]] || fail "a theme's icon folder holds only png and svg icons" "$variant"
      key="${variant##*/}"
      [[ -f $icons/${key%.*}.png || -f $icons/${key%.*}.svg ]] || fail "every theme variant has a base icon" "$variant"
    done
    continue
  fi
  [[ -f $icon && ! -L $icon ]] || fail "default/icons holds only regular files" "$icon"
  [[ $icon == *.png || $icon == *.svg ]] || fail "default/icons holds only png and svg icons" "$icon"
done
pass "default/icons holds png and svg files, and per-theme folders of them"

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

(( $(grep -c "^Icon=maitri-vscode\$" "$user_apps/code.desktop") == 2 )) ||
  fail "set points every Icon line of the override at the maitri icon" "$(cat "$user_apps/code.desktop")"
grep -Fxq 'Exec=code %F' "$user_apps/code.desktop" || fail "set keeps the rest of the launcher"
pass "set overrides a system launcher in the user applications dir"

grep -Fxq "Icon=maitri-slack" "$user_apps/slack.desktop" ||
  fail "set swaps the icon of a user launcher" "$(cat "$user_apps/slack.desktop")"
grep -Fxq 'Exec=slack-launch %U' "$user_apps/slack.desktop" || fail "set edits the user launcher, not the system one"
[[ -x $user_apps/slack.desktop ]] || fail "set keeps the user launcher's mode"
[[ -L $state/originals/Alacritty.desktop ]] || fail "set saves a symlinked user launcher as a symlink"
grep -Fxq "Icon=maitri-Alacritty" "$user_apps/Alacritty.desktop" || fail "set swaps a symlinked user launcher"
grep -Fxq 'Icon=Alacritty' "$tmpdir/elsewhere/Alacritty.desktop" || fail "set never edits a symlink's target"
pass "set swaps launchers already in the user dir, symlinks included"

grep -Fxq "Icon=maitri-firefox" "$user_apps/firefox.desktop" ||
  fail "set reads a spaced Icon key and ignores NoDisplay in an action group" "$(cat "$user_apps/firefox.desktop" 2>/dev/null)"
grep -Fxq "Icon=maitri-google-chrome" "$user_apps/google-chrome.desktop" ||
  fail "set matches an Icon key with a file extension" "$(cat "$user_apps/google-chrome.desktop" 2>/dev/null)"
grep -Fxq 'Exec=gvim -f %F' "$user_apps/gvim.desktop" || fail "set copies the first launcher in XDG_DATA_DIRS"
grep -Fxq "Icon=maitri-sublime-text" "$user_apps/sublime_text.desktop" || fail "set reads every XDG_DATA_DIRS entry"
pass "set reads only the Desktop Entry group and walks XDG_DATA_DIRS in order"

[[ ! -e $user_apps/foot.desktop ]] || fail "set leaves launchers without a maitri icon alone"
[[ ! -e $user_apps/code-url-handler.desktop ]] || fail "set skips hidden launchers"
[[ ! -e $user_apps/bundled.desktop ]] || fail "set leaves absolute Icon paths alone"
system_untouched || fail "set never writes to the system applications dirs"
ls "$state" | grep -q '^write\.' && fail "set leaves no temp files behind"
pass "set leaves other launchers and the system dirs untouched"

grep -Fxq "code.desktop"$'\t'"created"$'\t'"maitri-vscode"$'\t'"$(hash_of "$user_apps/code.desktop")" "$state/manifest" ||
  fail "manifest records the created override and its hash" "$(cat "$state/manifest")"
grep -Fxq "slack.desktop"$'\t'"replaced"$'\t'"maitri-slack"$'\t'"$(hash_of "$user_apps/slack.desktop")" "$state/manifest" ||
  fail "manifest records the replaced launcher and its hash" "$(cat "$state/manifest")"
cmp -s "$state/originals/slack.desktop" "$tmpdir/slack-original.desktop" || fail "set keeps the original user launcher"
pass "set records what it changed"

for key in vscode slack Alacritty firefox google-chrome gvim sublime-text; do
  cmp -s "$icons/$key.png" "$theme_icons/256x256/apps/maitri-$key.png" ||
    fail "set copies each icon it uses into the user's hicolor theme under a maitri name" "$key"
  [[ $(stat -c %a "$theme_icons/256x256/apps/maitri-$key.png") == 644 ]] || fail "icon copies are 0644" "$key"
  grep -Fxq "$theme_icons/256x256/apps/maitri-$key.png" "$state/copies" || fail "set records each icon copy" "$key"
done
grep -rq "$ROOT" "$user_apps" && fail "no launcher refers to the maitri checkout"
pass "set copies its icons into the user's hicolor theme and refers to them by name"

cp "$state/manifest" "$tmpdir/manifest-first"
run_icons set
cmp -s "$state/manifest" "$tmpdir/manifest-first" || fail "a second set leaves the manifest as it was" "$(cat "$state/manifest")"
cmp -s "$state/originals/slack.desktop" "$tmpdir/slack-original.desktop" || fail "a second set keeps the real original"
touch -d '2000-01-01' "$user_apps/code.desktop"
run_icons set
[[ $(stat -c %Y "$user_apps/code.desktop") == "$(date -d '2000-01-01' +%s)" ]] ||
  fail "set leaves an up-to-date override untouched"
pass "set is idempotent"

sed -i 's/^Exec=code %F$/Exec=code --enable-features=new %F/' "$system_apps/code.desktop"
rm "$second_apps/sublime_text.desktop"
run_icons set
grep -Fxq 'Exec=code --enable-features=new %F' "$user_apps/code.desktop" ||
  fail "set refreshes a created override from its updated system launcher" "$(cat "$user_apps/code.desktop")"
grep -Fxq "Icon=maitri-vscode" "$user_apps/code.desktop" || fail "a refreshed override keeps the maitri icon"
[[ ! -e $user_apps/sublime_text.desktop ]] || fail "set drops an override whose app is gone"
grep -q '^sublime_text.desktop' "$state/manifest" && fail "set forgets an override whose app is gone"
pass "set follows package updates and removals"

rm -rf "$tmpdir/system-before"
mkdir -p "$tmpdir/system-before"
cp -r "$tmpdir/system" "$tmpdir/second" "$tmpdir/system-before/"

sed -i 's/^Exec=gvim -f %F$/Exec=gvim -f --my-flag %F/' "$user_apps/gvim.desktop"
run_icons restore gvim
grep -Fxq 'Exec=gvim -f --my-flag %F' "$user_apps/gvim.desktop" || fail "restore keeps an edited override"
grep -Fxq 'Icon=gvim' "$user_apps/gvim.desktop" || fail "restore reverts the icon of an edited override"
grep -q '^gvim.desktop' "$state/manifest" && fail "restore of one launcher drops its manifest line"
[[ ! -e $theme_icons/256x256/apps/maitri-gvim.png ]] || fail "restore of one launcher removes an icon copy nothing else uses"
[[ -e $theme_icons/256x256/apps/maitri-vscode.png ]] || fail "restore of one launcher keeps the icon copies still in use"
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
[[ -z $(find "$theme_icons" -name 'maitri-*' 2>/dev/null) ]] || fail "restore removes every icon copy" "$(find "$theme_icons" -name 'maitri-*')"
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
grep -Fxq "code.desktop"$'\t'"created"$'\t'"maitri-vscode"$'\t'"$(hash_of "$user_apps/code.desktop")" "$state/manifest" ||
  fail "set upgrades a manifest without hashes" "$(cat "$state/manifest")"
awk -F'\t' -v OFS='\t' '{ print $1, $2, $3 }' "$state/manifest" >"$tmpdir/legacy" && mv "$tmpdir/legacy" "$state/manifest"
run_icons restore
[[ ! -e $user_apps/code.desktop ]] || fail "restore reads a manifest without hashes"
pass "manifests without hashes still set and restore"

reset_fixture
run_icons set
sed -i 's/^Exec=code %F$/Exec=code --my-flag %F/' "$user_apps/code.desktop"
awk -F'\t' -v OFS='\t' '{ print $1, $2, $3 }' "$state/manifest" >"$tmpdir/legacy" && mv "$tmpdir/legacy" "$state/manifest"
run_icons set
grep -Fxq 'Exec=code --my-flag %F' "$user_apps/code.desktop" || fail "set keeps a copy edited under a manifest without hashes"
grep -Fxq "code.desktop"$'\t'"created"$'\t'"maitri-vscode"$'\t'"-" "$state/manifest" ||
  fail "set marks a copy edited under a manifest without hashes" "$(cat "$state/manifest")"
run_icons restore
grep -Fxq 'Exec=code --my-flag %F' "$user_apps/code.desktop" || fail "restore keeps a copy edited under a manifest without hashes"
grep -Fxq 'Icon=vscode' "$user_apps/code.desktop" || fail "restore reverts the icon of a copy edited under a manifest without hashes"
pass "copies edited under a manifest without hashes keep their edits"

reset_fixture
data_home="$tmpdir/data"
run_icons set
grep -Fxq "Icon=maitri-vscode" "$data_home/applications/code.desktop" || fail "set writes overrides under XDG_DATA_HOME"
[[ -f $data_home/icons/hicolor/256x256/apps/maitri-vscode.png ]] || fail "set copies icons under XDG_DATA_HOME"
[[ ! -e $user_apps/code.desktop ]] || fail "set ignores ~/.local/share when XDG_DATA_HOME is set"
run_icons restore
[[ ! -e $data_home/applications/code.desktop ]] || fail "restore reads overrides under XDG_DATA_HOME"
[[ ! -e $data_home/icons/hicolor/256x256/apps/maitri-vscode.png ]] || fail "restore removes icon copies under XDG_DATA_HOME"
unset data_home
pass "set and restore follow XDG_DATA_HOME"

reset_fixture
maitri_path="$tmpdir/maitri"
mkdir -p "$maitri_path/default/icons"
printf '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1"/>\n' >"$maitri_path/default/icons/foot.svg"
run_icons set
grep -Fxq "Icon=maitri-foot" "$user_apps/foot.desktop" ||
  fail "set uses an svg icon when there is no png" "$(cat "$user_apps/foot.desktop" 2>/dev/null)"
cmp -s "$maitri_path/default/icons/foot.svg" "$theme_icons/scalable/apps/maitri-foot.svg" || fail "an svg icon is copied to scalable/apps"
run_icons restore
[[ ! -e $user_apps/foot.desktop ]] || fail "restore removes the svg override"
[[ ! -e $theme_icons/scalable/apps/maitri-foot.svg ]] || fail "restore removes the svg copy"
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
sed -i 's/^Exec=code %F$/Exec=code --my-flag %F/' "$user_apps/code.desktop"
HOME="$home" XDG_DATA_HOME="" XDG_DATA_DIRS="$tmpdir/system:$tmpdir/second" TEST_LOG="$tmpdir/remove.log" \
  MAITRI_PATH="$ROOT" PATH="$tmpdir/stubs:$ROOT/bin:$PATH" \
  "$ROOT/bin/maitri-remove-launcher-entry" code.desktop Code >"$tmpdir/out" 2>"$tmpdir/err" ||
  fail "launcher remove handles a swapped app" "$(cat "$tmpdir/err")"
grep -Fxq 'echo Uninstalling Code...; sudo pacman -Rns code' "$tmpdir/remove.log" ||
  fail "launcher remove uninstalls the app behind a swapped icon" "$(cat "$tmpdir/remove.log" 2>/dev/null)"
[[ ! -e $user_apps/code.desktop ]] || fail "launcher remove drops the icon override"
grep -q '^code.desktop' "$state/manifest" && fail "launcher remove forgets the icon override"
grep -q '^slack.desktop' "$state/manifest" || fail "launcher remove keeps the other swaps"
pass "launcher remove uninstalls an app whose icon was swapped, even an edited copy"

reset_fixture
mkdir -p "$tmpdir/abort-stubs"
cat >"$tmpdir/abort-stubs/chmod" <<'SCRIPT'
#!/bin/bash
[[ $* == *gvim.desktop* ]] && exit 1
exec /usr/bin/chmod "$@"
SCRIPT
/usr/bin/chmod +x "$tmpdir/abort-stubs/chmod"
if HOME="$home" XDG_DATA_HOME="" XDG_DATA_DIRS="$tmpdir/system:$tmpdir/second" MAITRI_PATH="$ROOT" \
  PATH="$tmpdir/abort-stubs:$ROOT/bin:$PATH" "$ROOT/bin/maitri-icons-set" >"$tmpdir/out" 2>"$tmpdir/err"; then
  fail "set fails when a write fails"
fi
grep -q 'Swapped icon for code.desktop' "$tmpdir/out" || fail "the aborted set swapped some launchers first" "$(cat "$tmpdir/out")"
for file in "$user_apps"/*.desktop; do
  grep -Fq "Icon=maitri-" "$file" || continue
  cut -f1 "$state/manifest" | grep -Fxq "${file##*/}" || fail "an aborted set records every override it wrote" "${file##*/}"
done
ls "$state" | grep -q '^write\.' && fail "an aborted set leaves no temp files behind"
run_icons set
run_icons restore
leftover=$(ls -A "$user_apps" | grep -vxE 'slack\.desktop|Alacritty\.desktop|mimeinfo\.cache' || true)
[[ -z $leftover ]] || fail "set and restore recover from an aborted set" "$leftover"
pass "an aborted set leaves a manifest restore can finish"

reset_fixture
run_icons set
sed -i 's/^Exec=code %F$/Exec=code --my-flag %F/' "$user_apps/code.desktop"
rm "$system_apps/code.desktop"
run_icons set
grep -Fxq 'Exec=code --my-flag %F' "$user_apps/code.desktop" || fail "set keeps an edited copy of a removed app"
grep -Fxq 'Icon=vscode' "$user_apps/code.desktop" || fail "set reverts the icon of an edited copy of a removed app"
grep -q '^code.desktop' "$state/manifest" && fail "set forgets an edited copy of a removed app"
[[ ! -e $state/originals/code.desktop ]] || fail "set does not adopt a dropped copy as a user launcher"
pass "set drops an edited copy of a removed app without swapping it again"

reset_fixture
run_icons set
sed -i "s|^Icon=maitri-vscode\$|Icon=vscode|" "$user_apps/code.desktop"
run_icons set
grep -q "^code.desktop"$'\t'"created"$'\t' "$state/manifest" || fail "a hand-reverted copy stays created" "$(cat "$state/manifest")"
grep -Fxq "Icon=maitri-vscode" "$user_apps/code.desktop" || fail "set swaps a hand-reverted copy again"
[[ ! -e $state/originals/code.desktop ]] || fail "set does not save its own copy as an original"
pass "set swaps a hand-reverted copy again and keeps tracking it"

cp "$state/manifest" "$tmpdir/manifest-before"
if HOME="$home" XDG_DATA_HOME="" XDG_DATA_DIRS="$tmpdir/system:$tmpdir/second" MAITRI_PATH="$tmpdir/nowhere" \
  PATH="$ROOT/bin:$PATH" "$ROOT/bin/maitri-icons-set" >"$tmpdir/out" 2>"$tmpdir/err"; then
  fail "set fails without an icon set"
fi
cmp -s "$state/manifest" "$tmpdir/manifest-before" || fail "set without an icon set leaves the manifest alone"
[[ -e $user_apps/code.desktop ]] || fail "set without an icon set leaves the overrides alone"
pass "set refuses to run without an icon set"

run_icons restore nothere
grep -Fq 'No swapped icon for nothere.desktop' "$tmpdir/err" || fail "restore names a launcher it has no swap for" "$(cat "$tmpdir/err")"
grep -q '^code.desktop' "$state/manifest" || fail "restore of an unknown launcher keeps the others"
pass "restore says when a launcher has no swap"

reset_fixture
maitri_path="$tmpdir/linked"
mkdir -p "$maitri_path/default"
cp -r "$icons" "$maitri_path/default/icons"
run_icons set
cp -r "$user_apps" "$tmpdir/apps-linked"
cp "$state/manifest" "$tmpdir/manifest-linked"
rm -rf "$maitri_path"
maitri_path="$ROOT"
diff -r "$tmpdir/apps-linked" "$user_apps" >/dev/null || fail "unlinking the checkout leaves the launchers alone"
for file in code slack firefox; do
  icon=$(sed -n 's/^Icon=//p' "$user_apps/$file.desktop" | head -n 1)
  [[ -n $(find "$theme_icons" -name "$icon.png") ]] || fail "a swapped icon still resolves once the checkout it came from is gone" "$file: $icon"
done
touch -d '2000-01-01' "$user_apps/code.desktop"
run_icons set
[[ $(stat -c %Y "$user_apps/code.desktop") == "$(date -d '2000-01-01' +%s)" ]] ||
  fail "set from another MAITRI_PATH leaves the launchers as they are"
cmp -s "$state/manifest" "$tmpdir/manifest-linked" || fail "set from another MAITRI_PATH leaves the manifest as it is"
pass "a swap made under maitri dev link keeps working after unlink"

maitri_path="$tmpdir/updated"
mkdir -p "$maitri_path/default"
cp -r "$icons" "$maitri_path/default/icons"
printf 'new art' >>"$maitri_path/default/icons/vscode.png"
run_icons set
cmp -s "$maitri_path/default/icons/vscode.png" "$theme_icons/256x256/apps/maitri-vscode.png" ||
  fail "set after an update refreshes the icon copy"
grep -Fxq "Icon=maitri-vscode" "$user_apps/code.desktop" || fail "an update keeps the launcher on the same icon name"
run_icons restore
[[ -z $(find "$theme_icons" -name 'maitri-*' 2>/dev/null) ]] || fail "restore after an update removes every copy"
unset maitri_path
pass "set after a package update refreshes the icon copies"

reset_fixture
run_icons set
sed -i 's/^Exec=code %F$/Exec=code --my-flag %F/' "$user_apps/code.desktop"
for file in "$user_apps"/*.desktop; do
  [[ -L $file ]] && continue
  sed -i -E "s|^Icon=maitri-([A-Za-z_-]+)\$|Icon=$icons/\\1.png|" "$file"
done
sed -i -E "s|\tmaitri-([A-Za-z_-]+)\t|\t$icons/\\1.png\t|" "$state/manifest"
legacy=""
while IFS=$'\t' read -r id kind icon hash; do
  [[ $id == "code.desktop" ]] || hash=$(hash_of "$user_apps/$id")
  legacy+="$id"$'\t'"$kind"$'\t'"$icon"$'\t'"$hash"$'\n'
done <"$state/manifest"
printf '%s' "$legacy" >"$state/manifest"
rm -rf "$theme_icons" "$state/copies"
grep -q "$icons/" "$state/manifest" && grep -Fxq "Icon=$icons/slack.png" "$user_apps/slack.desktop" &&
  grep -Fxq "Icon=$icons/vscode.png" "$user_apps/code.desktop" ||
  fail "the test sets up swaps with absolute icon paths" "$(cat "$state/manifest" "$user_apps/slack.desktop")"
run_icons set
grep -q "$icons/" "$state/manifest" "$user_apps"/*.desktop 2>/dev/null &&
  fail "set re-points swaps that used absolute icon paths" "$(grep -l "$icons/" "$state/manifest" "$user_apps"/*.desktop)"
grep -Fxq 'Icon=maitri-slack' "$user_apps/slack.desktop" || fail "set re-points a replaced user launcher"
grep -Fxq 'Exec=code --my-flag %F' "$user_apps/code.desktop" && grep -Fxq 'Icon=maitri-vscode' "$user_apps/code.desktop" ||
  fail "set re-points an edited copy and keeps the edit" "$(cat "$user_apps/code.desktop")"
[[ -f $theme_icons/256x256/apps/maitri-slack.png ]] || fail "set copies the icons of re-pointed swaps"
run_icons restore
cmp -s "$user_apps/slack.desktop" "$tmpdir/slack-original.desktop" || fail "a re-pointed replaced launcher still restores its original"
grep -Fxq 'Icon=vscode' "$user_apps/code.desktop" || fail "a re-pointed edited copy still restores its icon"
pass "set re-points swaps made with absolute icon paths, and restore still undoes them"

reset_fixture
maitri_path="$tmpdir/variants"
mkdir -p "$maitri_path/default" "$home/.local/state/maitri/current"
cp -r "$icons" "$maitri_path/default/icons"
mkdir -p "$maitri_path/default/icons/ember"
cp "$icons/vscode.png" "$maitri_path/default/icons/ember/vscode.png"
printf 'ember art' >>"$maitri_path/default/icons/ember/vscode.png"
printf '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1"/>\n' >"$maitri_path/default/icons/ember/slack.svg"
echo ember >"$home/.local/state/maitri/current/theme.name"
run_icons set
cmp -s "$maitri_path/default/icons/ember/vscode.png" "$theme_icons/256x256/apps/maitri-vscode.png" ||
  fail "set uses the current theme's variant of an icon"
cmp -s "$maitri_path/default/icons/ember/slack.svg" "$theme_icons/scalable/apps/maitri-slack.svg" ||
  fail "a theme's svg variant goes to scalable/apps"
cmp -s "$icons/firefox.png" "$theme_icons/256x256/apps/maitri-firefox.png" ||
  fail "an icon with no variant for the theme uses the base icon"
grep -Fxq "Icon=maitri-vscode" "$user_apps/code.desktop" || fail "a variant keeps the same icon name"
pass "set picks the current theme's icon variants, falling back to the base set"

cp -r "$user_apps" "$tmpdir/apps-ember"
theme_set_icons() {
  HOME="$home" XDG_DATA_HOME="" XDG_DATA_DIRS="$tmpdir/system:$tmpdir/second" \
    MAITRI_PATH="$maitri_path" PATH="$ROOT/bin:$PATH" \
    "$ROOT/bin/maitri-theme-set-icons" >"$tmpdir/out" 2>"$tmpdir/err" ||
    fail "maitri-theme-set-icons exits cleanly" "$(cat "$tmpdir/err")"
}
echo daybreak >"$home/.local/state/maitri/current/theme.name"
theme_set_icons
cmp -s "$icons/vscode.png" "$theme_icons/256x256/apps/maitri-vscode.png" ||
  fail "a theme without variants moves back to the base icons"
cmp -s "$icons/slack.png" "$theme_icons/256x256/apps/maitri-slack.png" &&
  [[ ! -e $theme_icons/scalable/apps/maitri-slack.svg ]] ||
  fail "moving off an svg variant replaces its copy with the base png"
diff -r "$tmpdir/apps-ember" "$user_apps" >/dev/null || fail "changing theme leaves the launchers alone"
echo ember >"$home/.local/state/maitri/current/theme.name"
theme_set_icons
cmp -s "$maitri_path/default/icons/ember/vscode.png" "$theme_icons/256x256/apps/maitri-vscode.png" ||
  fail "changing back to a theme with variants uses them again"
echo '../icons/ember' >"$home/.local/state/maitri/current/theme.name"
theme_set_icons
cmp -s "$icons/vscode.png" "$theme_icons/256x256/apps/maitri-vscode.png" ||
  fail "a theme name that isn't a plain name never picks a variant folder, even one that would reach a real one"
pass "the theme-set hook re-points the swapped icons to the new theme's variants"

run_icons restore
[[ -z $(find "$theme_icons" -name 'maitri-*' 2>/dev/null) ]] || fail "restore removes variant copies too"
echo ember >"$home/.local/state/maitri/current/theme.name"
theme_set_icons
[[ ! -e $state && -z $(find "$theme_icons" -type f 2>/dev/null) ]] || fail "the theme-set hook does nothing when icons aren't applied"
[[ ! -e $user_apps/code.desktop ]] || fail "the theme-set hook never swaps icons on its own"
unset maitri_path
pass "the theme-set hook is a no-op when icons aren't applied"

grep -qxE '  maitri-theme-set-icons' "$ROOT/bin/maitri-theme-set" ||
  fail "maitri-theme-set runs the icon hook with the other theme hooks"
pass "maitri-theme-set runs the icon hook"
png_header() {
  printf '\x89PNG\r\n\x1a\n\x00\x00\x00\x0dIHDR'
  printf "\\x$(printf '%02x' $(( $1 >> 24 & 255 )))\\x$(printf '%02x' $(( $1 >> 16 & 255 )))\\x$(printf '%02x' $(( $1 >> 8 & 255 )))\\x$(printf '%02x' $(( $1 & 255 )))"
  printf "\\x$(printf '%02x' $(( $2 >> 24 & 255 )))\\x$(printf '%02x' $(( $2 >> 16 & 255 )))\\x$(printf '%02x' $(( $2 >> 8 & 255 )))\\x$(printf '%02x' $(( $2 & 255 )))"
}

for icon in "$icons"/*.png "$icons"/*/*.png; do
  [[ -f $icon ]] || continue
  [[ $(od -An -tx1 -N8 "$icon" | tr -d ' \n') == "89504e470d0a1a0a" ]] || fail "every base icon is a PNG" "$icon"
  read -r width height < <(od -An -tu1 -j16 -N8 "$icon" | awk '{ print $1 * 16777216 + $2 * 65536 + $3 * 256 + $4, $5 * 16777216 + $6 * 65536 + $7 * 256 + $8 }')
  [[ $width == "$height" && " 16 22 24 32 36 48 64 72 96 128 192 256 512 " == *" $width "* ]] ||
    fail "every base icon is square at a size the hicolor theme lists" "$icon: ${width}x$height"
done
pass "every icon in default/icons and its theme folders is a square PNG at a hicolor size"

reset_fixture
maitri_path="$tmpdir/bad-pngs"
mkdir -p "$maitri_path/default"
cp -r "$icons" "$maitri_path/default/icons"
echo 'not a png' >"$maitri_path/default/icons/foot.png"
{ png_header 1024 1024; head -c 64 /dev/zero; } >"$maitri_path/default/icons/slack.png"
{ png_header 256 128; head -c 64 /dev/zero; } >"$maitri_path/default/icons/firefox.png"
run_icons set
[[ ! -e $user_apps/foot.desktop ]] || fail "set skips an icon that isn't a PNG"
grep -Fxq 'Icon=slack' "$user_apps/slack.desktop" || fail "set skips a PNG at a size the hicolor theme doesn't list"
[[ ! -e $user_apps/firefox.desktop ]] || fail "set skips a PNG that isn't square"
[[ -z $(find "$theme_icons" -path '*x/apps/*' ! -path '*[0-9]x[0-9]*/apps/*' 2>/dev/null) && ! -d $theme_icons/1024x1024 ]] ||
  fail "set never makes a size folder from a bad PNG" "$(find "$theme_icons")"
grep -Fxq 'Icon=maitri-vscode' "$user_apps/code.desktop" || fail "bad icons don't hold back the good ones"
run_icons restore
unset maitri_path
pass "set skips icons that aren't square PNGs at a hicolor size"

reset_fixture
desktop_entry "Foot" "foot --user" "foot" >"$user_apps/foot.desktop"
cp "$user_apps/foot.desktop" "$tmpdir/foot-original.desktop"
maitri_path="$tmpdir/branch"
mkdir -p "$maitri_path/default"
cp -r "$icons" "$maitri_path/default/icons"
cp "$icons/vscode.png" "$maitri_path/default/icons/foot.png"
run_icons set
grep -Fxq 'Icon=maitri-foot' "$user_apps/foot.desktop" || fail "set on the branch swaps the user launcher"
rm -rf "$maitri_path"
maitri_path="$ROOT"
run_icons set
cmp -s "$user_apps/foot.desktop" "$tmpdir/foot-original.desktop" ||
  fail "a replaced launcher whose icon left the set gets its original back" "$(cat "$user_apps/foot.desktop")"
grep -q '^foot.desktop' "$state/manifest" && fail "set forgets a replaced launcher whose icon left the set"
[[ -z $(find "$theme_icons" -name 'maitri-foot*') ]] || fail "the icon that left the set has no copy left"

maitri_path="$tmpdir/branch"
mkdir -p "$maitri_path/default"
cp -r "$icons" "$maitri_path/default/icons"
cp "$icons/vscode.png" "$maitri_path/default/icons/foot.png"
run_icons set
sed -i 's/^Exec=foot --user$/Exec=foot --edited/' "$user_apps/foot.desktop"
rm -rf "$maitri_path"
maitri_path="$ROOT"
run_icons set
grep -Fxq 'Exec=foot --edited' "$user_apps/foot.desktop" && grep -Fxq 'Icon=foot' "$user_apps/foot.desktop" ||
  fail "an edited replaced launcher whose icon left the set keeps its edit and gets its icon back" "$(cat "$user_apps/foot.desktop")"
grep -q '^foot.desktop' "$state/manifest" && fail "set forgets an edited replaced launcher whose icon left the set"
unset maitri_path
pass "a replaced launcher whose icon leaves the set after dev link and unlink goes back to its own icon"

reset_fixture
mkdir -p "$theme_icons/256x256/apps"
echo mine >"$theme_icons/256x256/apps/maitri-slack.png"
run_icons set
[[ $(<"$theme_icons/256x256/apps/maitri-slack.png") == "mine" ]] || fail "set never overwrites an icon it didn't put there"
grep -q 'maitri-slack.png' "$state/copies" && fail "set doesn't record an icon it didn't put there"
grep -q "maitri-slack.png alone: maitri didn't put it there" "$tmpdir/err" || fail "set says it left a file alone" "$(cat "$tmpdir/err")"
run_icons restore
[[ $(<"$theme_icons/256x256/apps/maitri-slack.png") == "mine" ]] || fail "restore never removes an icon set didn't put there"
rm "$theme_icons/256x256/apps/maitri-slack.png"
pass "set and restore leave alone an icon file they didn't write"

reset_fixture
run_icons set
touch -d '2000-01-01' "$theme_icons"
maitri_path="$tmpdir/touched"
mkdir -p "$maitri_path/default"
cp -r "$icons" "$maitri_path/default/icons"
printf 'new art' >>"$maitri_path/default/icons/vscode.png"
run_icons set
(( $(stat -c %Y "$theme_icons") > $(date -d '2000-01-01' +%s) )) || fail "set touches the icon theme dir when a copy changes"
touch -d '2000-01-01' "$theme_icons"
run_icons set
[[ $(stat -c %Y "$theme_icons") == "$(date -d '2000-01-01' +%s)" ]] || fail "set leaves the icon theme dir alone when nothing changes"
unset maitri_path
pass "set touches the icon theme dir only when a copy changes, so GTK rescans past a stale cache"

: >"$state/manifest"
run_icons restore
[[ -z $(find "$theme_icons" -name 'maitri-*') ]] || fail "restore with an empty manifest still removes the copies" "$(find "$theme_icons" -name 'maitri-*')"
[[ ! -e $state ]] || fail "restore with an empty manifest clears its state"
pass "restore cleans up copies left by a set that wrote no swaps"
