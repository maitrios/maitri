#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["fonttools==4.60.1", "uharfbuzz==0.51.1"]
# ///
"""Typeset the lowercase maitri wordmark as paths into assets/brand/wordmark.svg.

  tools/wordmark.py

Shapes the word with HarfBuzz in the vendored Nunito at WEIGHT, so kerning
matches what the font ships, opens it up by TRACKING font units per letter,
and writes each glyph as an outline. Run
tools/brand.py afterwards to rebuild the lockup and every render.
"""

import os

import uharfbuzz as hb
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT = os.path.join(ROOT, "assets/brand/fonts/Nunito-Variable.ttf")
OUT = os.path.join(ROOT, "assets/brand/wordmark.svg")
TEXT = "maitri"
WEIGHT = 800
TRACKING = 15
FILL = "#B08CFF"


def fmt(value):
    text = "%.1f" % value
    return "0" if text in ("0.0", "-0.0") else text.rstrip("0").rstrip(".")


def main():
    face = hb.Face(hb.Blob.from_file_path(FONT))
    font = hb.Font(face)
    font.set_variations({"wght": WEIGHT})

    buf = hb.Buffer()
    buf.add_str(TEXT)
    buf.guess_segment_properties()
    hb.shape(font, buf, {"kern": True, "liga": True})

    pen = SVGPathPen(None, ntos=fmt)
    x = 0
    for info, pos in zip(buf.glyph_infos, buf.glyph_positions):
        font.draw_glyph_with_pen(info.codepoint, TransformPen(pen, (1, 0, 0, -1, x + pos.x_offset, -pos.y_offset)))
        x += pos.x_advance + TRACKING
    d = pen.getCommands()

    left, right, top, bottom = ink_bounds(font, buf)
    with open(OUT, "w", encoding="utf-8") as f:
        f.write('<svg xmlns="http://www.w3.org/2000/svg" viewBox="%s %s %s %s"><path fill="%s" d="%s"/></svg>\n'
                % (fmt(left), fmt(-top), fmt(right - left), fmt(top - bottom), FILL, d))


def ink_bounds(font, buf):
    left, right, top, bottom = None, None, 0, 0
    x = 0
    for info, pos in zip(buf.glyph_infos, buf.glyph_positions):
        ext = font.get_glyph_extents(info.codepoint)
        gx = x + pos.x_offset + ext.x_bearing
        left = gx if left is None else min(left, gx)
        right = gx + ext.width if right is None else max(right, gx + ext.width)
        top = max(top, pos.y_offset + ext.y_bearing)
        bottom = min(bottom, pos.y_offset + ext.y_bearing + ext.height)
        x += pos.x_advance + TRACKING
    return left, right, top, bottom


if __name__ == "__main__":
    main()
