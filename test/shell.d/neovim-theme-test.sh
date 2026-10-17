#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

if ! command -v nvim >/dev/null; then
  skip "nvim is not installed; skipping the Neovim colorscheme test"
  exit 0
fi

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

cat >"$test_tmp/check.lua" <<'LUA'
local rendered, theme = arg[1], arg[2]

local function fail(message)
  io.stderr:write(theme .. ": " .. message .. "\n")
  os.exit(1)
end

local spec = dofile(rendered)
local plugin, lazyvim = spec[1], spec[2]

if plugin[1] ~= "maitri-theme" then
  fail("the first spec is not the maitri-theme plugin")
end
if lazyvim[1] ~= "LazyVim/LazyVim" or lazyvim.opts.colorscheme ~= "maitri" then
  fail("LazyVim is not pointed at the maitri colorscheme")
end

vim.opt.rtp:prepend(plugin.dir)
plugin.config(nil, plugin.opts)
vim.cmd.colorscheme(lazyvim.opts.colorscheme)

if vim.g.colors_name ~= "maitri" then
  fail("colors_name is " .. tostring(vim.g.colors_name))
end
if vim.o.background ~= plugin.opts.mode then
  fail("background is " .. vim.o.background .. ", theme mode is " .. plugin.opts.mode)
end

local function hl(name)
  return vim.api.nvim_get_hl(0, { name = name, link = false })
end

local function hex(value)
  return value and string.format("#%06x", value) or "unset"
end

local colors = plugin.opts.colors
local palette = require("maitri-theme.palette")
local p = require("maitri-theme").palette()
if hex(hl("Normal").bg) ~= colors.background:lower() then
  fail("Normal background is " .. hex(hl("Normal").bg))
end
if hex(hl("RenderMarkdownH1").fg) ~= p.accent:lower() then
  fail("the H1 heading is not the accent")
end

for _, other in ipairs({ "DiagnosticError", "DiagnosticWarn", "DiagnosticInfo" }) do
  if palette.distance(hex(hl("DiagnosticHint").fg), hex(hl(other).fg)) < 48 then
    fail("DiagnosticHint is too close to " .. other)
  end
end

for _, kind in ipairs({ "Error", "Warn", "Info", "Hint", "Ok" }) do
  local group = hl("DiagnosticVirtualText" .. kind)
  local ratio = palette.contrast(hex(group.fg), hex(group.bg))
  if ratio < 4.5 then
    fail(string.format("DiagnosticVirtualText%s is %.2f:1", kind, ratio))
  end
end

local border = palette.contrast(hex(hl("FloatBorder").fg), hex(hl("NormalFloat").bg))
if border < 3 then
  fail(string.format("FloatBorder is %.2f:1 on NormalFloat", border))
end

local forbidden = { [colors.green:lower()] = "green", [colors.yellow:lower()] = "yellow" }
for level = 1, 6 do
  for _, name in ipairs({ "RenderMarkdownH" .. level, "RenderMarkdownH" .. level .. "Bg", "@markup.heading." .. level .. ".markdown" }) do
    local group = hl(name)
    if not group.bold then
      fail(name .. " is not bold")
    end
    if forbidden[hex(group.fg)] then
      fail(name .. " is " .. forbidden[hex(group.fg)])
    end
  end
end

for i = 0, 15 do
  local color = vim.g["terminal_color_" .. i]
  if type(color) ~= "string" or not color:match("^#%x%x%x%x%x%x$") then
    fail("terminal_color_" .. i .. " is " .. tostring(color))
  end
end

local lualine = require("lualine.themes.maitri")
if lualine.normal.a.bg ~= p.accent then
  fail("the lualine normal mode is not the accent")
end
for _, mode in ipairs({ "insert", "visual", "replace", "command", "terminal" }) do
  if palette.distance(lualine[mode].a.bg, lualine.normal.a.bg) < 48 then
    fail("the lualine " .. mode .. " mode is too close to normal")
  end
end
LUA

for theme_dir in "$ROOT"/themes/*/; do
  theme=$(basename "$theme_dir")
  home="$test_tmp/$theme"
  next_theme="$home/.local/state/maitri/current/next-theme"
  mkdir -p "$next_theme"
  cp "$theme_dir/colors.toml" "$next_theme/colors.toml"

  HOME="$home" MAITRI_PATH="$ROOT" PATH="$ROOT/bin:$PATH" bash "$ROOT/bin/maitri-theme-set-templates"

  rendered="$next_theme/neovim.lua"
  [[ -f $rendered ]] || fail "$theme renders neovim.lua"
  ! grep -q '{{' "$rendered" || fail "$theme leaves no unrendered placeholders in neovim.lua" "$(grep -n '{{' "$rendered")"

  if ! output=$(MAITRI_PATH="$ROOT" nvim --clean --headless -l "$test_tmp/check.lua" "$rendered" "$theme" 2>&1); then
    fail "$theme loads the maitri colorscheme in Neovim" "$output"
  fi
  [[ -z $output ]] || fail "$theme loads the maitri colorscheme without messages" "$output"
  pass "$theme loads the maitri colorscheme in Neovim"
done
