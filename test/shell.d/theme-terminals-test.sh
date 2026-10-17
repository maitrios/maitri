#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

require_command python3

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

RENDERED=(alacritty.toml foot.ini ghostty.conf kitty.conf warp.yaml btop.theme gum_env.lua keyboard.rgb)

cat >"$test_tmp/contrast.py" <<'PY'
import re, sys

theme_dir, colors_file = sys.argv[1], sys.argv[2]

def channel(c):
    c /= 255
    return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4

def luminance(color):
    h = color.lstrip("#")
    r, g, b = (int(h[i:i + 2], 16) for i in (0, 2, 4))
    return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)

def contrast(a, b):
    la, lb = sorted((luminance(a), luminance(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)

def norm(value):
    value = value.strip().strip("'\"")
    return ("#" + value.lstrip("#")).lower()

def read(name):
    return open(f"{theme_dir}/{name}").read()

palette = {}
for line in open(colors_file):
    m = re.match(r'\s*([a-z_]+)\s*=\s*"([^"]*)"', line)
    if m:
        palette[m.group(1)] = m.group(2).lower()

TEXT, LINE = 4.5, 3.0
rows = []

def check(app, label, fg, bg, floor):
    rows.append((app, label, norm(fg), norm(bg), contrast(norm(fg), norm(bg)), floor))

def fail(message):
    print(f"FAIL\t{message}")

def toml_section(text, section):
    body = re.search(r"^\[" + re.escape(section) + r"\]\n(.*?)(?=^\[|\Z)", text, re.S | re.M).group(1)
    return dict(re.findall(r'^(\w+) = "([^"]+)"', body, re.M))

def terminal(app, bg, fg, sel_fg, sel_bg, color8):
    check(app, "foreground", fg, bg, TEXT)
    check(app, "color8", color8, bg, TEXT)
    check(app, "selected text", sel_fg, sel_bg, TEXT)
    if norm(color8) != palette["comment"]:
        fail(f"{app} color8 is {color8}, not comment")

def checks():
    a = read("alacritty.toml")
    primary, bright, sel = toml_section(a, "colors.primary"), toml_section(a, "colors.bright"), toml_section(a, "colors.selection")
    terminal("alacritty", primary["background"], primary["foreground"], sel["text"], sel["background"], bright["black"])
    normal = toml_section(a, "colors.normal")
    for name, value in [(f"normal {n}", v) for n, v in normal.items() if n != "black"] + [(f"bright {n}", v) for n, v in bright.items()]:
        check("alacritty", name, value, primary["background"], TEXT)
    for section in ("colors.search.matches", "colors.search.focused_match"):
        s = toml_section(a, section)
        check("alacritty", section.split(".")[-1].replace("_", " "), s["foreground"], s["background"], TEXT)

    f = read("foot.ini")
    sections = re.findall(r"^\[(colors-\w+)\]\n(.*?)(?=^\[|\Z)", f, re.S | re.M)
    if [name for name, _ in sections] != ["colors-dark", "colors-light"]:
        fail(f"foot.ini sections are {[name for name, _ in sections]}")
    if len({body.strip() for _, body in sections}) != 1:
        fail("foot.ini colors-dark and colors-light differ")
    foot = dict(re.findall(r"^([\w-]+)=(\S+)", sections[0][1], re.M))
    terminal("foot", foot["background"], foot["foreground"], foot["selection-foreground"], foot["selection-background"], foot["bright0"])

    g = read("ghostty.conf")
    ghostty = dict(re.findall(r"^([\w-]+) = (\S+)$", g, re.M))
    ghostty_palette = dict(re.findall(r"^palette = (\d+)=(\S+)$", g, re.M))
    terminal("ghostty", ghostty["background"], ghostty["foreground"], ghostty["selection-foreground"], ghostty["selection-background"], ghostty_palette["8"])

    k = dict(re.findall(r"^(\w+) (\S+)$", read("kitty.conf"), re.M))
    terminal("kitty", k["background"], k["foreground"], k["selection_foreground"], k["selection_background"], k["color8"])
    check("kitty", "active tab", k["active_tab_foreground"], k["active_tab_background"], TEXT)
    check("kitty", "inactive tab", k["inactive_tab_foreground"], k["inactive_tab_background"], TEXT)
    check("kitty", "url", k["url_color"], k["background"], TEXT)
    check("kitty", "active border", k["active_border_color"], k["background"], LINE)
    check("kitty", "inactive border", k["inactive_border_color"], k["background"], LINE)

    w = read("warp.yaml")
    warp = dict(re.findall(r"^(\w+): (\S+)$", w, re.M))
    warp_bright = dict(re.findall(r"^    (\w+): (\S+)$", w.split("  bright:")[1], re.M))
    terminal("warp", warp["background"], warp["foreground"], warp["foreground"], warp["background"], warp_bright["black"])
    check("warp", "accent", warp["accent"], warp["background"], LINE)
    details = {"dark": "darker", "light": "lighter"}[palette.get("mode", "dark")]
    if warp["details"] != details:
        fail(f"warp details is {warp['details']}, not {details}")

    b = {k: norm(v) if v else "" for k, v in re.findall(r'^theme\[(\w+)\]="([^"]*)"', read("btop.theme"), re.M)}
    bg = b["main_bg"]
    for key in ("main_fg", "title", "hi_fg", "inactive_fg", "graph_text", "proc_misc"):
        check("btop", key, b[key], bg, TEXT)
    check("btop", "selected_fg", b["selected_fg"], b["selected_bg"], TEXT)
    check("btop", "followed_fg", b["followed_fg"], b["followed_bg"], TEXT)
    for key in ("proc_pause_bg", "proc_follow_bg", "proc_banner_bg"):
        check("btop", f"banner on {key}", b["proc_banner_fg"], b[key], TEXT)
    for key in ("cpu_box", "mem_box", "net_box", "proc_box", "div_line", "meter_bg"):
        check("btop", key, b[key], bg, LINE)
    for key in sorted(b):
        if re.search(r"_(start|mid|end)$", key):
            check("btop", key, b[key], bg, LINE)
    syntax = {palette[h] for h in ("green", "yellow", "blue", "magenta", "cyan") if palette[h] != palette["accent"]}
    for key in ("cpu_box", "mem_box", "net_box", "proc_box", "div_line", "meter_bg", "title", "selected_fg", "hi_fg"):
        if b[key] in syntax:
            fail(f"btop {key} is a syntax hue")
    if b["temp_mid"] != palette["orange"] or b["temp_end"] != palette["red"]:
        fail("btop temperature does not warn in orange and end in red")
    if "gradient_color_0" in b:
        fail("btop.theme sets gradient_color keys btop does not read")

    gum = dict(re.findall(r'^hl\.env\("(\w+)", "([^"]+)"\)', read("gum_env.lua"), re.M))
    for key, fg in gum.items():
        if not key.endswith("_FOREGROUND"):
            continue
        prefix = key[: -len("FOREGROUND")]
        bg_value = gum.get(prefix + "BACKGROUND", gum["BACKGROUND"])
        line = re.search(r"BORDER|SEPARATOR|END_OF_BUFFER", key)
        check("gum", prefix.rstrip("_").removeprefix("GUM_").lower() or "base", fg, bg_value, LINE if line else TEXT)
    for prefix in ("CONFIRM_PROMPT", "INPUT_PROMPT", "FILTER_PROMPT", "WRITE_PROMPT", "INPUT_HEADER", "CHOOSE_HEADER", "FILTER_HEADER", "FILE_HEADER", "WRITE_HEADER", "TABLE_HEADER"):
        fg = norm(gum[f"GUM_{prefix}_FOREGROUND"])
        if gum.get(f"GUM_{prefix}_BOLD") != "true":
            fail(f"gum {prefix} is not bold")
        if fg in (palette["green"], palette["yellow"]) and fg != palette["accent"]:
            fail(f"gum {prefix} is green or yellow")
        if "HEADER" in prefix and prefix != "TABLE_HEADER" or "PROMPT" in prefix:
            if fg != palette["accent"]:
                fail(f"gum {prefix} is {fg}, not the accent")

    if norm(read("keyboard.rgb")) != palette["accent"]:
        fail("keyboard.rgb is not the accent")

try:
    checks()
except (KeyError, AttributeError) as error:
    fail(f"missing {error}")

for app, label, fg, bg, ratio, floor in rows:
    print(f"{'ok' if ratio >= floor else 'FAIL'}\t{app}\t{label}\t{fg}\t{bg}\t{ratio:.2f}\t{floor}")
PY

for theme_dir in "$ROOT"/themes/*/; do
  theme=$(basename "$theme_dir")
  home="$test_tmp/$theme"
  next_theme="$home/.local/state/maitri/current/next-theme"
  mkdir -p "$next_theme"
  cp "$theme_dir/colors.toml" "$next_theme/colors.toml"

  HOME="$home" MAITRI_PATH="$ROOT" PATH="$ROOT/bin:$PATH" bash "$ROOT/bin/maitri-theme-set-templates"

  for file in "${RENDERED[@]}"; do
    [[ -f $next_theme/$file ]] || fail "$theme renders $file"
    ! grep -q '{{' "$next_theme/$file" || fail "$theme leaves no placeholders in $file" "$(grep -n '{{' "$next_theme/$file")"
  done

  report=$(python3 "$test_tmp/contrast.py" "$next_theme" "$theme_dir/colors.toml") ||
    fail "$theme contrast check runs"
  [[ -n $report ]] || fail "$theme produces a contrast report"
  if failures=$(grep '^FAIL' <<<"$report"); then
    fail "$theme terminal, btop, gum and keyboard colors clear 4.5:1 for text and 3:1 for lines" "$failures"
  fi
  [[ -z ${MAITRI_CONTRAST_REPORT:-} ]] || sed "s/^/$theme\t/" <<<"$report" >>"$MAITRI_CONTRAST_REPORT"
  pass "$theme terminal, btop, gum and keyboard colors clear 4.5:1 for text and 3:1 for lines"
done
