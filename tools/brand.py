#!/usr/bin/python3
"""Regenerate maitri's brand assets from the heart below and assets/brand/wordmark.svg.

  tools/brand.py           rebuild every derived asset in place
  tools/brand.py --check   fail if a derived asset is stale or the wrong shape

The heart is one bold line drawn from circles and the lines tangent to them,
so HEART holds its whole geometry: the two lobes, the rounded point, the loop
and the two free ends. The outline is the exact offset of that centre line,
which keeps heart.svg, heart-glyph.svg and icon.svg on one path. The wordmark
comes from tools/wordmark.py.

Needs rsvg-convert and ImageMagick (magick).
"""

import hashlib
import math
import os
import re
import struct
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

HEART = {
    "stroke": 14.5,
    "lobe": ((37, -32), 36.5),
    "point": ((0, 30), 26),
    "loop": ((0, -18.5), 19),
    "start": (-150, 7),
    "end": (-134, 4),
}
BRAND_COLOR = "#B08CFF"
GLYPH_COLOR = "#000000"
TILE_TOP, TILE_BOTTOM = "#1D1729", "#0F0A18"
ICON_SCALE = 0.88

LOCKUP_GAP = 0.32
LOCKUP_WIDTH = 800
ICON_SIZE = 256
BOOT_HEART_SIZE = 360
PREVIEW_SIZE = (1920, 1080)

DEFAULT_THEME = "amethyst"
DEFAULT_TEXT = "#ffffff"


def path(*parts):
    return os.path.join(ROOT, *parts)


def read_text(relative):
    with open(path(relative), encoding="utf-8") as f:
        return f.read()


def theme_colors(name):
    colors = {}
    with open(path("themes", name, "colors.toml"), encoding="utf-8") as f:
        for line in f:
            key, sep, value = line.partition("=")
            if sep:
                colors[key.strip()] = value.strip().strip('"')
    return colors


def themes():
    return sorted(d for d in os.listdir(path("themes"))
                  if os.path.isfile(path("themes", d, "colors.toml")))


def fmt(value):
    text = ("%.2f" % value).rstrip("0").rstrip(".")
    return "0" if text == "-0" else text


def pt(p):
    return "%s %s" % (fmt(p[0]), fmt(p[1]))


def unit(degrees):
    return (math.cos(math.radians(degrees)), math.sin(math.radians(degrees)))


def normal(d):
    return (d[1], -d[0])


def along(p, d, distance):
    return (p[0] + distance * d[0], p[1] + distance * d[1])


def touch(centre, radius, d):
    return along(centre, normal(d), -radius)


def tangent(c1, r1, c2, r2):
    dx, dy = c2[0] - c1[0], c2[1] - c1[1]
    d = unit(math.degrees(math.atan2(dy, dx) + math.asin((r2 - r1) / math.hypot(dx, dy))))
    return touch(c1, r1, d), touch(c2, r2, d)


def heart_line():
    (lx, ly), lobe_r = HEART["lobe"]
    left, right = (-lx, ly), (lx, ly)
    point, point_r = HEART["point"]
    loop, loop_r = HEART["loop"]
    start_dir, end_dir = unit(HEART["start"][0]), unit(HEART["end"][0])

    a = touch(left, lobe_r, start_dir)
    b, c = tangent(left, lobe_r, point, point_r)
    d, e = tangent(point, point_r, right, lobe_r)
    f, g = tangent(right, lobe_r, loop, loop_r)
    h = touch(loop, loop_r, end_dir)
    return [
        ("line", along(a, start_dir, -HEART["start"][1]), a),
        ("arc", a, b, left, lobe_r),
        ("line", b, c),
        ("arc", c, d, point, point_r),
        ("line", d, e),
        ("arc", e, f, right, lobe_r),
        ("line", f, g),
        ("arc", g, h, loop, loop_r),
        ("line", h, along(h, end_dir, HEART["end"][1])),
    ]


def direction(segment, at_end):
    if segment[0] == "line":
        (x0, y0), (x1, y1) = segment[1], segment[2]
        length = math.hypot(x1 - x0, y1 - y0)
        return ((x1 - x0) / length, (y1 - y0) / length)
    _, a, b, centre, radius = segment
    p = b if at_end else a
    return ((p[1] - centre[1]) / radius, (centre[0] - p[0]) / radius)


def large(segment):
    _, a, b, centre, _ = segment
    start = math.atan2(a[1] - centre[1], a[0] - centre[0])
    stop = math.atan2(b[1] - centre[1], b[0] - centre[0])
    return 1 if (start - stop) % (2 * math.pi) > math.pi else 0


def side(segments, offset):
    edges = []
    for segment in segments:
        a = along(segment[1], normal(direction(segment, False)), offset)
        b = along(segment[2], normal(direction(segment, True)), offset)
        radius = None if segment[0] == "line" else segment[4] - offset
        edges.append((a, b, radius, 0 if segment[0] == "line" else large(segment)))
    return edges


def heart_path():
    segments = heart_line()
    half = HEART["stroke"] / 2
    outer = side(segments, -half)
    inner = [(b, a, radius, flag) for a, b, radius, flag in reversed(side(segments, half))]
    cap = "A%s %s 0 0 0 " % (fmt(half), fmt(half))

    commands = ["M" + pt(outer[0][0])]
    for edges, sweep in ((outer, 0), (inner, 1)):
        for _, b, radius, flag in edges:
            if radius is None:
                commands.append("L" + pt(b))
            else:
                commands.append("A%s %s 0 %d %d %s" % (fmt(radius), fmt(radius), flag, sweep, pt(b)))
        commands.append(cap + pt(inner[0][0] if sweep == 0 else outer[0][0]))
    return " ".join(commands) + " Z"


def heart_box():
    (lx, ly), lobe_r = HEART["lobe"]
    point, point_r = HEART["point"]
    half = HEART["stroke"] / 2
    return (-(lx + lobe_r + half), ly - lobe_r - half, lx + lobe_r + half, point[1] + point_r + half)


def heart_svg(fill):
    return ('<svg xmlns="http://www.w3.org/2000/svg" viewBox="-100 -100 200 200">'
            '<path fill="%s" d="%s"/></svg>\n' % (fill, heart_path()))


def icon_svg():
    x0, y0, x1, y1 = heart_box()
    dy = 128 - ICON_SCALE * (y0 + y1) / 2
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256">\n'
        '  <defs>\n'
        '    <linearGradient id="tile" x1="0" y1="0" x2="0" y2="256" gradientUnits="userSpaceOnUse">\n'
        '      <stop offset="0" stop-color="%s"/>\n'
        '      <stop offset="1" stop-color="%s"/>\n'
        '    </linearGradient>\n'
        '  </defs>\n'
        '  <rect x="8" y="8" width="240" height="240" rx="56" fill="url(#tile)"/>\n'
        '  <path transform="translate(128 %s) scale(%s)" fill="%s" d="%s"/>\n'
        '</svg>\n'
        % (TILE_TOP, TILE_BOTTOM, fmt(dy), fmt(ICON_SCALE), BRAND_COLOR, heart_path()))


def wordmark():
    svg = read_text("assets/brand/wordmark.svg")
    box = [float(v) for v in re.search(r'viewBox="([^"]+)"', svg).group(1).split()]
    return box, re.search(r' d="([^"]+)"', svg).group(1)


def lockup_svg(fill):
    (wx, wy, ww, wh), letters = wordmark()
    x0, y0, x1, y1 = heart_box()
    scale = wh / (y1 - y0)
    heart_w = (x1 - x0) * scale
    gap = LOCKUP_GAP * wh
    width, height = heart_w + gap + ww, wh
    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %s %s">\n'
        '  <g fill="%s">\n'
        '    <path transform="translate(%s %s) scale(%s)" d="%s"/>\n'
        '    <path transform="translate(%s %s)" d="%s"/>\n'
        '  </g>\n'
        '</svg>\n'
        % (fmt(width), fmt(height), fill,
           fmt(-x0 * scale), fmt(-y0 * scale), ("%.6f" % scale).rstrip("0"), heart_path(),
           fmt(heart_w + gap - wx), fmt(-wy), letters))


def theme_lockup(name):
    return lockup_svg(theme_colors(name)["accent"])


def sources():
    return {
        "assets/brand/heart.svg": heart_svg(BRAND_COLOR),
        "assets/brand/heart-glyph.svg": heart_svg(GLYPH_COLOR),
        "assets/brand/icon.svg": icon_svg(),
        "assets/brand/lockup.svg": lockup_svg(BRAND_COLOR),
        "logo.svg": theme_lockup(DEFAULT_THEME),
    }


def render(svg, out, width):
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with tempfile.NamedTemporaryFile("w", suffix=".svg", delete=False) as f:
        f.write(svg)
    try:
        subprocess.run(["rsvg-convert", "-w", str(width), "-o", out, f.name], check=True)
    finally:
        os.unlink(f.name)


def preview(background, text, logo, out):
    env = dict(os.environ, MAITRI_PATH=ROOT)
    subprocess.run([path("bin", "maitri-plymouth-preview"), "--no-view",
                    background, text, logo, out], check=True, env=env)
    subprocess.run(["magick", out, "-strip", "-define", "png:exclude-chunks=date,time", out], check=True)


def png_size(file):
    with open(file, "rb") as f:
        head = f.read(24)
    if head[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("%s is not a PNG" % file)
    return struct.unpack(">II", head[16:24])


def digest(file):
    with open(file, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()


def build():
    for relative, svg in sources().items():
        with open(path(relative), "w", encoding="utf-8") as f:
            f.write(svg)

    for name in themes():
        unlock = path("themes", name, "unlock.png")
        render(theme_lockup(name), unlock, LOCKUP_WIDTH)
        colors = theme_colors(name)
        preview(colors["background"], colors["foreground"], unlock,
                path("themes", name, "preview-unlock.png"))

    default_logo = path("themes", DEFAULT_THEME, "unlock.png")
    for target in ("default/plymouth/logo.png", "default/sddm/maitri/logo.png"):
        with open(default_logo, "rb") as src, open(path(target), "wb") as dst:
            dst.write(src.read())
    preview(theme_colors(DEFAULT_THEME)["background"], DEFAULT_TEXT, default_logo,
            path("default/plymouth/preview-unlock.png"))

    render(icon_svg(), path("icon.png"), ICON_SIZE)
    render(heart_svg(BRAND_COLOR), path("default/plymouth/logos/heart.png"), BOOT_HEART_SIZE)


def check():
    problems = []
    for relative, svg in sources().items():
        if not os.path.isfile(path(relative)) or read_text(relative) != svg:
            problems.append("%s is stale; run tools/brand.py" % relative)

    def expect(file, width, height=None):
        if not os.path.isfile(path(file)):
            problems.append("%s is missing" % file)
            return
        w, h = png_size(path(file))
        if w != width or (height is not None and h != height):
            problems.append("%s is %dx%d" % (file, w, h))

    unlocks = {}
    for name in themes():
        expect("themes/%s/unlock.png" % name, LOCKUP_WIDTH)
        expect("themes/%s/preview-unlock.png" % name, *PREVIEW_SIZE)
        if os.path.isfile(path("themes", name, "unlock.png")):
            unlocks.setdefault(digest(path("themes", name, "unlock.png")), []).append(name)
    for names in unlocks.values():
        if len(names) > 1:
            problems.append("themes share one unlock.png: %s" % ", ".join(names))

    for file in ("default/plymouth/logo.png", "default/sddm/maitri/logo.png"):
        expect(file, LOCKUP_WIDTH)
        if os.path.isfile(path(file)) and digest(path(file)) != digest(
                path("themes", DEFAULT_THEME, "unlock.png")):
            problems.append("%s is not the %s lockup" % (file, DEFAULT_THEME))
    expect("default/plymouth/preview-unlock.png", *PREVIEW_SIZE)
    expect("icon.png", ICON_SIZE, ICON_SIZE)
    expect("default/plymouth/logos/heart.png", BOOT_HEART_SIZE, BOOT_HEART_SIZE)

    for problem in problems:
        print("brand: %s" % problem, file=sys.stderr)
    return 1 if problems else 0


def main():
    args = sys.argv[1:]
    if args == ["--check"]:
        sys.exit(check())
    if args in ([], ["--build"]):
        build()
        sys.exit(check())
    sys.exit(__doc__.strip())


if __name__ == "__main__":
    main()
