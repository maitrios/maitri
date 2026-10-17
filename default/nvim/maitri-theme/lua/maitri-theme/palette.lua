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

local function luminance(hex)
  local function channel(value)
    value = value / 255
    return value <= 0.03928 and value / 12.92 or ((value + 0.055) / 1.055) ^ 2.4
  end
  local r, g, b = rgb(hex)
  return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
end

function M.contrast(a, b)
  local la, lb = luminance(a), luminance(b)
  if la < lb then
    la, lb = lb, la
  end
  return (la + 0.05) / (lb + 0.05)
end

function M.distance(a, b)
  local r1, g1, b1 = rgb(a)
  local r2, g2, b2 = rgb(b)
  return math.sqrt((r1 - r2) ^ 2 + (g1 - g2) ^ 2 + (b1 - b2) ^ 2)
end

local function near(a, b)
  return M.distance(a, b) < 48
end

function M.hue(hex)
  local r, g, b = rgb(hex)
  r, g, b = r / 255, g / 255, b / 255
  local max, min = math.max(r, g, b), math.min(r, g, b)
  local delta = max - min
  if delta == 0 then
    return 0
  end
  local h
  if max == r then
    h = ((g - b) / delta) % 6
  elseif max == g then
    h = (b - r) / delta + 2
  else
    h = (r - g) / delta + 4
  end
  return h * 60
end

function M.hue_distance(a, b)
  local d = math.abs(M.hue(a) - M.hue(b)) % 360
  return math.min(d, 360 - d)
end

function M.toward(color, target, against, minimum)
  local amount = 0
  local result = color
  while M.contrast(result, against) < minimum and amount < 1 do
    amount = amount + 0.02
    result = M.blend(color, target, amount)
  end
  return result
end

function M.readable(color, bg, fg, minimum)
  local amount = 0
  local result = color
  while M.contrast(result, bg) < (minimum or 4.5) and amount < 1 do
    amount = amount + 0.05
    result = M.blend(color, fg, amount)
  end
  return result
end

local required = {
  "accent",
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

  c = vim.tbl_extend("force", {}, c)
  for _, key in ipairs({ "selection", "border", "border_focus", "hint", "link", "comment" }) do
    if type(c[key]) ~= "string" or not c[key]:match("^#%x%x%x%x%x%x$") then
      c[key] = nil
    end
  end
  if c.selection and M.contrast(c.selection, c.background) < 1.3 then
    c.selection = nil
  end
  if c.border_focus and c.border_focus:lower() == c.accent:lower() then
    c.border_focus = nil
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
    comment = c.comment or c.dark_foreground,
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

  if light then
    p.bg_dark = M.toward(p.bg_dark, p.fg, p.bg, 1.22)
    p.bg_darker = M.toward(p.bg_darker, p.fg, p.bg, 1.35)
    p.bg_light = M.toward(p.bg_light, p.fg, p.bg, 1.16)
    p.line = M.toward(p.line, p.fg, p.bg, 3)
  else
    p.bg_dark = M.toward(c.lighter_background, p.fg, p.bg, 1.22)
    p.bg_light = M.toward(c.lighter_background, p.fg, p.bg, 1.15)
  end
  p.code_border = light and p.bg_darker or M.toward(c.lighter_background, p.fg, p.bg, 1.35)

  for _, key in ipairs({ "comment", "accent", "red", "green", "yellow", "blue", "magenta", "cyan", "orange" }) do
    p[key] = M.readable(p[key], p.bg_dark, p.fg)
  end

  local tint = light and 0.16 or 0.13

  local function clear(color, avoid)
    for _, other in ipairs(avoid) do
      if near(color, other) then
        return false
      end
    end
    return true
  end

  local function apart(color, alternatives, avoid)
    for _, candidate in ipairs({ color, unpack(alternatives) }) do
      if clear(candidate, avoid) then
        return candidate
      end
    end
    return color
  end

  local diagnostics = { p.red, p.orange, p.cyan, p.green }
  if c.hint and clear(c.hint, diagnostics) then
    p.hint = M.readable(c.hint, p.bg_dark, p.fg)
  else
    p.hint = apart(p.accent, { p.magenta, p.blue }, diagnostics)
  end
  p.modes = {
    normal = p.accent,
    insert = apart(p.green, { p.cyan, p.blue }, { p.accent }),
    visual = apart(p.magenta, { p.blue, p.cyan }, { p.accent }),
    replace = apart(p.red, { p.yellow, p.magenta }, { p.accent }),
    command = apart(p.orange, { p.cyan, p.yellow }, { p.accent }),
  }
  p.modes.terminal = apart(p.cyan, { p.blue, p.green }, { p.accent, p.modes.command })
  p.jump_current = apart(p.orange, { p.red, p.yellow }, { p.accent })

  p.link = p.magenta
  local links = { p.magenta, blend(p.magenta, p.red, 0.5), p.blue, p.orange }
  if c.link then
    table.insert(links, 1, c.link)
  end
  for _, candidate in ipairs(links) do
    if M.hue_distance(candidate, p.accent) >= 60 then
      p.link = M.readable(candidate, p.bg_dark, p.fg)
      break
    end
  end

  p.visual = c.selection or light and M.toward(p.bg, p.accent, p.bg, 1.5) or blend(p.bg, p.accent, 0.26)
  p.cursorline = p.bg_light
  p.float = p.bg_dark
  p.border = c.border_focus or light and M.toward(p.bg, p.accent, p.float, 3) or blend(p.bg, p.accent, 0.6)
  p.border = M.toward(p.border, light and p.fg or p.accent, p.float, 3)
  p.border_dim = c.border or p.line
  p.nontext = light and blend(p.bg, p.comment, 0.55) or blend(p.line, p.comment, 0.35)
  p.reference = blend(p.bg, p.accent, light and 0.12 or 0.16)
  p.menu_sel = blend(p.bg_dark, p.accent, light and 0.22 or 0.3)

  p.search = blend(p.bg, p.green, light and 0.3 or 0.32)
  p.diff_add = blend(p.bg, p.green, tint)
  p.diff_delete = blend(p.bg, p.red, tint)
  p.diff_change = blend(p.bg, p.blue, tint * 0.8)
  p.diff_text = blend(p.bg, p.blue, 0.3)
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
    hint = blend(p.bg, p.hint, 0.1),
    ok = blend(p.bg, p.green, 0.1),
  }
  p.virtual_fg = {
    error = M.readable(p.red, p.virtual.error, p.fg),
    warn = M.readable(p.orange, p.virtual.warn, p.fg),
    info = M.readable(p.cyan, p.virtual.info, p.fg),
    hint = M.readable(p.hint, p.virtual.hint, p.fg),
    ok = M.readable(p.green, p.virtual.ok, p.fg),
  }

  p.terminal = {
    c.background,
    c.red,
    c.green,
    c.yellow,
    c.blue,
    c.magenta,
    c.cyan,
    c.foreground,
    c.muted,
    c.bright_red,
    c.bright_green,
    c.bright_yellow,
    c.bright_blue,
    c.bright_magenta,
    c.bright_cyan,
    c.bright_foreground,
  }

  return p
end

return M
