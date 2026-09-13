-- Essential application bindings.
o.bind("SUPER + RETURN", "Terminal", { maitri = "terminal" })
o.bind("SUPER + SHIFT + RETURN", "Browser", { maitri = "browser" })
o.bind("SUPER + SHIFT + F", "File manager", { maitri = "nautilus" })
o.bind("SUPER + ALT + SHIFT + F", "File manager (cwd)", { maitri = "nautilus-cwd" })
o.bind("SUPER + SHIFT + B", "Browser", { maitri = "browser" })
o.bind("SUPER + SHIFT + ALT + B", "Browser (private)", { maitri = "browser --private" })
o.bind("SUPER + SHIFT + N", "Editor", { maitri = "editor" })

if o.preinstalled_bindings_enabled() then
  -- Bindings for preinstalled maitri applications, TUIs, and web apps.
  o.bind("SUPER + ALT + RETURN", "Tmux", { maitri = "terminal-tmux" })
  o.bind("SUPER + CTRL + RETURN", "Herdr", { maitri = "terminal-herdr" })
  o.bind("SUPER + SHIFT + M", "Music", { maitri = "spotify" })
  o.bind("SUPER + SHIFT + ALT + M", "Music TUI", { tui = "cliamp", focus = true })
  o.bind("SUPER + SHIFT + D", "Docker", { tui = "maitri-launch-docker-tui" })
  o.bind("SUPER + SHIFT + G", "Signal", { maitri = "signal" })
  o.bind("SUPER + SHIFT + O", "Obsidian", { launch = "obsidian", focus = "^obsidian$" })
  o.bind("SUPER + SHIFT + W", "Omawrite", { launch = "omawrite" })
  o.bind("SUPER + SHIFT + SLASH", "Passwords", { maitri = "1password" })

  o.bind("SUPER + SHIFT + Y", "YouTube", { webapp = "https://youtube.com/" })
  o.bind("SUPER + SHIFT + ALT + G", "GitHub", { webapp = "https://github.com/", focus = true })
  o.bind("SUPER + SHIFT + I", "Figma", { webapp = "https://www.figma.com/", focus = true })
  o.bind("SUPER + SHIFT + ALT + D", "Discord", { webapp = "https://discord.com/channels/@me", focus = true })
end
