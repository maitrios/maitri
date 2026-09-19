#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

require_command python3

# `muted` is the ANSI color8 / divider shade: in every shipped palette it sits
# far below readable contrast against the background, so it belongs on lines,
# not on glyphs. `dark_foreground` is the de-emphasized *text* color. These
# checks keep that split honest — see the palette table in docs/theming.md.

WCAG_AA=4.5

contrast_report=$(python3 - "$ROOT" <<'PY'
import os, re, sys

root = sys.argv[1]

def channel(c):
    c /= 255
    return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4

def luminance(hex_color):
    h = hex_color.strip().strip('"').lstrip('#')
    r, g, b = (int(h[i:i + 2], 16) for i in (0, 2, 4))
    return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)

def contrast(a, b):
    la, lb = luminance(a), luminance(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)

themes_dir = os.path.join(root, "themes")
key_re = re.compile(r'\s*([a-z_]+)\s*=\s*"?(#[0-9a-fA-F]{6})"?')

for theme in sorted(os.listdir(themes_dir)):
    colors = os.path.join(themes_dir, theme, "colors.toml")
    if not os.path.isfile(colors):
        continue
    palette = {}
    for line in open(colors):
        m = key_re.match(line)
        if m:
            palette.setdefault(m.group(1), m.group(2))
    background = palette.get("background") or palette.get("bg")
    text = palette.get("dark_foreground") or palette.get("dark_fg")
    if not background or not text:
        print(f"{theme}\tMISSING\t0")
        continue
    print(f"{theme}\t{text}\t{contrast(text, background):.2f}")
PY
)

[[ -n $contrast_report ]] || fail "themes/ has palettes to check"

while IFS=$'\t' read -r theme color ratio; do
  [[ $color != "MISSING" ]] ||
    fail "theme $theme defines background and dark_foreground"
  awk -v r="$ratio" -v min="$WCAG_AA" 'BEGIN { exit !(r >= min) }' ||
    fail "theme $theme reads dark_foreground against background at $WCAG_AA:1" \
      "$theme: dark_foreground $color is $ratio:1, below $WCAG_AA:1"
done <<<"$contrast_report"

pass "every shipped palette keeps dark_foreground readable on background"

offenders=$(python3 - "$ROOT" <<'PY'
import os, re, sys

templates = os.path.join(sys.argv[1], "default", "themed")

# A bare {{ muted }}; alpha-suffixed uses ({{ muted }}40) are fills, not glyphs.
MUTED = re.compile(r'\{\{ muted \}\}(?![0-9A-Fa-f])')

# Key names that mean "glyphs a person reads"...
TEXT = re.compile(r'foreground|comment|placeholder|line_?number|subtle|inactive_fg',
                  re.IGNORECASE)
# ...unless the same name also says the value is a line, edge or fill. Gum names
# every slot *_FOREGROUND, including its box drawing, so structural wins here.
# end_of_buffer is the `~` filler past the last line: decoration, not content.
STRUCTURAL = re.compile(
    r'border|separator|stroke|outline|guide|background|scrollbar|rule|'
    r'\bline\b|lines|div_line|ansi|color8|palette|end_of_buffer',
    re.IGNORECASE)

found = []
for name in sorted(os.listdir(templates)):
    if not name.endswith(".tpl"):
        continue
    path = os.path.join(templates, name)
    section = ""
    for n, line in enumerate(open(path), 1):
        stripped = line.strip()
        header = re.match(r'\[([^\]]+)\]\s*$', stripped)
        if header:
            section = header.group(1)
        if not MUTED.search(line):
            continue
        key = stripped.split("=")[0].split(":")[0]
        # Any value inside a TOML [colors.text*] table is read as text, whatever
        # the key is called — vicinae spells its muted-text slot `muted`.
        in_text_table = section.startswith("colors.text")
        if in_text_table or (TEXT.search(key) and not STRUCTURAL.search(key)):
            found.append(f"{name}:{n}: {stripped}")

print("\n".join(found))
PY
)

[[ -z $offenders ]] ||
  fail "themed templates render text from dark_foreground, not muted" "$offenders"

pass "themed templates keep muted off text-bearing keys"
