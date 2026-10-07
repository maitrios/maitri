#!/usr/bin/python3
"""Regenerate maitri's brand assets from logo.txt and assets/brand/.

  tools/brand.py           rebuild every derived asset in place
  tools/brand.py --check   fail if a derived asset is stale or the wrong shape

Needs rsvg-convert and ImageMagick (magick).
"""

import hashlib
import os
import struct
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

CELL_W, CELL_H = 10, 20
SHADOW_DX, SHADOW_DY = 5, 6
WORDMARK_WIDTH = 800
ICON_SIZE = 256
PREVIEW_SIZE = (1920, 1080)

DEFAULT_THEME = "amethyst"
DEFAULT_TEXT = "#ffffff"


def path(*parts):
    return os.path.join(ROOT, *parts)


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


def mix(a, b, t):
    ca = [int(a[i:i + 2], 16) for i in (1, 3, 5)]
    cb = [int(b[i:i + 2], 16) for i in (1, 3, 5)]
    return "#" + "".join("%02X" % round(x * (1 - t) + y * t) for x, y in zip(ca, cb))


def wordmark_runs():
    with open(path("logo.txt"), encoding="utf-8") as f:
        lines = [line.rstrip("\n") for line in f if line.strip()]
    runs = []
    for row, line in enumerate(lines):
        col = 0
        while col < len(line):
            if line[col] == "█":
                start = col
                while col < len(line) and line[col] == "█":
                    col += 1
                runs.append((start, row, col - start))
            else:
                col += 1
    return runs


def wordmark_svg(face, shadow):
    runs = wordmark_runs()
    cols = max(start + length for start, _, length in runs)
    rows = max(row for _, row, _ in runs) + 1
    width, height = cols * CELL_W + SHADOW_DX, rows * CELL_H + SHADOW_DY

    def rects(dx, dy):
        return "".join(
            '<rect x="%d" y="%d" width="%d" height="%d"/>'
            % (start * CELL_W + dx, row * CELL_H + dy, length * CELL_W, CELL_H)
            for start, row, length in runs)

    return (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 %d %d" width="%d" height="%d">\n'
        '  <g fill="%s">%s</g>\n'
        '  <g fill="%s">%s</g>\n'
        '</svg>\n'
        % (width, height, width, height,
           shadow, rects(SHADOW_DX, SHADOW_DY), face, rects(0, 0)))


def theme_wordmark(name):
    colors = theme_colors(name)
    return wordmark_svg(colors["accent"], mix(colors["accent"], colors["background"], 0.5))


def render(svg, out, width):
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
    with open(path("logo.svg"), "w", encoding="utf-8") as f:
        f.write(theme_wordmark(DEFAULT_THEME))

    for name in themes():
        unlock = path("themes", name, "unlock.png")
        render(theme_wordmark(name), unlock, WORDMARK_WIDTH)
        colors = theme_colors(name)
        preview(colors["background"], colors["foreground"], unlock,
                path("themes", name, "preview-unlock.png"))

    default_logo = path("themes", DEFAULT_THEME, "unlock.png")
    for target in ("default/plymouth/logo.png", "default/sddm/maitri/logo.png"):
        with open(default_logo, "rb") as src, open(path(target), "wb") as dst:
            dst.write(src.read())
    preview(theme_colors(DEFAULT_THEME)["background"], DEFAULT_TEXT, default_logo,
            path("default/plymouth/preview-unlock.png"))

    render(open(path("assets/brand/icon.svg"), encoding="utf-8").read(),
           path("icon.png"), ICON_SIZE)


def check():
    problems = []
    with open(path("logo.svg"), encoding="utf-8") as f:
        if f.read() != theme_wordmark(DEFAULT_THEME):
            problems.append("logo.svg is stale; run tools/brand.py")

    def expect(file, width, height=None):
        if not os.path.isfile(path(file)):
            problems.append("%s is missing" % file)
            return
        w, h = png_size(path(file))
        if w != width or (height is not None and h != height):
            problems.append("%s is %dx%d" % (file, w, h))

    unlocks = {}
    for name in themes():
        expect("themes/%s/unlock.png" % name, WORDMARK_WIDTH)
        expect("themes/%s/preview-unlock.png" % name, *PREVIEW_SIZE)
        if os.path.isfile(path("themes", name, "unlock.png")):
            unlocks.setdefault(digest(path("themes", name, "unlock.png")), []).append(name)
    for names in unlocks.values():
        if len(names) > 1:
            problems.append("themes share one unlock.png: %s" % ", ".join(names))

    for file in ("default/plymouth/logo.png", "default/sddm/maitri/logo.png"):
        expect(file, WORDMARK_WIDTH)
        if os.path.isfile(path(file)) and digest(path(file)) != digest(
                path("themes", DEFAULT_THEME, "unlock.png")):
            problems.append("%s is not the %s wordmark" % (file, DEFAULT_THEME))
    expect("default/plymouth/preview-unlock.png", *PREVIEW_SIZE)
    expect("icon.png", ICON_SIZE, ICON_SIZE)

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
