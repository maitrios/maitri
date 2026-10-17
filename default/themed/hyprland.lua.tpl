local active_border_color = {{ hypr_gradient hyprland_active_border accent }}
local inactive_border_color = {{ hypr_gradient hyprland_inactive_border border }}
local shadow_color = "{{ mode }}" == "light" and "rgba({{ foreground_strip }}33)" or "rgba({{ darker_background_strip }}88)"

hl.config({
  general = {
    col = {
      active_border = active_border_color,
      inactive_border = inactive_border_color,
    },
  },

  decoration = {
    shadow = {
      color = shadow_color,
    },
  },

  group = {
    col = {
      border_active = active_border_color,
      border_inactive = inactive_border_color,
      border_locked_active = "rgb({{ orange_strip }})",
      border_locked_inactive = inactive_border_color,
    },

    groupbar = {
      text_color = "rgb({{ foreground_strip }})",
      text_color_inactive = "rgb({{ comment_strip }})",
      col = {
        active = "rgb({{ selection_strip }})",
        inactive = "rgb({{ dark_background_strip }})",
        locked_active = "rgb({{ mix_strip background orange 30% }})",
        locked_inactive = "rgb({{ dark_background_strip }})",
      },
    },
  },
})
