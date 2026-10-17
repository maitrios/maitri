#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

migration="$ROOT/migrations/1792235139.sh"
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

mkdir -p "$test_dir/bin"

cat >"$test_dir/bin/maitri-theme-set" <<'STUB'
#!/bin/bash

echo "$*" >>"$THEME_SETS"
STUB

chmod +x "$test_dir/bin/"*

export THEME_SETS="$test_dir/theme-sets"

home="$test_dir/home"

run_migration() {
  : >"$THEME_SETS"
  HOME="$home" MAITRI_PATH="$ROOT" PATH="$test_dir/bin:$PATH" bash -euo pipefail "$migration" >/dev/null
}

with_theme() {
  rm -rf "$home"
  mkdir -p "$home/.local/state/maitri/current"
  [[ -z $1 ]] || printf '%s\n' "$1" >"$home/.local/state/maitri/current/theme.name"
}

with_theme orchid
run_migration
[[ $(<"$THEME_SETS") == "Amethyst" ]] || fail "an orchid user moves to Amethyst" "$(cat "$THEME_SETS")"
pass "an orchid user moves to Amethyst"

with_theme ember
run_migration
[[ ! -s $THEME_SETS ]] || fail "another theme is left alone" "$(cat "$THEME_SETS")"
pass "another theme is left alone"

with_theme ""
run_migration
[[ ! -s $THEME_SETS ]] || fail "a home with no current theme is left alone" "$(cat "$THEME_SETS")"
pass "a home with no current theme is left alone"

with_theme orchid
mkdir -p "$home/.config/maitri/themes/orchid"
run_migration
[[ ! -s $THEME_SETS ]] || fail "a user's own orchid theme is kept" "$(cat "$THEME_SETS")"
pass "a user's own orchid theme is kept"
