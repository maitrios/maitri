return {
  {
    "maitri-theme",
    dir = assert(vim.env.MAITRI_PATH, "MAITRI_PATH is not set, so the maitri colorscheme can't load") .. "/default/nvim/maitri-theme",
    lazy = false,
    priority = 1000,
    opts = {
      mode = "{{ mode }}",
      colors = {
        accent = "{{ accent }}",
        selection = "{{ selection }}",
        muted = "{{ muted }}",
        border = "{{ border }}",
        border_focus = "{{ border_focus }}",
        hint = "{{ hint }}",
        link = "{{ link }}",

        background = "{{ background }}",
        dark_background = "{{ dark_background }}",
        darker_background = "{{ darker_background }}",
        lighter_background = "{{ lighter_background }}",

        foreground = "{{ foreground }}",
        dark_foreground = "{{ dark_foreground }}",
        light_foreground = "{{ light_foreground }}",
        bright_foreground = "{{ bright_foreground }}",
        comment = "{{ comment }}",

        red = "{{ red }}",
        green = "{{ green }}",
        yellow = "{{ yellow }}",
        blue = "{{ blue }}",
        magenta = "{{ magenta }}",
        cyan = "{{ cyan }}",
        orange = "{{ orange }}",

        bright_red = "{{ bright_red }}",
        bright_green = "{{ bright_green }}",
        bright_yellow = "{{ bright_yellow }}",
        bright_blue = "{{ bright_blue }}",
        bright_magenta = "{{ bright_magenta }}",
        bright_cyan = "{{ bright_cyan }}",
      },
    },
    config = function(_, opts)
      require("maitri-theme").setup(opts)
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "maitri",
    },
  },
}
