local p = require("maitri-theme").palette()

local function mode(color)
  return {
    a = { fg = p.bg, bg = color, gui = "bold" },
    b = { fg = color, bg = p.bg_light },
    c = { fg = p.fg_dim, bg = p.bg_dark },
  }
end

return {
  normal = mode(p.modes.normal),
  insert = mode(p.modes.insert),
  visual = mode(p.modes.visual),
  replace = mode(p.modes.replace),
  command = mode(p.modes.command),
  terminal = mode(p.modes.terminal),
  inactive = {
    a = { fg = p.comment, bg = p.bg_dark },
    b = { fg = p.comment, bg = p.bg_dark },
    c = { fg = p.comment, bg = p.bg_dark },
  },
}
