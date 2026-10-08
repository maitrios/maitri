#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

plymouth="$test_dir/plymouth"
sed "s|/usr/share/plymouth|$plymouth|" "$ROOT/migrations/1791359597.sh" >"$test_dir/migration.sh"

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

[[ $1 == "limine-mkinitcpio" ]] && (( HAS_LIMINE ))
STUB
for command in limine-mkinitcpio mkinitcpio; do
  cat >"$test_dir/bin/$command" <<STUB
#!/bin/bash

echo "$command\${*:+ \$*}" >>"\$CALLS"
exit \${REBUILD_STATUS:-0}
STUB
done
chmod +x "$test_dir/bin/"*

export CALLS="$test_dir/calls"
home="$test_dir/home"
about="$home/.config/maitri/branding/about.txt"

run_migration() {
  : >"$CALLS"
  HOME="$home" MAITRI_PATH="$ROOT" PATH="$test_dir/bin:$PATH" GROUPS_LIST="${GROUPS_LIST:-beyera wheel}" \
    HAS_LIMINE="${HAS_LIMINE:-1}" STALE="${STALE-/boot/EFI/Linux/maitri_linux.efi}" \
    bash -euo pipefail "$test_dir/migration.sh" >/dev/null
}

reset() {
  rm -rf "$home" "$plymouth"
  mkdir -p "$(dirname "$about")" "$plymouth/themes/maitri"
  cp "$ROOT/test/shell.d/fixtures/brand/shipped-icon.txt" "$about"
  : >"$plymouth/themes/maitri/logo.png"
}

reset
run_migration
cmp -s "$about" "$ROOT/icon.txt" || fail "the shipped About heart is replaced with the open heart"
pass "the shipped About heart is replaced with the open heart"
grep -qx 'limine-mkinitcpio' "$CALLS" || fail "a stale boot image is rebuilt with limine-mkinitcpio" "$(cat "$CALLS")"
pass "a stale boot image is rebuilt with limine-mkinitcpio"

reset
printf 'my own art\n' >"$about"
HAS_LIMINE=0 run_migration
[[ $(cat "$about") == "my own art" ]] || fail "customized About art is left alone"
grep -qx 'mkinitcpio -P' "$CALLS" || fail "without limine the initramfs is rebuilt with mkinitcpio -P" "$(cat "$CALLS")"
pass "customized About art stays, and plain mkinitcpio rebuilds without limine"

reset
STALE="" run_migration
! grep -q mkinitcpio "$CALLS" || fail "boot images newer than the logo are not rebuilt again" "$(cat "$CALLS")"
pass "boot images newer than the logo are not rebuilt again"

reset
GROUPS_LIST="guest users" run_migration
[[ ! -s $CALLS ]] || fail "a user outside wheel is never asked for sudo" "$(cat "$CALLS")"
pass "a user outside wheel is never asked for sudo"

reset
rm "$plymouth/themes/maitri/logo.png"
run_migration
[[ ! -s $CALLS ]] || fail "a machine without the Plymouth theme has nothing to rebuild"
pass "a machine without the Plymouth theme has nothing to rebuild"

reset
: >"$CALLS"
if HOME="$home" MAITRI_PATH="$ROOT" PATH="$test_dir/bin:$PATH" GROUPS_LIST="wheel" HAS_LIMINE=1 \
  STALE=/boot/EFI/Linux/maitri_linux.efi REBUILD_STATUS=1 bash -euo pipefail "$test_dir/migration.sh" >/dev/null 2>&1; then
  fail "a failed rebuild leaves the migration pending"
fi
pass "a failed rebuild leaves the migration pending"

rm -rf "$home"
mkdir -p "$home"
run_migration
[[ ! -e $about ]] || fail "a user without About art gets none"
pass "a user without About art gets none"
