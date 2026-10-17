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

cat >"$test_tmp/server.py" <<'PY'
import http.server, os, sys

class Handler(http.server.SimpleHTTPRequestHandler):
    protocol_version = "HTTP/1.0"

    def do_GET(self):
        if not (self.path.startswith("/stream/themes/") and self.path.endswith(".jpg")):
            return super().do_GET()
        self.send_response(200)
        self.end_headers()
        sent = 0
        try:
            while sent < 300 * 1024 * 1024:
                self.wfile.write(b"\0" * 65536)
                sent += 65536
        except OSError:
            pass
        with open(os.environ["STREAM_LOG"], "a") as log:
            log.write(f"{sent}\n")

server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), lambda *a: Handler(*a, directory=sys.argv[1]))
print(f"port {server.server_address[1]}", flush=True)
server.serve_forever()
PY
STREAM_LOG="$test_tmp/stream.log" python3 -I "$test_tmp/server.py" "$served" >"$test_tmp/server.log" 2>&1 &
server_pid=$!
for _ in {1..50}; do
  port=$(sed -n 's/^port \([0-9]*\)$/\1/p' "$test_tmp/server.log")
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
  mkdir -p "${2:-$served}/channels/stable"
  jq -s --arg release "$1" '{release: $release, files: .}' >"${2:-$served}/channels/stable/manifest.json"
}

image() {
  case $1 in
    jpg) printf '\xff\xd8\xff\xe0' ;;
    png) printf '\x89PNG\r\n\x1a\n' ;;
    webp) printf 'RIFF\x00\x00\x00\x00WEBP' ;;
  esac >"$3"
  head -c "$2" /dev/urandom >>"$3"
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

image jpg 4092 "$test_tmp/good.jpg"
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
image jpg 2996 "$staging/amethyst/New Dawn.JPEG"
cp "$test_tmp/good.jpg" "$staging/amethyst/good.jpg"
image webp 988 "$staging/garnet/glow.webp"
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

oversized=$(head -c 5120 /dev/urandom | sha256sum | cut -d' ' -f1)
mkdir -p "$served/huge/themes/amethyst" "$served/stream/themes/amethyst"
printf '\xff\xd8\xff' >"$served/huge/themes/amethyst/$oversized.jpg"
truncate -s 300M "$served/huge/themes/amethyst/$oversized.jpg"
jq -nc --arg sha256 "$oversized" '{theme: "amethyst", file: ("themes/amethyst/" + $sha256 + ".jpg"), sha256: $sha256, size: 5120}' |
  write_manifest v9.0.0 "$served/huge"

if (ulimit -f 20480; URL="$base_url/huge" run_updater); then
  fail "a file far larger than its manifest size reports a failure"
fi
grep -q "rejected themes/amethyst/$oversized.jpg (download failed)" "$test_tmp/err" ||
  fail "a file larger than its manifest size is rejected before it is written" "$(cat "$test_tmp/out" "$test_tmp/err")"
[[ ! -e $backgrounds/amethyst/$oversized.jpg ]] || fail "an oversized file is not installed"
grep -q "1 rejected, nothing installed" "$test_tmp/out" || fail "a run with only rejections says so" "$(cat "$test_tmp/out")"
[[ $(<"$test_home/.local/state/maitri/wallpapers/release") == "v1.2.0" ]] ||
  fail "a run with only rejections does not record the release"
pass "a 300 MB body for a 5 KB entry is refused up front and nothing large lands on disk"

{
  jq -nc --arg sha256 "$oversized" '{theme: "amethyst", file: ("themes/amethyst/" + $sha256 + ".jpg"), sha256: $sha256, size: 5120}'
  jq -nc --arg sha256 "$dusk" '{theme: "amethyst", file: ("themes/amethyst/" + $sha256 + ".jpg"), sha256: $sha256, size: 67108865}'
} | write_manifest v9.0.0 "$served/stream"
: >"$test_tmp/stream.log"
if (ulimit -f 20480; URL="$base_url/stream" run_updater); then
  fail "a body with no length that runs past the manifest size reports a failure"
fi
grep -q "rejected themes/amethyst/$oversized.jpg (download failed)" "$test_tmp/err" ||
  fail "a body with no length is cut off at the manifest size" "$(cat "$test_tmp/out" "$test_tmp/err")"
for _ in {1..50}; do
  [[ ! -s $test_tmp/stream.log ]] || break
  sleep 0.1
done
(( $(<"$test_tmp/stream.log") < 16 * 1024 * 1024 )) ||
  fail "the download stops soon after the manifest size" "$(cat "$test_tmp/stream.log") bytes sent"
grep -q "rejected themes/amethyst/$dusk.jpg (larger than 67108864 bytes)" "$test_tmp/err" ||
  fail "an entry declaring more than 64 MiB is rejected" "$(cat "$test_tmp/err")"
pass "a body with no length is cut off at the manifest size, and entries over 64 MiB are refused"

mkdir -p "$served/bigmanifest/channels/stable"
truncate -s 2M "$served/bigmanifest/channels/stable/manifest.json"
URL="$base_url/bigmanifest" run_updater || fail "a manifest over 1 MiB exits 0"
grep -q "could not be fetched, nothing changed" "$test_tmp/out" || fail "a manifest over 1 MiB is not read" "$(cat "$test_tmp/out")"
pass "a manifest over 1 MiB is refused"

upload() {
  MAITRI_WALLPAPERS_URL="$base_url" "$ROOT/tools/wallpapers-upload.sh" "$@" >"$test_tmp/manifest.json" 2>"$test_tmp/plan"
}

tar -cf "$test_tmp/wallpapers.tar" -C "$staging" --exclude README.md .
upload --dry-run --from "$staging" v1.2.0 || fail "a dry run from the staging directory succeeds" "$(cat "$test_tmp/plan")"
cp "$test_tmp/manifest.json" "$test_tmp/from-dir.json"
upload --dry-run --tar "$test_tmp/wallpapers.tar" v1.2.0 || fail "a dry run from wallpapers.tar succeeds" "$(cat "$test_tmp/plan")"
[[ $(jq -cS . "$test_tmp/manifest.json") == "$(jq -cS . "$test_tmp/from-dir.json")" ]] ||
  fail "wallpapers.tar gives the same manifest as the staging directory it was packed from" "$(diff <(jq -S . "$test_tmp/from-dir.json") <(jq -S . "$test_tmp/manifest.json"))"
pass "the uploader reads wallpapers.tar packed the way the release docs say"

refuse_tar() {
  local name=$1 expected=$2
  if upload --dry-run --tar "$test_tmp/$name.tar" v1.2.0; then
    fail "the uploader refuses $name"
  fi
  grep -q "$expected" "$test_tmp/plan" || fail "the uploader says why it refuses $name" "$(cat "$test_tmp/plan")"
  ! grep -q "would upload" "$test_tmp/plan" || fail "a refused tar uploads nothing"
}

bad="$test_tmp/bad"
mkdir -p "$bad/amethyst"
ln -s /etc/passwd "$bad/amethyst/link.jpg"
tar -cf "$test_tmp/symlink.tar" -C "$bad" .
refuse_tar symlink "only directories and plain files"
rm "$bad/amethyst/link.jpg"

head -c 4096 /dev/urandom >"$bad/amethyst/fake.jpg"
tar -cf "$test_tmp/not-an-image.tar" -C "$bad" .
refuse_tar not-an-image "not a jpg image"
rm "$bad/amethyst/fake.jpg"

image png 16 "$bad/amethyst/huge.png"
truncate -s 65M "$bad/amethyst/huge.png"
tar -cf "$test_tmp/too-big.tar" -S -C "$bad" .
refuse_tar too-big "wallpapers are at most 67108864"
rm "$bad/amethyst/huge.png"

image jpg 64 "$bad/loose.jpg"
tar -cf "$test_tmp/loose.tar" -C "$bad" .
refuse_tar loose "only theme directories go at the top"
rm "$bad/loose.jpg"

python3 -I -c 'import sys, tarfile, io
with tarfile.open(sys.argv[1], "w") as t:
    data = b"\xff\xd8\xff" + bytes(64)
    info = tarfile.TarInfo("amethyst/../../escaped.jpg")
    info.size = len(data)
    t.addfile(info, io.BytesIO(data))' "$test_tmp/escape.tar"
refuse_tar escape "could not be unpacked"
[[ ! -e $test_tmp/escaped.jpg && ! -e ${TMPDIR:-/tmp}/escaped.jpg ]] || fail "a member with .. is never written outside the staging directory"
pass "the uploader refuses symlinks, non-images, files over 64 MiB, loose files and .. in wallpapers.tar"

fake_bin="$test_tmp/bin"
mkdir -p "$fake_bin"
cat >"$fake_bin/aws" <<'SH'
#!/bin/bash
operation=$4
shift 4
out=""
while (( $# > 0 )); do
  case $1 in
    --bucket) shift ;;
    --key) key=$2; shift ;;
    --body) body=$2; shift ;;
    --content-type) type=$2; shift ;;
    --cache-control) cache=$2; shift ;;
    *) out=$1 ;;
  esac
  shift
done
case $operation in
  get-object)
    [[ -f $FAKE_BUCKET/$key ]] || { echo "An error occurred (NoSuchKey) when calling the GetObject operation" >&2; exit 254; }
    cp "$FAKE_BUCKET/$key" "$out"
    ;;
  head-object)
    [[ -f $FAKE_BUCKET/$key ]] || { echo "An error occurred (404) when calling the HeadObject operation: Not Found" >&2; exit 254; }
    ;;
  put-object)
    mkdir -p "$(dirname "$FAKE_BUCKET/$key")"
    cp "$body" "$FAKE_BUCKET/$key"
    echo "$key|$type|$cache" >>"$FAKE_BUCKET.log"
    ;;
esac
SH
chmod +x "$fake_bin/aws"

publish_release() {
  PATH="$fake_bin:$PATH" FAKE_BUCKET="$served" R2_ACCESS_KEY_ID=test R2_SECRET_ACCESS_KEY=test R2_ENDPOINT=http://r2.invalid \
    upload "$@"
}

: >"$served.log"
staging2="$test_tmp/staging2"
mkdir -p "$staging2/harbor"
image png 2040 "$staging2/harbor/tide.png"
tide=$(sha256_of "$staging2/harbor/tide.png")
cp "$test_tmp/good.jpg" "$staging2/harbor/good.jpg"
tar -cf "$test_tmp/wallpapers.tar" -C "$staging2" .
publish_release --tar "$test_tmp/wallpapers.tar" v1.3.0 || fail "a release with wallpapers.tar publishes" "$(cat "$test_tmp/plan")"
grep -qx "themes/harbor/$tide.png|image/png|public, max-age=31536000, immutable" "$served.log" ||
  fail "a new wallpaper is uploaded under its hash with its type and a year's cache" "$(cat "$served.log")"
grep -qx "releases/v1.3.0/manifest.json|application/json|public, max-age=60" "$served.log" &&
  grep -qx "channels/stable/manifest.json|application/json|public, max-age=60" "$served.log" ||
  fail "the release and stable manifests are written with a short cache" "$(cat "$served.log")"
[[ $(grep -c '^themes/' "$served.log") == 2 ]] || fail "only files not yet in the bucket are uploaded" "$(cat "$served.log")"
[[ $(jq -r '.release' "$served/channels/stable/manifest.json") == "v1.3.0" ]] || fail "stable moves to the release"
run_updater || fail "a published release installs" "$(cat "$test_tmp/out" "$test_tmp/err")"
cmp -s "$staging2/harbor/tide.png" "$backgrounds/harbor/$tide.png" || fail "the published wallpaper installs"
pass "a release with wallpapers.tar uploads content-addressed files, both manifests, and installs"

image webp 500 "$staging2/harbor/rc.webp"
tar -cf "$test_tmp/wallpapers.tar" -C "$staging2" .
publish_release --tar "$test_tmp/wallpapers.tar" v1.4.0-rc.1 || fail "a prerelease publishes" "$(cat "$test_tmp/plan")"
[[ -f $served/releases/v1.4.0-rc.1/manifest.json ]] || fail "a prerelease writes its own manifest"
[[ $(jq -r '.release' "$served/channels/stable/manifest.json") == "v1.3.0" ]] || fail "a prerelease tag leaves stable alone"
publish_release --prerelease --tar "$test_tmp/wallpapers.tar" v1.4.0 || fail "a release marked prerelease publishes" "$(cat "$test_tmp/plan")"
[[ $(jq -r '.release' "$served/channels/stable/manifest.json") == "v1.3.0" ]] || fail "--prerelease leaves stable alone"
pass "a prerelease writes only releases/<tag>/manifest.json"

rm "$staging2/harbor/rc.webp"
empty="$test_tmp/empty"
mkdir -p "$empty"
publish_release --from "$empty" v1.5.0 || fail "a release without wallpapers publishes" "$(cat "$test_tmp/plan")"
[[ $(jq -cS '.files' "$served/releases/v1.5.0/manifest.json") == "$(jq -cS '.files' "$served/releases/v1.3.0/manifest.json")" ]] ||
  fail "a release without wallpapers carries the stable ones forward"
image jpg 700 "$staging2/harbor/late.jpg"
late=$(sha256_of "$staging2/harbor/late.jpg")
tar -cf "$test_tmp/wallpapers.tar" -C "$staging2" .
publish_release --tar "$test_tmp/wallpapers.tar" v1.5.0 || fail "wallpapers attached after the release publish" "$(cat "$test_tmp/plan")"
jq -e --arg file "themes/harbor/$late.jpg" '.files | any(.file == $file)' "$served/releases/v1.5.0/manifest.json" >/dev/null &&
  jq -e --arg file "themes/harbor/$late.jpg" '.files | any(.file == $file)' "$served/channels/stable/manifest.json" >/dev/null ||
  fail "wallpapers attached after the release reach its manifest and stable"
pass "wallpapers attached to a release after it was published can be published by a rerun"

publish_release --tar "$test_tmp/wallpapers.tar" v1.5.0 || fail "an identical rerun succeeds" "$(cat "$test_tmp/plan")"
grep -qx "already published releases/v1.5.0/manifest.json" "$test_tmp/plan" ||
  fail "an identical rerun leaves the release manifest as it is" "$(cat "$test_tmp/plan")"
pass "an identical rerun publishes nothing new"

jq --arg sha256 "$oversized" '.files += [{theme: "amethyst", file: ("themes/amethyst/" + $sha256 + ".jpg"), sha256: $sha256, size: 5120}]' \
  "$served/releases/v1.5.0/manifest.json" >"$test_tmp/grown.json"
cp "$test_tmp/grown.json" "$served/releases/v1.5.0/manifest.json"
: >"$served.log"
if publish_release --tar "$test_tmp/wallpapers.tar" v1.5.0; then
  fail "a rerun that would drop a published file is refused"
fi
grep -q "would drop" "$test_tmp/plan" || fail "the uploader says a rerun would drop files" "$(cat "$test_tmp/plan")"
[[ ! -s $served.log ]] || fail "a refused rerun uploads nothing" "$(cat "$served.log")"
pass "a rerun never drops files from a published release's manifest, and checks before uploading"

stable_before=$(<"$served/channels/stable/manifest.json")
for name in $'a\nb.jpg' 'a\b.jpg' $'a\tb.jpg'; do
  odd="$test_tmp/odd"
  rm -rf "$odd"
  mkdir -p "$odd/amethyst"
  image jpg 64 "$odd/amethyst/$name"
  tar -cf "$test_tmp/odd.tar" -C "$odd" .
  : >"$served.log"
  if publish_release --tar "$test_tmp/odd.tar" v1.6.0; then
    fail "a wallpaper whose name holds a control character or backslash is refused"
  fi
  grep -q "file names can't hold control characters or backslashes" "$test_tmp/plan" ||
    fail "the uploader says why it refuses an odd file name" "$(cat "$test_tmp/plan")"
  [[ ! -s $served.log ]] || fail "an odd file name uploads nothing" "$(cat "$served.log")"
done
[[ $(<"$served/channels/stable/manifest.json") == "$stable_before" ]] || fail "an odd file name leaves stable alone"
grep -rq '\\' "$served/channels" "$served/releases" && fail "no manifest ever carries a backslash"
pass "file names with a newline, backslash or other control character are refused before anything uploads"

cp "$served/channels/stable/manifest.json" "$test_tmp/stable-before.json"
python3 -I -c '
import hashlib, json, sys
manifest = json.load(open(sys.argv[1]))
for i in range(6500):
    sha256 = hashlib.sha256(str(i).encode()).hexdigest()
    manifest["files"].append({"theme": "amethyst", "file": f"themes/amethyst/{sha256}.jpg", "sha256": sha256, "size": i})
json.dump(manifest, open(sys.argv[1], "w"))' "$served/channels/stable/manifest.json"
(( $(stat -c %s "$served/channels/stable/manifest.json") > 1048576 )) || fail "the test builds a stable manifest over 1 MiB"
: >"$served.log"
if publish_release --tar "$test_tmp/wallpapers.tar" v1.6.0; then
  fail "a manifest over 1 MiB is refused"
fi
grep -q "more than maitri-update-wallpapers reads; nothing was uploaded" "$test_tmp/plan" ||
  fail "the uploader says the manifest would be too big" "$(cat "$test_tmp/plan")"
[[ ! -s $served.log ]] || fail "a manifest that is too big uploads nothing" "$(cat "$served.log")"
cp "$test_tmp/stable-before.json" "$served/channels/stable/manifest.json"
pass "the uploader validates the whole manifest, size included, before anything uploads"
