#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

require_command jq
require_command python3
require_command curl

test_tmp=$(mktemp -d)
server_pid=""
trap '[[ -z $server_pid ]] || kill "$server_pid" 2>/dev/null; rm -rf "$test_tmp"' EXIT

served="$test_tmp/served"
test_home="$test_tmp/home"
mkdir -p "$served/channels/stable" "$test_home"

python3 -u -m http.server 0 --bind 127.0.0.1 --directory "$served" >"$test_tmp/server.log" 2>&1 &
server_pid=$!
for _ in {1..50}; do
  port=$(sed -n 's/.* port \([0-9]*\) .*/\1/p' "$test_tmp/server.log")
  [[ -z $port ]] || break
  sleep 0.1
done
[[ -n $port ]] || fail "the test HTTP server starts" "$(cat "$test_tmp/server.log")"
base_url="http://127.0.0.1:$port"

backgrounds="$test_home/.config/maitri/backgrounds"
installed_list="$test_home/.local/state/maitri/wallpapers/installed"

sha256_of() {
  sha256sum "$1" | cut -d' ' -f1
}

publish() {
  local theme=$1 source=$2 extension=$3 sha256
  sha256=$(sha256_of "$source")
  mkdir -p "$served/themes/$theme"
  cp "$source" "$served/themes/$theme/$sha256.$extension"
  jq -nc --arg theme "$theme" --arg file "themes/$theme/$sha256.$extension" --arg sha256 "$sha256" \
    --argjson size "$(stat -c %s "$source")" '{theme: $theme, file: $file, sha256: $sha256, size: $size}'
}

write_manifest() {
  jq -s --arg release "$1" '{release: $release, files: .}' >"$served/channels/stable/manifest.json"
}

run_updater() {
  HOME="$test_home" MAITRI_WALLPAPERS_URL="${URL:-$base_url}" \
    "$ROOT/bin/maitri-update-wallpapers" >"$test_tmp/out" 2>"$test_tmp/err"
}

head -c 4096 /dev/urandom >"$test_tmp/dusk.jpg"
head -c 2048 /dev/urandom >"$test_tmp/ember.png"
dusk=$(sha256_of "$test_tmp/dusk.jpg")
ember=$(sha256_of "$test_tmp/ember.png")

{
  publish amethyst "$test_tmp/dusk.jpg" jpg
  publish ember "$test_tmp/ember.png" png
} | write_manifest v1.0.0

run_updater || fail "a clean install succeeds" "$(cat "$test_tmp/out" "$test_tmp/err")"
cmp -s "$test_tmp/dusk.jpg" "$backgrounds/amethyst/$dusk.jpg" ||
  fail "a verified wallpaper is installed under the theme's user backgrounds"
cmp -s "$test_tmp/ember.png" "$backgrounds/ember/$ember.png" ||
  fail "every theme in the manifest gets its wallpapers"
pass "verified wallpapers install into ~/.config/maitri/backgrounds/<theme>/"

grep -qxF "$dusk amethyst/$dusk.jpg" "$installed_list" && grep -qxF "$ember ember/$ember.png" "$installed_list" ||
  fail "installed wallpapers are recorded" "$(cat "$installed_list" 2>/dev/null)"
[[ $(<"$test_home/.local/state/maitri/wallpapers/release") == "v1.0.0" ]] ||
  fail "the manifest's release is recorded"
pass "the install is recorded in the state directory"

rm "$served/themes/amethyst/$dusk.jpg" "$served/themes/ember/$ember.png"
run_updater || fail "a re-run succeeds" "$(cat "$test_tmp/out" "$test_tmp/err")"
grep -q "up to date" "$test_tmp/out" || fail "a re-run reports it is up to date" "$(cat "$test_tmp/out")"
(( $(wc -l <"$installed_list") == 2 )) || fail "a re-run does not record anything twice" "$(cat "$installed_list")"
pass "a re-run downloads nothing and records nothing twice"

rm "$backgrounds/amethyst/$dusk.jpg"
run_updater || fail "a re-run after deleting a wallpaper succeeds"
[[ ! -e $backgrounds/amethyst/$dusk.jpg ]] || fail "a deleted wallpaper stays deleted"
pass "a wallpaper the user deleted is not fetched again"

head -c 4096 /dev/urandom >"$test_tmp/good.jpg"
head -c 4096 /dev/urandom >"$test_tmp/tampered.jpg"
head -c 4096 /dev/urandom >"$test_tmp/claimed.jpg"
good=$(sha256_of "$test_tmp/good.jpg")
claimed=$(sha256_of "$test_tmp/claimed.jpg")
cp "$test_tmp/tampered.jpg" "$served/themes/amethyst/$claimed.jpg"
{
  publish amethyst "$test_tmp/good.jpg" jpg
  jq -nc --arg file "themes/amethyst/$claimed.jpg" --arg sha256 "$claimed" \
    '{theme: "amethyst", file: $file, sha256: $sha256, size: 4096}'
  jq -nc --arg sha256 "$good" '{theme: "amethyst", file: "themes/amethyst/../../evil.jpg", sha256: $sha256, size: 4096}'
  jq -nc --arg sha256 "$good" '{theme: "ember", file: ("themes/amethyst/" + $sha256 + ".jpg"), sha256: $sha256, size: 4096}'
} | write_manifest v1.1.0

if run_updater; then
  fail "a manifest with a bad checksum reports a failure"
fi
grep -q "rejected themes/amethyst/$claimed.jpg (sha256 mismatch)" "$test_tmp/err" ||
  fail "a checksum mismatch is reported" "$(cat "$test_tmp/err")"
[[ ! -e $backgrounds/amethyst/$claimed.jpg ]] || fail "a file that fails its checksum is never installed"
grep -q "$claimed" "$installed_list" && fail "a rejected file is not recorded as installed"
pass "a file whose sha256 does not match is rejected, reported and not installed"

grep -q 'rejected themes/amethyst/../../evil.jpg (invalid file name)' "$test_tmp/err" ||
  fail "a path outside themes/<theme>/ is rejected" "$(cat "$test_tmp/err")"
grep -q "rejected themes/amethyst/$good.jpg (name does not match" "$test_tmp/err" ||
  fail "a file filed under another theme is rejected" "$(cat "$test_tmp/err")"
[[ ! -e $backgrounds/ember/$good.jpg ]] || fail "a file filed under another theme is not installed"
pass "entries whose name does not fit the contract are rejected"

cmp -s "$test_tmp/good.jpg" "$backgrounds/amethyst/$good.jpg" ||
  fail "the valid files next to a rejected one still install"
pass "a rejected file does not hold back the valid ones"

cp -a "$test_home" "$test_tmp/home-before"
URL="http://127.0.0.1:1" run_updater || fail "an offline run exits 0" "$(cat "$test_tmp/err")"
(( $(wc -l <"$test_tmp/out") <= 3 )) && grep -q "nothing changed" "$test_tmp/out" ||
  fail "an offline run says so in one line" "$(cat "$test_tmp/out")"
diff -r "$test_tmp/home-before" "$test_home" >/dev/null || fail "an offline run changes nothing"
pass "offline, the updater exits 0 and changes nothing"

URL="$base_url/missing" run_updater || fail "a missing manifest exits 0"
grep -q "nothing changed" "$test_tmp/out" || fail "a missing manifest is reported"
mkdir -p "$served/portal/channels/stable"
echo '<html>captive portal</html>' >"$served/portal/channels/stable/manifest.json"
URL="$base_url/portal" run_updater || fail "a manifest that is not JSON exits 0"
diff -r "$test_tmp/home-before" "$test_home" >/dev/null || fail "an unreadable manifest changes nothing"
pass "a missing or unreadable manifest exits 0 and changes nothing"

{
  publish amethyst "$test_tmp/good.jpg" jpg
  publish ember "$test_tmp/ember.png" png
} | write_manifest v1.1.1

staging="$test_tmp/staging"
mkdir -p "$staging/amethyst" "$staging/garnet"
head -c 3000 /dev/urandom >"$staging/amethyst/New Dawn.JPEG"
cp "$test_tmp/good.jpg" "$staging/amethyst/good.jpg"
head -c 1000 /dev/urandom >"$staging/garnet/glow.webp"
new_dawn=$(sha256_of "$staging/amethyst/New Dawn.JPEG")
glow=$(sha256_of "$staging/garnet/glow.webp")

MAITRI_WALLPAPERS_URL="$base_url" "$ROOT/tools/wallpapers-upload.sh" --dry-run --from "$staging" v1.2.0 \
  >"$test_tmp/manifest.json" 2>"$test_tmp/plan" ||
  fail "a dry run of the upload succeeds" "$(cat "$test_tmp/plan")"
grep -qx "would upload themes/amethyst/$new_dawn.jpg" "$test_tmp/plan" &&
  grep -qx "would upload themes/garnet/$glow.webp" "$test_tmp/plan" &&
  grep -q "^already published themes/amethyst/$good.jpg" "$test_tmp/plan" &&
  grep -qx "would upload releases/v1.2.0/manifest.json" "$test_tmp/plan" &&
  grep -qx "would upload channels/stable/manifest.json" "$test_tmp/plan" ||
  fail "a dry run says what it would upload and skips what is already there" "$(cat "$test_tmp/plan")"
pass "a dry run of the upload plans only the new files and both manifests"

[[ $(jq -r '.release' "$test_tmp/manifest.json") == "v1.2.0" ]] ||
  fail "the new manifest carries the release tag"
[[ $(jq -r '.files[].file' "$test_tmp/manifest.json" | sort -u | wc -l) == $(jq '.files | length' "$test_tmp/manifest.json") ]] ||
  fail "the new manifest lists each file once"
jq -e --arg file "themes/garnet/$glow.webp" --arg sha256 "$glow" \
  '.files | any(.file == $file and .sha256 == $sha256 and .size == 1000 and .theme == "garnet")' \
  "$test_tmp/manifest.json" >/dev/null || fail "the new manifest lists the staged files" "$(cat "$test_tmp/manifest.json")"
jq -e --arg file "themes/ember/$ember.png" '.files | any(.file == $file)' "$test_tmp/manifest.json" >/dev/null ||
  fail "the new manifest carries the published wallpapers forward"
pass "the upload builds a manifest from the published one plus the staged files"

mkdir -p "$staging/nosuchtheme"
cp "$test_tmp/good.jpg" "$staging/nosuchtheme/"
if MAITRI_WALLPAPERS_URL="$base_url" "$ROOT/tools/wallpapers-upload.sh" --dry-run --from "$staging" v1.2.0 \
  >/dev/null 2>"$test_tmp/plan"; then
  fail "the upload refuses a directory that is not a maitri theme"
fi
rm -r "$staging/nosuchtheme"
pass "the upload refuses a directory that is not a maitri theme"

cp "$staging/amethyst/New Dawn.JPEG" "$served/themes/amethyst/$new_dawn.jpg"
mkdir -p "$served/themes/garnet"
cp "$staging/garnet/glow.webp" "$served/themes/garnet/$glow.webp"
cp "$test_tmp/manifest.json" "$served/channels/stable/manifest.json"
run_updater || fail "the published manifest installs" "$(cat "$test_tmp/out" "$test_tmp/err")"
cmp -s "$staging/amethyst/New Dawn.JPEG" "$backgrounds/amethyst/$new_dawn.jpg" &&
  cmp -s "$staging/garnet/glow.webp" "$backgrounds/garnet/$glow.webp" ||
  fail "a manifest from the uploader round-trips through the updater"
[[ ! -e $backgrounds/amethyst/$dusk.jpg ]] || fail "the round trip respects a deleted wallpaper"
pass "a manifest from the uploader round-trips through the updater"
