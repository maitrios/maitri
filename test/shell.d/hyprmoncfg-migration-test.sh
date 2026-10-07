#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

migration="$ROOT/migrations/1791352447.sh"
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

mkdir -p "$test_dir/bin"

cat >"$test_dir/bin/maitri-pkg-present" <<'STUB'
#!/bin/bash

[[ " $INSTALLED " == *" $1 "* ]]
STUB

cat >"$test_dir/bin/maitri-pkg-add" <<'STUB'
#!/bin/bash

echo "pkg-add $*" >>"$CALLS"
STUB

cat >"$test_dir/bin/systemctl" <<'STUB'
#!/bin/bash

echo "systemctl $*" >>"$CALLS"
case "$*" in
  "--user enable hyprmoncfgd.service") (( ENABLE_WORKS )) ;;
  "--user is-active --quiet graphical-session.target") (( GRAPHICAL )) ;;
  *) exit 0 ;;
esac
STUB

chmod +x "$test_dir/bin/"*

export CALLS="$test_dir/calls"
home="$test_dir/home"
config="$home/.config/hypr/hyprland.lua"
output="$test_dir/output"
wants="$home/.config/systemd/user/default.target.wants/hyprmoncfgd.service"

run_migration() {
  : >"$CALLS"
  HOME="$home" PATH="$test_dir/bin:$PATH" INSTALLED="${INSTALLED:-}" ENABLE_WORKS="${ENABLE_WORKS:-1}" \
    GRAPHICAL="${GRAPHICAL:-1}" bash -euo pipefail "$migration" >"$output"
}

reset_home() {
  rm -rf "$home"
  mkdir -p "$home/.config/hypr"
  head -n -3 "$ROOT/config/hypr/hyprland.lua" >"$config"
}

include_count() {
  grep -c 'hyprmoncfg-monitors.lua' "$config" || true
}

# ------------------------------------------------------------------ fresh install

reset_home
run_migration
grep -qx 'pkg-add hyprmoncfg' "$CALLS" || fail "migration installs hyprmoncfg" "$(cat "$CALLS")"
pass "migration installs hyprmoncfg"

diff <(tail -n 2 "$config") <(tail -n 2 "$ROOT/config/hypr/hyprland.lua") >/dev/null ||
  fail "the include matches the shipped template and loads last" "$(tail -n 4 "$config")"
pass "the include matches the shipped template and loads last"

grep -qx 'systemctl --user enable hyprmoncfgd.service' "$CALLS" || fail "migration enables hyprmoncfgd"
grep -qx 'systemctl --user start hyprmoncfgd.service' "$CALLS" || fail "migration starts hyprmoncfgd in a graphical session"
pass "migration enables and starts hyprmoncfgd"

run_migration
[[ $(include_count) == 1 ]] || fail "migration is idempotent" "$(cat "$config")"
pass "migration is idempotent"

# ------------------------------------------------------------------ existing setups

reset_home
cp "$ROOT/config/hypr/hyprland.lua" "$config"
before=$(cat "$config")
INSTALLED="hyprmoncfg-bin" run_migration
! grep -q 'pkg-add' "$CALLS" || fail "an installed hyprmoncfg-bin is kept" "$(cat "$CALLS")"
[[ $(cat "$config") == "$before" ]] || fail "an existing include is left alone"
pass "an installed hyprmoncfg-bin and its include are kept"

reset_home
before=$(cat "$config")
INSTALLED="hyprmoncfg" run_migration
[[ $(cat "$config") == "$before" ]] || fail "an unmanaged hyprmoncfg keeps its config untouched"
grep -q "hyprmoncfg manage" "$output" || fail "migration explains how to hand hyprmoncfg display control" "$(cat "$output")"
! grep -q 'enable hyprmoncfgd' "$CALLS" || fail "an unmanaged hyprmoncfg is not re-enabled"
pass "a deliberately unmanaged hyprmoncfg is respected"

reset_home
printf 'require("default.hypr.maitri")' >"$config"
run_migration
[[ $(head -n 1 "$config") == 'require("default.hypr.maitri")' ]] || fail "a config without a trailing newline keeps its last line"
[[ $(tail -n 1 "$config") == *'hyprmoncfg-monitors.lua'* ]] || fail "the include still loads last" "$(cat "$config")"
pass "a config without a trailing newline keeps its last line"

# ------------------------------------------------------------------ sessions

reset_home
ENABLE_WORKS=0 GRAPHICAL=0 run_migration
[[ -L $wants && $(readlink "$wants") == /usr/lib/systemd/user/hyprmoncfgd.service ]] ||
  fail "without a user manager the unit is wanted by default.target"
! grep -q 'start hyprmoncfgd' "$CALLS" || fail "nothing starts outside a graphical session"
pass "a TTY update enables hyprmoncfgd for the next login"

rm -rf "$home"
mkdir -p "$home"
run_migration
[[ ! -e $config ]] || fail "a missing hyprland.lua stays missing"
pass "a missing hyprland.lua stays missing"
