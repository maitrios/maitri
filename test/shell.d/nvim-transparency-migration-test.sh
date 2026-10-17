#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

migration=$(grep -rl 'Let Neovim floats keep their depth' "$ROOT/migrations" | head -n 1 || true)
[[ -n $migration ]] || fail "Neovim float transparency migration exists"

shipped="$SHELL_TEST_DIR/fixtures/nvim-transparency/shipped.lua"
current_sha256=91bfa0b739b9bda9a48db6120612ecb11567ae190167540f0ccc3bd1035612b7

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

case_home() {
  local home="$test_tmp/$1"
  mkdir -p "$home/.config/nvim/plugin/after"
  printf '%s' "$home"
}

run_migration() {
  local home="$1"
  HOME="$home" bash -euo pipefail "$migration" >/dev/null 2>"$home/stderr"
}

sha256_of() {
  sha256sum "$1" | cut -d' ' -f1
}

home=$(case_home shipped)
target="$home/.config/nvim/plugin/after/transparency.lua"
cp "$shipped" "$target"
chmod 0640 "$target"
run_migration "$home" || fail "the migration updates a shipped copy"
[[ $(sha256_of "$target") == "$current_sha256" ]] || fail "a shipped copy becomes the current shipped list" "$(cat "$target")"
! grep -Eq '"(NormalFloat|FloatBorder|Pmenu)"' "$target" || fail "NormalFloat, FloatBorder and Pmenu leave the list"
[[ $(stat -c %a "$target") == 640 ]] || fail "the update keeps the file mode"
[[ ! -s $home/stderr ]] || fail "a shipped copy updates quietly" "$(cat "$home/stderr")"
[[ -z $(find "$home/.config/nvim/plugin/after" -name 'transparency.lua.*') ]] || fail "the update leaves no temp file"
pass "the migration updates a shipped transparency.lua to the current list"

run_migration "$home" || fail "the migration reruns over an updated copy"
[[ $(sha256_of "$target") == "$current_sha256" && ! -s $home/stderr ]] ||
  fail "an already updated copy is left alone quietly"
pass "the migration leaves an already updated copy alone"

home=$(case_home edited)
target="$home/.config/nvim/plugin/after/transparency.lua"
{ cat "$shipped"; printf '%s\n' '-- mine'; } >"$target"
before=$(sha256_of "$target")
run_migration "$home" || fail "the migration exits cleanly over an edited copy"
[[ $(sha256_of "$target") == "$before" ]] || fail "an edited copy is left untouched"
(( $(wc -l <"$home/stderr") == 1 )) || fail "an edited copy gets a one-line notice" "$(cat "$home/stderr")"
grep -Fq "$target" "$home/stderr" || fail "the notice names the file" "$(cat "$home/stderr")"
pass "the migration leaves an edited copy untouched with a notice"

home=$(case_home linked)
target="$home/.config/nvim/plugin/after/transparency.lua"
cp "$shipped" "$home/dotfile.lua"
ln -s "$home/dotfile.lua" "$target"
run_migration "$home" || fail "the migration exits cleanly over a symlinked copy"
[[ -L $target && $(sha256_of "$home/dotfile.lua") == "$(sha256_of "$shipped")" ]] ||
  fail "a symlinked copy and its target are left untouched"
pass "the migration leaves a symlinked copy untouched"

home=$(case_home missing)
run_migration "$home" || fail "the migration exits cleanly without the file"
[[ ! -e $home/.config/nvim/plugin/after/transparency.lua && ! -s $home/stderr ]] ||
  fail "a missing file stays missing"
pass "the migration is a no-op when transparency.lua is missing"
