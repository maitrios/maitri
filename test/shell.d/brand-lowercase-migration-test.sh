#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

plymouth="$test_dir/plymouth"
sed "s|/usr/share/plymouth|$plymouth|" "$ROOT/migrations/1792245436.sh" >"$test_dir/migration.sh"

mkdir -p "$test_dir/bin"
cat >"$test_dir/bin/sudo" <<'STUB'
#!/bin/bash

echo "sudo $*" >>"$CALLS"
"$@"
STUB
cat >"$test_dir/bin/find" <<'STUB'
#!/bin/bash

[[ -n ${STALE:-} ]] && echo "$STALE"
exit 0
STUB
cat >"$test_dir/bin/id" <<'STUB'
#!/bin/bash

echo "$GROUPS_LIST"
STUB
cat >"$test_dir/bin/maitri-cmd-present" <<'STUB'
#!/bin/bash

[[ $1 == "limine-mkinitcpio" ]]
STUB
cat >"$test_dir/bin/limine-mkinitcpio" <<'STUB'
#!/bin/bash

echo "limine-mkinitcpio" >>"$CALLS"
STUB
chmod +x "$test_dir/bin/"*

export CALLS="$test_dir/calls"
home="$test_dir/home"
branding="$home/.config/maitri/branding"

run_migration() {
  : >"$CALLS"
  HOME="$home" MAITRI_PATH="$ROOT" PATH="$test_dir/bin:$PATH" GROUPS_LIST="${GROUPS_LIST:-beyera wheel}" \
    STALE="${STALE-/boot/EFI/Linux/maitri_linux.efi}" bash -euo pipefail "$test_dir/migration.sh" >/dev/null
}

reset() {
  rm -rf "$home" "$plymouth"
  mkdir -p "$branding" "$plymouth/themes/maitri"
  cp "$ROOT/test/shell.d/fixtures/brand/shipped-open-heart.txt" "$branding/about.txt"
  cp "$ROOT/test/shell.d/fixtures/brand/shipped-block-wordmark.txt" "$branding/screensaver.txt"
  : >"$plymouth/themes/maitri/logo.png"
}

reset
run_migration
cmp -s "$branding/about.txt" "$ROOT/icon.txt" || fail "the shipped About heart is replaced with the loop heart"
pass "the shipped About heart is replaced with the loop heart"
cmp -s "$branding/screensaver.txt" "$ROOT/screensaver.txt" || fail "the shipped screensaver wordmark is replaced with the heart and lowercase wordmark"
pass "the shipped screensaver wordmark is replaced with the heart and lowercase wordmark"
grep -qx 'limine-mkinitcpio' "$CALLS" || fail "a stale boot image is rebuilt" "$(cat "$CALLS")"
pass "a stale boot image is rebuilt"

reset
printf 'my own art\n' >"$branding/about.txt"
printf 'my own words\n' >"$branding/screensaver.txt"
STALE="" run_migration
[[ $(cat "$branding/about.txt") == "my own art" ]] || fail "customized About art is left alone"
[[ $(cat "$branding/screensaver.txt") == "my own words" ]] || fail "a customized screensaver is left alone"
! grep -q mkinitcpio "$CALLS" || fail "boot images newer than the logo are not rebuilt again" "$(cat "$CALLS")"
pass "customized branding stays, and fresh boot images are not rebuilt"

reset
GROUPS_LIST="guest users" run_migration
[[ ! -s $CALLS ]] || fail "a user outside wheel is never asked for sudo" "$(cat "$CALLS")"
pass "a user outside wheel is never asked for sudo"

rm -rf "$home"
mkdir -p "$home"
run_migration
[[ ! -e $branding ]] || fail "a user without branding files gets none"
pass "a user without branding files gets none"
