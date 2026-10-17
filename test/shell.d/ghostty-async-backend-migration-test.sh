#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

migration="$ROOT/migrations/1792254615.sh"
test_dir=$(mktemp -d)
trap 'chmod -R u+w "$test_dir"; rm -rf "$test_dir"' EXIT

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

mkdir -p "$test_dir/dotfiles/ghostty"
printf 'async-backend = epoll\n' >"$test_dir/dotfiles/ghostty/config"
ln -s ghostty/config "$test_dir/dotfiles/current"
rm "$config"
ln -s ../../../dotfiles/current "$config"
run_migration
[[ -L $config && -L $test_dir/dotfiles/current ]] || fail "every link in a chain stays a link"
[[ $(<"$test_dir/dotfiles/ghostty/config") == "async-backend = io_uring" ]] || fail "a chain of links is edited at its final target"
pass "a chain of relative links stays linked and moves to io_uring"

rm "$config"
ln -s "$test_dir/moved-away/config" "$config"
run_migration || fail "a dangling link doesn't stall the queue"
[[ -L $config && ! -e $test_dir/moved-away ]] || fail "a dangling link is left as it is"
pass "a dangling link is skipped without stalling the queue"

rm "$config"
ln -s "$test_dir/loop-b" "$test_dir/loop-a"
ln -s "$test_dir/loop-a" "$test_dir/loop-b"
ln -s "$test_dir/loop-a" "$config"
run_migration || fail "a link loop doesn't stall the queue"
[[ -L $test_dir/loop-a && -L $test_dir/loop-b ]] || fail "a link loop is left as it is"
pass "a link loop is skipped without stalling the queue"

rm "$config"
printf 'async-backend = epoll\n' >"$config"
chmod 444 "$config"
output=$(HOME="$home" MAITRI_PATH="$ROOT" bash -euo pipefail "$migration") || fail "a read-only config doesn't stall the queue"
[[ $(<"$config") == "async-backend = epoll" ]] || fail "a read-only config is left alone"
[[ $output == *"isn't writable"* ]] || fail "a read-only config gets a notice" "$output"
chmod 644 "$config"
pass "a read-only config is left alone with a notice"

mkdir -p "$test_dir/locked"
printf 'async-backend = epoll\n' >"$test_dir/locked/config"
chmod 555 "$test_dir/locked"
rm "$config"
ln -s "$test_dir/locked/config" "$config"
run_migration || fail "a config in a read-only directory doesn't stall the queue"
chmod 755 "$test_dir/locked"
[[ $(<"$test_dir/locked/config") == "async-backend = epoll" ]] || fail "a config in a read-only directory is left alone"
pass "a config in a read-only directory is left alone"

rm -rf "$home"
run_migration
[[ ! -e $config ]] || fail "no config is created where there was none"
pass "a home without a ghostty config is left alone"
