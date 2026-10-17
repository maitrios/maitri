local M = {}

M.options = nil

function M.setup(opts)
  M.options = opts or {}
end

function M.palette()
  if not M.options or not M.options.colors then
    error("maitri-theme: setup() was not called with the theme colors")
  end
  return require("maitri-theme.palette").build(M.options.colors, M.options.mode)
end

function M.load()
  local p = M.palette()

  vim.g.colors_name = nil
  vim.o.background = p.mode
  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end
  vim.o.termguicolors = true

  for name, hl in pairs(require("maitri-theme.groups").get(p)) do
    vim.api.nvim_set_hl(0, name, hl)
  end

  for i, color in ipairs(p.terminal) do
    vim.g["terminal_color_" .. (i - 1)] = color
  end

  vim.g.colors_name = "maitri"
end

return M
