#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

require_command python3

output=$("$ROOT/tools/brand.py" --check 2>&1) || fail "brand assets match tools/brand.py" "$output"
pass "brand assets match tools/brand.py"

grep -qxF -- '- `U+E900` — maitri, from `assets/brand/heart-glyph.svg`' "$ROOT/default/fonts/maitri/README.md" ||
  fail "the font README records where the maitri heart comes from"
pass "the font README records where the maitri heart comes from"

font_dir=$(mktemp -d)
trap 'rm -rf "$font_dir"' EXIT
cp "$ROOT/default/fonts/maitri/maitri.ttf" "$font_dir/maitri.ttf"
MAITRI_PATH=$ROOT "$ROOT/bin/maitri-dev-font" replace U+E900 "$ROOT/assets/brand/heart-glyph.svg" \
  --font "$font_dir/maitri.ttf" >/dev/null
cmp -s "$font_dir/maitri.ttf" "$ROOT/default/fonts/maitri/maitri.ttf" ||
  fail "maitri.ttf carries the current heart glyph; rerun maitri dev font replace U+E900"
pass "maitri.ttf carries the current heart glyph"

for art in logo.txt icon.txt; do
  stray=$(LC_ALL=C.UTF-8 grep -n '[^ █▀▄]' "$ROOT/$art" || true)
  [[ -z $stray ]] || fail "$art uses only the block glyphs every console font has" "$stray"
  width=$(LC_ALL=C.UTF-8 wc -L <"$ROOT/$art")
  (( width <= 80 )) || fail "$art fits an 80-column console" "$width columns"
done
pass "logo.txt and icon.txt fit the console"
