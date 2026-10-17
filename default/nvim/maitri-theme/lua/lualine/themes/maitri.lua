local p = require("maitri-theme").palette()

local function mode(color)
  return {
    a = { fg = p.bg, bg = color, gui = "bold" },
    b = { fg = color, bg = p.bg_light },
    c = { fg = p.fg_dim, bg = p.bg_dark },
  }
end

return {
  normal = mode(p.accent),
  insert = mode(p.green),
  visual = mode(p.magenta),
  replace = mode(p.red),
  command = mode(p.orange),
  terminal = mode(p.cyan),
  inactive = {
    a = { fg = p.comment, bg = p.bg_dark },
    b = { fg = p.comment, bg = p.bg_dark },
    c = { fg = p.comment, bg = p.bg_dark },
  },
}
