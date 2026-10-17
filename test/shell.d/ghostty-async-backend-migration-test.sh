#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

migration="$ROOT/migrations/1792254615.sh"
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

home="$test_dir/home"
config="$home/.config/ghostty/config"

run_migration() {
  HOME="$home" MAITRI_PATH="$ROOT" bash -euo pipefail "$migration" >/dev/null
}

grep -qx "async-backend = io_uring" "$ROOT/config/ghostty/config" || fail "the shipped ghostty config uses io_uring"
pass "the shipped ghostty config uses io_uring"

mkdir -p "${config%/*}"
cat >"$config" <<'CONF'
mouse-scroll-multiplier = 0.95

# Fix general slowness on hyprland (https://github.com/ghostty-org/ghostty/discussions/3224)
async-backend = epoll
CONF
expected=$(printf 'mouse-scroll-multiplier = 0.95\n\n'; tail -n 3 "$ROOT/config/ghostty/config")
run_migration
[[ $(<"$config") == "$expected" ]] || fail "the previously shipped lines become the current ones" "$(cat "$config")"
run_migration
[[ $(<"$config") == "$expected" ]] || fail "a second run changes nothing"
pass "the previously shipped config moves to io_uring, once"

printf 'font-size = 12\nasync-backend = auto\n' >"$config"
run_migration
[[ $(<"$config") == $'font-size = 12\nasync-backend = auto' ]] || fail "a backend the user picked stays" "$(cat "$config")"
pass "a backend the user picked stays"

printf 'font-size = 12\nasync-backend = epoll\n' >"$test_dir/dotfiles-config"
rm "$config"
ln -s "$test_dir/dotfiles-config" "$config"
run_migration
[[ -L $config ]] || fail "a linked config stays linked"
grep -qx "async-backend = io_uring" "$test_dir/dotfiles-config" || fail "a linked config is edited at its target"
pass "a linked config stays linked and moves to io_uring"

rm -rf "$home"
run_migration
[[ ! -e $config ]] || fail "no config is created where there was none"
pass "a home without a ghostty config is left alone"
