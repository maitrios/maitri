local M = {}

local function rgb(hex)
  hex = hex:gsub("^#", "")
  return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
end

function M.blend(from, to, amount)
  local r1, g1, b1 = rgb(from)
  local r2, g2, b2 = rgb(to)
  local function channel(a, b)
    return math.floor(a + (b - a) * amount + 0.5)
  end
  return string.format("#%02x%02x%02x", channel(r1, r2), channel(g1, g2), channel(b1, b2))
end

local required = {
  "accent",
  "selection",
  "muted",
  "background",
  "dark_background",
  "darker_background",
  "lighter_background",
  "foreground",
  "dark_foreground",
  "light_foreground",
  "bright_foreground",
  "red",
  "green",
  "yellow",
  "blue",
  "magenta",
  "cyan",
  "orange",
  "bright_red",
  "bright_green",
  "bright_yellow",
  "bright_blue",
  "bright_magenta",
  "bright_cyan",
}

function M.build(c, mode)
  for _, key in ipairs(required) do
    if type(c[key]) ~= "string" or not c[key]:match("^#%x%x%x%x%x%x$") then
      error(string.format("maitri-theme: color %s is missing or not #rrggbb (got %s)", key, tostring(c[key])))
    end
  end

  local blend = M.blend
  local light = mode == "light"

  local p = {
    blend = blend,
    mode = light and "light" or "dark",
    light = light,

    bg = c.background,
    bg_dark = c.dark_background,
    bg_darker = c.darker_background,
    bg_light = c.lighter_background,

    fg = c.foreground,
    fg_dim = c.light_foreground,
    fg_bright = c.bright_foreground,
    comment = c.dark_foreground,
    line = c.muted,
    accent = c.accent,

    red = c.red,
    green = c.green,
    yellow = c.yellow,
    blue = c.blue,
    magenta = c.magenta,
    cyan = c.cyan,
    orange = c.orange,

    bright_red = c.bright_red,
    bright_green = c.bright_green,
    bright_yellow = c.bright_yellow,
    bright_blue = c.bright_blue,
    bright_magenta = c.bright_magenta,
    bright_cyan = c.bright_cyan,
  }

  local tint = light and 0.16 or 0.13

  p.visual = blend(p.bg, p.accent, light and 0.2 or 0.26)
  p.cursorline = p.bg_light
  p.float = p.bg_dark
  p.border = blend(p.bg, p.accent, light and 0.6 or 0.5)
  p.border_dim = light and blend(p.bg, p.line, 0.6) or p.line
  p.nontext = light and blend(p.bg, p.comment, 0.55) or blend(p.line, p.comment, 0.35)
  p.reference = blend(p.bg, p.accent, light and 0.12 or 0.16)
  p.menu_sel = blend(p.bg_dark, p.accent, light and 0.22 or 0.3)

  p.search = blend(p.bg, p.green, light and 0.3 or 0.32)
  p.diff_add = blend(p.bg, p.green, tint)
  p.diff_delete = blend(p.bg, p.red, tint)
  p.diff_change = blend(p.bg, p.orange, tint * 0.75)
  p.diff_text = blend(p.bg, p.orange, light and 0.34 or 0.3)
  p.diff_add_text = blend(p.bg, p.green, light and 0.34 or 0.3)
  p.diff_delete_text = blend(p.bg, p.red, light and 0.34 or 0.3)

  p.heading = {}
  p.heading_bg = {}
  local heading_bg = { 0.16, 0.12, 0.09, 0.07, 0.05, 0.04 }
  for level = 1, 6 do
    p.heading[level] = blend(p.accent, p.fg, (level - 1) * 0.13)
    p.heading_bg[level] = blend(p.bg, p.accent, heading_bg[level] * (light and 0.8 or 1))
  end

  p.virtual = {
    error = blend(p.bg, p.red, 0.1),
    warn = blend(p.bg, p.orange, 0.1),
    info = blend(p.bg, p.cyan, 0.1),
    hint = blend(p.bg, p.accent, 0.1),
    ok = blend(p.bg, p.green, 0.1),
  }

  p.terminal = {
    p.bg,
    p.red,
    p.green,
    p.yellow,
    p.blue,
    p.magenta,
    p.cyan,
    p.fg,
    p.line,
    p.bright_red,
    p.bright_green,
    p.bright_yellow,
    p.bright_blue,
    p.bright_magenta,
    p.bright_cyan,
    p.fg_bright,
  }

  return p
end

return M
