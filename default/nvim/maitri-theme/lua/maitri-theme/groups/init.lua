local M = {}

function M.get(p)
  local groups = {}
  for _, name in ipairs({ "editor", "syntax", "markdown", "plugins" }) do
    for group, hl in pairs(require("maitri-theme.groups." .. name)(p)) do
      groups[group] = hl
    end
  end
  return groups
end

return M
