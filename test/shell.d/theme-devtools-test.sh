#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

require_command python3

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

TEMPLATES=(claude.json herdr.toml pi.json t3code.json hermes.yaml)

for file in "${TEMPLATES[@]}"; do
  ! grep -q '{{ muted }}' "$ROOT/default/themed/$file.tpl" ||
    fail "$file.tpl draws nothing in muted" "$(grep -n '{{ muted }}' "$ROOT/default/themed/$file.tpl")"
done
pass "the dev tool templates keep muted off text and lines"

cat >"$test_tmp/contrast.py" <<'PY'
import json, re, sys

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
    return ("#" + value.strip().strip("'\"").lstrip("#")).lower()

def mix(a, b, amount):
    a, b = norm(a).lstrip("#"), norm(b).lstrip("#")
    out = (int(int(a[i:i + 2], 16) * (1 - amount) + int(b[i:i + 2], 16) * amount + 0.5) for i in (0, 2, 4))
    return "#" + "".join(f"{v:02x}" for v in out)

def read(name):
    return open(f"{theme_dir}/{name}").read()

palette = {}
for line in open(colors_file):
    m = re.match(r'\s*([a-z_]+)\s*=\s*"([^"]*)"', line)
    if m:
        palette[m.group(1)] = m.group(2).lower()
palette.setdefault("comment", palette["dark_foreground"])
mode = palette.get("mode", "dark")

TEXT, LINE = 4.5, 3.0
SELECTION = 3.0
rows = []

def check(app, label, fg, bg, floor):
    rows.append((app, label, norm(fg), norm(bg), contrast(norm(fg), norm(bg)), floor))

def fail(message):
    print(f"FAIL\t{message}")

def same(app, key, value, role):
    expected = palette[role] if role in palette else role
    if norm(value) != norm(expected):
        fail(f"{app} {key} is {norm(value)}, not {role}")

def apart(app, label, a, b, floor=1.1):
    if contrast(norm(a), norm(b)) < floor:
        fail(f"{app} {label} does not stand out ({contrast(norm(a), norm(b)):.2f}:1)")

heading2 = mix(palette["accent"], palette["foreground"], 0.13)
heading3 = mix(palette["accent"], palette["foreground"], 0.26)

def claude():
    data = json.loads(read("claude.json"))
    if data["base"] != mode:
        fail(f"claude base is {data['base']}, not {mode}")
    o = data["overrides"]
    bg = palette["background"]
    lines = {"promptBorder", "promptBorderShimmer", "rate_limit_fill", "rate_limit_empty"}
    fills = {"inverseText", "clawd_background", "selectionBg"}
    for key, value in o.items():
        if key in lines:
            check("claude", key, value, bg, LINE)
        elif not re.search(r"Background|diff", key) and key not in fills:
            check("claude", key, value, bg, TEXT)
    for key in ("userMessageBackground", "userMessageBackgroundHover", "bashMessageBackgroundColor", "memoryBackgroundColor", "composerSidebarBackground", "selectionBg"):
        check("claude", f"text on {key}", o["text"], o[key], TEXT)
    for key in ("userMessageBackground", "bashMessageBackgroundColor", "memoryBackgroundColor"):
        check("claude", f"subtle on {key}", o["subtle"], o[key], TEXT)
    for key in sorted(k for k in o if k.startswith("diff")):
        check("claude", f"text on {key}", o["text"], o[key], TEXT)
    for key in ("claude", "permission", "suggestion"):
        check("claude", f"inverseText on {key}", o["inverseText"], o[key], TEXT)
    for key, role in (("warning", "orange"), ("error", "red"), ("success", "green"), ("subtle", "comment"), ("inactive", "comment"),
                      ("remember", "hint"), ("promptBorder", "border_focus"), ("rate_limit_empty", "border"), ("selectionBg", "selection"),
                      ("claude", "accent"), ("text", "foreground"), ("inverseText", "background")):
        same("claude", key, o[key], role)
    for key, hue, amount in (("diffAdded", "green", 0.13), ("diffRemoved", "red", 0.13), ("diffAddedWord", "green", 0.3), ("diffRemovedWord", "red", 0.3)):
        same("claude", key, o[key], mix(bg, palette[hue], amount))
    yellows = [k for k, v in o.items() if norm(v) == palette["yellow"] and k not in ("chromeYellow", "yellow_FOR_SUBAGENTS_ONLY", "rainbow_yellow")]
    if yellows and palette["yellow"] != palette["orange"]:
        fail(f"claude still draws {', '.join(yellows)} in yellow")

def herdr():
    t = dict(re.findall(r'^(\w+) = "([^"]+)"$', read("herdr.toml").split("[theme.custom]")[1], re.M))
    panel, sidebar = t["panel_bg"], t["sidebar_bg"]
    rows_bg = {"panel_bg": panel, "sidebar_bg": sidebar, "surface0": t["surface0"], "surface1": t["surface1"], "active_row_bg": t["active_row_bg"], "selection_bg": t["selection_bg"]}
    for name, fill in rows_bg.items():
        for key in ("text", "subtext0", "overlay1"):
            check("herdr", f"{key} on {name}", t[key], fill, TEXT)
        if name != "selection_bg":
            check("herdr", f"overlay0 on {name}", t["overlay0"], fill, TEXT)
    check("herdr", "overlay0 on selection_bg", t["overlay0"], t["selection_bg"], SELECTION)
    for key in ("accent", "mauve", "red", "green", "yellow", "blue", "peach", "teal"):
        check("herdr", f"{key} on panel_bg", t[key], panel, TEXT)
        check("herdr", f"{key} on sidebar_bg", t[key], sidebar, TEXT)
    check("herdr", "mauve on active_row_bg", t["mauve"], t["active_row_bg"], TEXT)
    check("herdr", "panel_bg on accent", panel, t["accent"], TEXT)
    check("herdr", "panel_bg on mauve", panel, t["mauve"], TEXT)
    check("herdr", "surface_dim on sidebar_bg", t["surface_dim"], sidebar, LINE)
    check("herdr", "surface_dim on panel_bg", t["surface_dim"], panel, LINE)
    check("herdr", "focused pane border", t["accent"], panel, LINE)
    apart("herdr", "active_row_bg on sidebar_bg", t["active_row_bg"], sidebar, 1.05)
    apart("herdr", "selection_bg on sidebar_bg", t["selection_bg"], sidebar)
    apart("herdr", "surface0 on panel_bg", t["surface0"], panel, 1.05)
    if norm(t["active_row_bg"]) == norm(t["selection_bg"]):
        fail("herdr active_row_bg reuses selection")
    for key, role in (("surface_dim", "border"), ("selection_bg", "selection"), ("mauve", "hint"), ("peach", "orange"), ("red", "red"),
                      ("overlay0", "comment"), ("text", "foreground"), ("accent", "accent")):
        same("herdr", key, t[key], role)

def pi():
    data = json.loads(read("pi.json"))
    if data.get("appearance") != mode:
        fail(f"pi appearance is {data.get('appearance')}, not {mode}")
    v = data["vars"]
    c = {k: norm(v.get(val, val)) for k, val in data["colors"].items()}
    bg = v["background"]
    lines = {"border", "borderAccent", "borderMuted", "mdCodeBlockBorder", "mdQuoteBorder", "mdHr", "scrollbarTrack", "scrollbarThumb", "bashMode"}
    fills = {"selectedBg", "searchMatchBg", "userMessageBg", "customMessageBg", "toolPendingBg", "toolSuccessBg", "toolErrorBg"}
    for key, value in c.items():
        if key in fills:
            continue
        check("pi", key, value, bg, LINE if key in lines or key.startswith("thinking") and key != "thinkingText" else TEXT)
    for key in ("userMessageBg", "customMessageBg", "toolPendingBg", "toolSuccessBg", "toolErrorBg", "selectedBg"):
        check("pi", f"text on {key}", c["text"], c[key], TEXT)
        check("pi", f"muted on {key}", c["muted"], c[key], TEXT)
    for key in ("userMessageBg", "customMessageBg", "toolPendingBg", "toolSuccessBg", "toolErrorBg", "selectedBg"):
        check("pi", f"dim on {key}", c["dim"], c[key], TEXT)
    check("pi", "accent on selectedBg", c["accent"], c["selectedBg"], TEXT)
    check("pi", "search match", c["searchMatchText"], c["searchMatchBg"], TEXT)
    for key, role in (("warning", "orange"), ("error", "red"), ("success", "green"), ("dim", "comment"), ("syntaxComment", "comment"),
                      ("mdHeading", "accent"), ("mdLink", "link"), ("border", "border_focus"), ("borderMuted", "border"),
                      ("syntaxString", "yellow"), ("syntaxNumber", "blue"), ("syntaxFunction", "green"), ("syntaxType", "cyan"), ("syntaxKeyword", "magenta")):
        same("pi", key, c[key], role)
    ramp = [c[k] for k in ("thinkingOff", "thinkingMinimal", "thinkingLow", "thinkingMedium", "thinkingHigh", "thinkingXhigh")]
    if len(set(ramp)) != len(ramp):
        fail("pi thinking levels repeat a colour")
    syntax = {palette[h] for h in ("red", "green", "yellow", "blue", "magenta", "cyan") if palette[h] != palette["accent"]}
    if set(ramp) & syntax:
        fail("pi thinking levels use a syntax hue")

def t3code():
    data = json.loads(read("t3code.json"))
    if data["appearance"] != mode:
        fail(f"t3code appearance is {data['appearance']}, not {mode}")
    c = dict(data["colors"], canvas=data["canvas"], accent=data["accent"])
    pairs = [
        ("text", "canvas"), ("textMuted", "canvas"), ("placeholder", "canvas"), ("secondaryLabel", "canvas"), ("iconMuted", "canvas"),
        ("text", "surface"), ("textMuted", "surface"), ("text", "surfaceOverlay"),
        ("toolbarForeground", "toolbar"), ("toolbarControlForeground", "toolbarControl"), ("toolbarControlForeground", "toolbarControlHover"),
        ("accentForeground", "accent"), ("accent", "canvas"), ("secondaryForeground", "secondary"), ("mutedForeground", "muted"),
        ("error", "canvas"), ("errorForeground", "errorSurface"), ("warning", "canvas"), ("warningForeground", "warningSurface"),
        ("update", "canvas"), ("updateForeground", "updateSurface"), ("accentSurfaceForeground", "accentSurface"),
        ("messageForeground", "messageSurface"), ("messageActionForeground", "messageAction"), ("messageActionForeground", "messageActionHover"),
        ("codeForeground", "codeBackground"), ("searchMatchForeground", "searchMatchBackground"), ("searchMatchActiveForeground", "searchMatchActiveBackground"),
        ("sidebarForeground", "sidebar"), ("sidebarMutedForeground", "sidebar"), ("sidebarMutedForeground", "sidebarRowHover"),
        ("sidebarForeground", "sidebarRowHover"), ("sidebarForeground", "sidebarRowActive"), ("sidebarForeground", "sidebarRowSelected"),
        ("sidebarMutedForeground", "sidebarRowActive"), ("sidebarMutedForeground", "sidebarRowSelected"),
        ("sidebarForeground", "sidebarControlSurface"), ("terminalForeground", "terminalBackground"), ("terminalForeground", "terminalSelection"),
    ]
    for fg, bg in pairs:
        check("t3code", f"{fg} on {bg}", c[fg], c[bg], TEXT)
    for fg, bg in (("toolbarBorder", "toolbar"), ("border", "canvas"), ("input", "canvas"), ("focus", "canvas"), ("sidebarBorder", "sidebar"),
                   ("terminalScrollbar", "terminalBackground"), ("terminalScrollbarHover", "terminalBackground")):
        check("t3code", f"{fg} on {bg}", c[fg], c[bg], LINE)
    apart("t3code", "sidebarRowSelected on sidebar", c["sidebarRowSelected"], c["sidebar"], 1.05)
    apart("t3code", "sidebarRowActive on sidebar", c["sidebarRowActive"], c["sidebar"], 1.05)
    if norm(c["sidebarRowSelected"]) == palette["selection"]:
        fail("t3code sidebarRowSelected reuses selection")
    for key, role in (("warning", "orange"), ("error", "red"), ("textMuted", "comment"), ("border", "border"), ("toolbarBorder", "border"),
                      ("sidebarBorder", "border"), ("input", "border"), ("focus", "border_focus"), ("terminalSelection", "selection")):
        same("t3code", key, c[key], role)

def hermes():
    h = dict(re.findall(r'^  (\w+): "([^"]+)"$', read("hermes.yaml"), re.M))
    bg = h["background"]
    for key in ("ui_text", "ui_primary", "ui_accent", "ui_label", "ui_ok", "ui_warn", "ui_error", "ui_tool", "ui_thinking", "banner_title",
                "banner_accent", "banner_dim", "banner_text", "prompt", "shell_dollar", "session_label", "diff_added_word",
                "diff_removed_word", "syntax_string", "syntax_number", "syntax_keyword", "syntax_comment"):
        check("hermes", key, h[key], bg, TEXT)
    for key in ("status_bar_text", "status_bar_strong", "status_bar_dim", "status_bar_good", "status_bar_warn", "status_bar_bad", "status_bar_critical"):
        check("hermes", key, h[key], h["status_bar_bg"], TEXT)
    for fill in ("completion_menu_bg", "completion_menu_current_bg", "completion_menu_meta_bg", "completion_menu_meta_current_bg", "selection_bg", "diff_added", "diff_removed"):
        check("hermes", f"ui_text on {fill}", h["ui_text"], h[fill], TEXT)
    for fill in ("completion_menu_bg", "completion_menu_meta_bg"):
        check("hermes", f"ui_thinking on {fill}", h["ui_thinking"], h[fill], TEXT)
    check("hermes", "banner_title on completion_menu_current_bg", h["banner_title"], h["completion_menu_current_bg"], TEXT)
    check("hermes", "ui_label on completion_menu_meta_current_bg", h["ui_label"], h["completion_menu_meta_current_bg"], TEXT)
    for key in ("ui_border", "banner_border", "input_rule", "response_border", "session_border"):
        check("hermes", key, h[key], bg, LINE)
    apart("hermes", "completion_menu_current_bg on completion_menu_bg", h["completion_menu_current_bg"], h["completion_menu_bg"], 1.05)
    if norm(h["completion_menu_current_bg"]) == palette["selection"]:
        fail("hermes completion_menu_current_bg reuses selection")
    for key, role in (("ui_warn", "orange"), ("status_bar_warn", "orange"), ("ui_error", "red"), ("status_bar_bad", "red"), ("ui_thinking", "comment"),
                      ("syntax_comment", "comment"), ("ui_border", "border"), ("banner_border", "border"), ("input_rule", "border"),
                      ("session_border", "border"), ("response_border", "border_focus"), ("selection_bg", "selection"), ("banner_title", "accent"),
                      ("banner_accent", heading2), ("ui_label", heading3), ("session_label", heading3), ("syntax_string", "yellow"), ("syntax_number", "blue")):
        same("hermes", key, h[key], role)

for app in (claude, herdr, pi, t3code, hermes):
    try:
        app()
    except (KeyError, AttributeError, IndexError, ValueError) as error:
        fail(f"{app.__name__} is missing {error}")

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

  for file in "${TEMPLATES[@]}"; do
    [[ -f $next_theme/$file ]] || fail "$theme renders $file"
    ! grep -q '{{' "$next_theme/$file" || fail "$theme leaves no placeholders in $file" "$(grep -n '{{' "$next_theme/$file")"
  done

  report=$(python3 "$test_tmp/contrast.py" "$next_theme" "$theme_dir/colors.toml") ||
    fail "$theme contrast check runs"
  [[ -n $report ]] || fail "$theme produces a contrast report"
  if failures=$(grep '^FAIL' <<<"$report"); then
    fail "$theme dev tool colors keep their roles and clear 4.5:1 for text and 3:1 for lines" "$failures"
  fi
  [[ -z ${MAITRI_CONTRAST_REPORT:-} ]] || sed "s/^/$theme\t/" <<<"$report" >>"$MAITRI_CONTRAST_REPORT"
  pass "$theme dev tool colors keep their roles and clear 4.5:1 for text and 3:1 for lines"
done
