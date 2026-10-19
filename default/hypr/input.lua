-- https://wiki.hypr.land/Configuring/Basics/Variables/#input

local function read_vconsole()
  local values = {}
  local file = io.open("/etc/vconsole.conf", "r")
  if not file then
    return values
  end

  for line in file:lines() do
    local key, value = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
    if key and value then
      value = value:gsub("%s+#.*$", "")
      value = value:gsub('^"(.*)"$', "%1")
      value = value:gsub("^'(.*)'$", "%1")
      values[key] = value
    end
  end

  file:close()
  return values
end

-- Layouts that can't type Latin letters. Keep in sync with the list in
-- etc/mkinitcpio.conf.d/maitri_hooks.conf.
local non_latin_layouts =
  " af am ara bd bg by et ge gr il in iq ir kg kh kz la lk mk mm mn mv np rs ru sy th tj ua "

local vconsole = read_vconsole()

local kb_layout = vconsole.XKBLAYOUT or "us"
local kb_variant = vconsole.XKBVARIANT or ""
-- CapsLock is the compose key, so Caps Lock itself has to live somewhere else.
-- Both Shifts together is the usual home for it, but it's easy to hit by
-- accident while typing. The _cancel variant sets Caps Lock the same way and
-- releases it on the next lone Shift, so a misfire clears itself.
local kb_options = "compose:caps,shift:both_capslock_cancel"

-- Hyprland resolves keybindings against the first entry in kb_layout, not the
-- layout that's currently active, so maitri's Latin-keysym bindings (SUPER + W
-- and friends) only fire when a Latin layout leads. Installing with a non-Latin
-- one would otherwise leave the desktop unusable.
if non_latin_layouts:find(" " .. kb_layout:match("^[^,]*") .. " ", 1, true) then
  kb_layout = "us," .. kb_layout
  kb_variant = "," .. kb_variant
  -- Reach the original layout with Left Alt + Right Alt.
  kb_options = kb_options .. ",grp:alts_toggle"
end

hl.config({
  input = {
    kb_layout = kb_layout,
    kb_variant = kb_variant,
    kb_model = "",
    kb_options = kb_options,
    kb_rules = "",
    follow_mouse = 1,
    sensitivity = 0,

    repeat_rate = 40,
    repeat_delay = 250,
    numlock_by_default = true,

    touchpad = {
      natural_scroll = false,
      clickfinger_behavior = true,
      scroll_factor = 0.4,
    },
  },

  misc = {
    key_press_enables_dpms = true,
    mouse_move_enables_dpms = true,
  },
})

-- Scroll nicely in the terminal. TUIs launched under their own app-id
-- (org.maitri.agent in the console, org.maitri.btop, TUI.float, ...) no longer
-- carry the terminal's class, but their initial title is still the terminal's
-- name, so they are matched by that to scroll at the same rate.
local function terminal_scroll(class, title, factor)
  o.window(class, { scroll_touchpad = factor })
  o.window({ class = "(org\\.maitri\\..*|TUI\\..*)", initial_title = title }, { scroll_touchpad = factor })
end

terminal_scroll("(Alacritty|kitty|foot)", "(Alacritty|kitty|foot)", 1.5)
terminal_scroll("com.mitchellh.ghostty", "Ghostty", 0.2)
o.window("org.maitri.herdr", { scroll_touchpad = o.cmd_present("ghostty") and 0.2 or 1.5 })
