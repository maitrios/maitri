#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

home="$test_tmp/home"
state="$home/.local/state/maitri/current"
user_backgrounds="$home/.config/maitri/backgrounds/amethyst"
fake_bin="$test_tmp/bin"
mkdir -p "$state" "$user_backgrounds" "$fake_bin"
low="$user_backgrounds/0000000000000000000000000000000000000000000000000000000000000000.jpg"
high="$user_backgrounds/ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff.jpg"
head -c 64 /dev/urandom >"$low"
head -c 64 /dev/urandom >"$high"
theme_background="$state/theme/backgrounds/amethyst.png"

HOME="$home" MAITRI_PATH="$ROOT" PATH="$ROOT/bin:$PATH" MAITRI_THEME_HEADLESS=1 XDG_RUNTIME_DIR="$test_tmp" \
  bash "$ROOT/bin/maitri-theme-set" amethyst >/dev/null 2>"$test_tmp/err" || fail "maitri-theme-set applies amethyst" "$(cat "$test_tmp/err")"
[[ $(readlink "$state/background") == "$theme_background" ]] ||
  fail "switching theme picks the theme's own wallpaper over downloaded ones" "$(readlink "$state/background")"
pass "switching theme picks the theme's own wallpaper first"

cat >"$fake_bin/maitri-theme-bg-set" <<'SH'
#!/bin/bash
ln -nsf "$1" "$HOME/.local/state/maitri/current/background"
SH
chmod +x "$fake_bin/maitri-theme-bg-set"
cycle=()
for _ in 1 2 3; do
  HOME="$home" PATH="$fake_bin:$ROOT/bin:$PATH" bash "$ROOT/bin/maitri-theme-bg-next"
  cycle+=("$(readlink "$state/background")")
done
[[ ${cycle[0]} == "$low" && ${cycle[1]} == "$high" && ${cycle[2]} == "$theme_background" ]] ||
  fail "bg next cycles the theme's own wallpaper and then the downloaded ones in order" "${cycle[*]}"
pass "bg next follows the same order as a theme switch"
