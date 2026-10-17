#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

require_command python3

# See "The hue model" in docs/theming.md.

problems=$(python3 - "$ROOT" <<'PY'
import colorsys, math, os, re, sys

root = sys.argv[1]
SYNTAX = ["red", "orange", "yellow", "green", "cyan", "blue", "magenta"]
ROLES = ["accent", "selection", "muted", "border", "border_focus", "hint", "link", "comment"]
DIAGNOSTICS = ["red", "orange", "cyan", "green"]

def rgb(value):
    h = value.lstrip("#")
    return [int(h[i:i + 2], 16) for i in (0, 2, 4)]

def hue(value):
    r, g, b = (c / 255 for c in rgb(value))
    return colorsys.rgb_to_hls(r, g, b)[0] * 360

def apart(a, b):
    d = abs(hue(a) - hue(b)) % 360
    return min(d, 360 - d)

def luminance(value):
    def channel(c):
        c /= 255
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = (channel(c) for c in rgb(value))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b

def contrast(a, b):
    hi, lo = sorted((luminance(a), luminance(b)), reverse=True)
    return (hi + 0.05) / (lo + 0.05)

def oklch(value):
    def linear(c):
        c /= 255
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = (linear(c) for c in rgb(value))
    l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    lightness = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s
    a = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s
    b = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
    return lightness, math.hypot(a, b)

key_re = re.compile(r'^\s*([a-z_]+)\s*=\s*"(#[0-9a-fA-F]{6})"')
themes_dir = os.path.join(root, "themes")
problems = []

for theme in sorted(os.listdir(themes_dir)):
    path = os.path.join(themes_dir, theme, "colors.toml")
    if not os.path.isfile(path):
        continue
    text = open(path).read()
    c = {m.group(1): m.group(2).upper() for m in map(key_re.match, text.splitlines()) if m}
    light = re.search(r'^mode\s*=\s*"light"', text, re.M) is not None

    def problem(message):
        problems.append(f"{theme}: {message}")

    missing = [k for k in ROLES + SYNTAX + ["background", "dark_background", "foreground", "dark_foreground"] if k not in c]
    if missing:
        problem("missing " + ", ".join(missing))
        continue

    for i, a in enumerate(SYNTAX):
        for b in SYNTAX[i + 1:]:
            if apart(c[a], c[b]) < 30:
                problem(f"{a} and {b} are {apart(c[a], c[b]):.0f} degrees apart, under 30")

    slots = [n for n in SYNTAX if c[n] == c["accent"]]
    if len(slots) != 1:
        problem("the accent is not exactly one syntax color (" + (", ".join(slots) or "none") + ")")
    else:
        nearest = min(SYNTAX, key=lambda n: apart(c[n], c["accent"]) if n != slots[0] else 360)
        if apart(c[nearest], c["accent"]) < 30:
            problem(f"{nearest} sits {apart(c[nearest], c['accent']):.0f} degrees from the accent")

    if apart(c["link"], c["accent"]) < 60:
        problem(f"link is {apart(c['link'], c['accent']):.0f} degrees from the accent, under 60")
    for d in DIAGNOSTICS:
        if apart(c["hint"], c[d]) < 40:
            problem(f"hint is {apart(c['hint'], c[d]):.0f} degrees from {d}, under 40")
    if c["comment"] != c["dark_foreground"]:
        problem("comment is not dark_foreground")

    others = [n for n in SYNTAX if n not in slots]
    chroma = [oklch(c[n])[1] for n in others]
    lightness = [oklch(c[n])[0] for n in others]
    if max(chroma) - min(chroma) > (0.06 if light else 0.03):
        problem(f"syntax chroma spreads {min(chroma):.3f} to {max(chroma):.3f}")
    if max(lightness) - min(lightness) > 0.12:
        problem(f"syntax lightness spreads {min(lightness):.2f} to {max(lightness):.2f}")

    floor_bg = c["dark_background"] if light else c["background"]
    texts = [(key, surface) for key in SYNTAX + ["link", "hint", "comment"] for surface in {floor_bg, c["background"]}]
    texts += [(key, c["background"]) for key in c if key.startswith("bright_") and key != "bright_foreground"]
    for key, surface in texts:
        if contrast(c[key], surface) < 4.5:
            problem(f"{key} is {contrast(c[key], surface):.2f}:1 on {surface}, under 4.5")
    if contrast(c["border"], c["background"]) < 3:
        problem(f"border is {contrast(c['border'], c['background']):.2f}:1, under 3")
    if contrast(c["border_focus"], c["dark_background"]) < 3:
        problem(f"border_focus is {contrast(c['border_focus'], c['dark_background']):.2f}:1 on dark_background, under 3")
    if contrast(c["foreground"], c["selection"]) < 4.5:
        problem(f"foreground is {contrast(c['foreground'], c['selection']):.2f}:1 on selection, under 4.5")

print("\n".join(problems))
PY
)

[[ -z $problems ]] || fail "every shipped theme follows the hue model" "$problems"

pass "every shipped theme follows the hue model"
