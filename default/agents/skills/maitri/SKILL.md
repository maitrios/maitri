---
name: maitri
description: >
  REQUIRED for end-user customization of Linux desktop, window manager, or system config.
  Use when editing ~/.config/hypr/, ~/.config/maitri/,
  ~/.config/alacritty/, ~/.config/foot/, ~/.config/kitty/, or ~/.config/ghostty/.
  Triggers: Hyprland, window rules, animations, keybindings, monitors, gaps, borders,
  blur, opacity, maitri-shell, bar, terminal config, themes, background,
  night light, idle, lock screen, screenshots, reminders, layer rules, workspace
  settings, display config, and user-facing maitri commands. Excludes maitri
  source development through `maitri dev link` workflows.
---

# maitri Skill

Manage [maitri](https://github.com/maitrios/maitri) Linux systems - a beautiful, opinionated Arch Linux desktop with Hyprland, made by Kindness and grown from Omarchy. <!-- rebrand:keep -->

This skill is for end-user customization on installed systems.
It is not for contributing to maitri source code.

## When This Skill MUST Be Used

**ALWAYS invoke this skill for end-user requests involving ANY of these:**

- Editing ANY file in `~/.config/hypr/` (window rules, animations, keybindings, monitors, etc.)
- Editing `~/.config/maitri/shell.json` (status bar layout, widgets)
- Editing terminal configs (alacritty, foot, kitty, ghostty)
- Editing ANY file in `~/.config/maitri/`
- Window behavior, animations, opacity, blur, gaps, borders
- Layer rules, workspace settings, display/monitor configuration
- Themes, backgrounds, fonts, appearance changes
- User-facing `maitri` commands (`maitri theme ...`, `maitri refresh ...`, `maitri restart ...`, etc.)
- Screenshots, screen recording, reminders, night light, idle behavior, lock screen

**If you're about to edit a config file in ~/.config/ on this system, STOP and use this skill first.**

**Do NOT use this skill for maitri development tasks** (editing the maitri source tree, creating migrations, or running `maitri dev ...` workflows).

## Topic Guides

Deeper instructions for common areas live next to this file. Read the
matching guide before starting:

- [`hyprland.md`](hyprland.md) - keybindings, monitors, window rules, and other Hyprland config
- [`plugins.md`](plugins.md) - the maitri shell: bar layout, widgets, plugins, idle behavior
- [`theming.md`](theming.md) - themes, backgrounds, and fonts
- [`hooks.md`](hooks.md) - automation hooks that run on system events
- [`capture.md`](capture.md) - screenshots, screen recordings, OCR text capture, and file sharing
- [`contributing.md`](contributing.md) - reporting maitri bugs and submitting fixes upstream

## Critical Safety Rules

For privileged commands, follow the Privilege Escalation rules below: `sudo` when a terminal is available for the password prompt, `pkexec` when it is not. Do not wrap commands that already manage privilege elevation themselves.

**For end-user customization tasks, NEVER modify anything in `/usr/share/maitri/`** - but READING is safe and encouraged.

This directory is owned by the maitri package. Any local changes will be
overwritten on the next `maitri update`.

```
/usr/share/maitri/     # READ-ONLY - NEVER EDIT (reading is OK)
├── bin/                    # Command source (packaged binaries are on PATH)
├── config/                 # Default config templates
├── themes/                 # Stock themes
├── default/                # System defaults
├── shell/                  # maitri shell source and defaults
├── migrations/             # Update migrations
└── install/                # Installation scripts
```

**Reading `/usr/share/maitri/` is SAFE and useful** - do it freely to:
- Understand how maitri commands work: `maitri theme set --help` or `cat $(which maitri-theme-set)`
- See default configs before customizing: `cat "$MAITRI_PATH/config/maitri/shell.json"`
- Check stock theme files to copy for customization
- Reference default hyprland settings: `cat /usr/share/maitri/default/hypr/*`

**Always use these safe locations instead:**
- `~/.config/` - User configuration (safe to edit)
- `~/.config/maitri/themes/<custom-name>/` - Custom themes
- `~/.config/maitri/hooks/` - Custom automation hooks

If the request is to develop maitri itself, this skill is out of scope. Follow repository development instructions instead of this skill.

## Privilege Escalation

For an interactive script or command run in a visible terminal, use `sudo` for
privileged work. maitri may grant passwordless `sudo` access to particular
commands, and the terminal is the appropriate place to request a password
when one is needed.

Use `pkexec` only when the caller cannot interact with a terminal or cannot
enter a password there, such as a command launched by an agent or a graphical
background process. Do not replace `sudo` with `pkexec` merely because a
command changes system state.

## System Architecture

maitri is built on:

| Component | Purpose | Config Location |
|-----------|---------|-----------------|
| **Arch Linux** | Base OS | `/etc/`, `~/.config/` |
| **Hyprland** | Wayland compositor/WM | `~/.config/hypr/` |
| **maitri shell** | Status bar + notifications (Quickshell) | `~/.config/maitri/shell.json` |
| **Launcher/menus** | Vicinae + the maitri extension | `~/.config/maitri/extensions/maitri-menu.jsonc`, `~/.config/vicinae/settings.json` |
| **Alacritty/Foot/Kitty/Ghostty** | Terminals | `~/.config/<terminal>/` |
| **maitri OSD** | On-screen display | Quickshell plugin |

## Command Discovery

maitri ships a single `maitri` CLI that dispatches to all `maitri-*` binaries via `maitri <group> <action>`. Always prefer this form — it is self-documenting and stable. The underlying `maitri-*` binaries still exist on `PATH` and remain safe to read for source.

```bash
# List every documented command and its summary (--all includes hidden commands)
maitri commands

# Show the commands inside a group
maitri theme --help
maitri refresh --help
maitri restart --help

# Show help for a specific command (does not execute it)
maitri theme set --help

# Machine-readable listing (binary, route, summary, args, aliases)
maitri commands --json

# Read a command's source to understand it
cat $(which maitri-theme-set)
```

### Command Groups

Run `maitri --help` for the full list. The most common groups:

| Group | Purpose | Example |
|-------|---------|---------|
| `maitri refresh` | Reset config to defaults (backs up first) | `maitri refresh shell` |
| `maitri restart` | Restart a service/app | `maitri restart shell` |
| `maitri toggle` | Toggle feature on/off | `maitri toggle nightlight` |
| `maitri theme` | Theme management | `maitri theme set <name>` |
| `maitri bar` | Bar layout and widgets | `maitri bar move maitri.clock --section right` |
| `maitri plugin` | Manage/clone shell plugins | `maitri plugin clone maitri.clock` |
| `maitri hook` | Install automation hooks | `maitri hook install theme-set <script>` |
| `maitri install` | Install optional software / packages | `maitri install docker dbs` |
| `maitri launch` | Launch apps | `maitri launch browser` |
| `maitri capture` | Screenshots and recordings | `maitri capture screenshot` |
| `maitri reminder` | Desktop notification reminders | `maitri reminder 15 "Pickup Jack"` |
| `maitri pkg` | Package management | `maitri pkg add <pkg>` |
| `maitri setup` | Interactive setup wizards | `maitri setup security fingerprint` |
| `maitri update` | System updates | `maitri update` |

## Configuration Locations

Hyprland config lives in `~/.config/hypr/` — see [`hyprland.md`](hyprland.md).
The maitri shell (bar, notifications, plugins, idle) is configured in
`~/.config/maitri/shell.json` — see [`plugins.md`](plugins.md).

### Terminals

```
~/.config/alacritty/alacritty.toml
~/.config/foot/foot.ini
~/.config/kitty/kitty.conf
~/.config/ghostty/config
```

**Command:** `maitri restart terminal`

### Other Configs

| App | Location |
|-----|----------|
| btop | `~/.config/btop/btop.conf` |
| fastfetch | `/etc/fastfetch/config.jsonc` default; `~/.config/fastfetch/config.jsonc` user override |
| lazygit | `~/.config/lazygit/config.yml` |
| starship | `~/.config/starship.toml` |
| git | `~/.config/git/config` |

## Safe Customization Patterns

### Edit User Config Directly

For simple changes, edit files in `~/.config/`:

```bash
# 1. Read current config
cat ~/.config/hypr/bindings.lua

# 2. Backup before changes
cp ~/.config/hypr/bindings.lua ~/.config/hypr/bindings.lua.bak.$(date +%s)

# 3. Make changes with Edit tool

# 4. Apply changes
# - Hyprland: auto-reloads on save, but MUST validate with `hyprctl reload` and `hyprctl configerrors`
# - maitri shell: shell.json and user plugin code under ~/.config/maitri/plugins/ hot-reload on save
# - Menus/launcher: ~/.config/maitri/extensions/maitri-menu.jsonc hot-reloads on save
# - Terminals: apply with `maitri restart terminal` (reloads running terminals; foot picks changes up in new windows)
```

### Reset to Defaults -- ALWAYS SEEK USER CONFIRMATION BEFORE RUNNING

When customizations go wrong:

```bash
# Reset specific config (creates backup automatically)
maitri refresh shell
maitri refresh hyprland

# The refresh command:
# 1. Backs up current config with timestamp
# 2. Copies default from $MAITRI_PATH/config/
# 3. Restarts the component where the refresh needs it (e.g. `refresh shell`)
```

## System Commands

```bash
maitri update                  # Full system update
maitri version                 # Show maitri version
maitri debug --no-sudo --print # Debug info (ALWAYS use these flags)
maitri system lock             # Lock screen
maitri system shutdown         # Shutdown
maitri system reboot           # Reboot
```

**IMPORTANT:** Always run `maitri debug` with `--no-sudo --print` flags to avoid interactive sudo prompts that will hang the terminal.

## Troubleshooting

```bash
# Get debug information (ALWAYS use these flags to avoid interactive prompts)
maitri debug --no-sudo --print

# Reset specific config to defaults
maitri refresh <app>

# Refresh specific config file
# config-file path is relative to ~/.config/
# eg. `maitri refresh config hypr/hyprland.lua` will refresh ~/.config/hypr/hyprland.lua
maitri refresh config <config-file>

# Full reinstall of configs (nuclear option)
maitri reinstall
```

## Decision Framework

When user requests system changes:

1. **Is it a stock maitri command?** Use it directly
2. **Is it a config edit?** Edit in `~/.config/`, never `/usr/share/maitri/`
3. **Is it a theme customization?** Follow [`theming.md`](theming.md); create a NEW custom theme directory
4. **Is it automation?** Follow [`hooks.md`](hooks.md); use `maitri hook install` and the hook `.d` directories
5. **Is it a package install?** Use `maitri pkg add <pkgs...>` (or `maitri pkg aur add <pkgs...>` for AUR-only packages)
6. **Is it built-in shell/plugin code?** Follow [`plugins.md`](plugins.md); clone it with `maitri plugin clone`, never edit the packaged copy
7. **Unsure if command exists?** Run `maitri commands` (or `maitri <group> --help` for one group)

### Reminder Requests

When the user asks to set a reminder, use `maitri reminder <minutes> [message]` directly. Convert natural language durations to minutes and title-case short reminder labels when appropriate.

```bash
maitri reminder 15 "Pickup Jack"
maitri reminder 60 "Check laundry"
maitri reminder show
maitri reminder clear
```

## Out of Scope

This skill intentionally does not cover maitri source development. Do not use this skill for:
- Editing files in `/usr/share/maitri/` (`bin/`, `config/`, `default/`, `shell/`, `themes/`, `migrations/`, etc.)
- Creating or editing migrations
- Running `maitri dev ...` commands

## Example Requests

- "Change my theme to catppuccin" -> `maitri theme set catppuccin`
- "Add a keybinding for Super+E to open file manager" -> Check existing bindings first, call `hl.unbind` if needed, then `o.bind` in `~/.config/hypr/bindings.lua`
- "Configure my external monitor" -> Edit `~/.config/hypr/monitors.lua`
- "Make the window gaps smaller" -> Edit `~/.config/hypr/looknfeel.lua`
- "Turn on night light" -> `maitri toggle nightlight` (for time-based schedules, edit `~/.config/hypr/hyprsunset.conf` profiles, then `maitri restart hyprsunset`)
- "Set a reminder to pickup jack in 15 minutes" -> `maitri reminder 15 "Pickup Jack"`
- "Show my reminders" -> `maitri reminder show`
- "Clear all reminders" -> `maitri reminder clear`
- "Customize the catppuccin theme colors" -> Overlay: put an edited `colors.toml` in `~/.config/maitri/themes/catppuccin/`, then re-apply the theme (see `theming.md`)
- "Run a script every time I change themes" -> Install it with `maitri hook install theme-set <script>`
- "Change how workspace labels are rendered" -> Clone `maitri.workspaces`, which switches the bar to `<username>.workspaces`, then edit the clone
- "Lock after ten minutes" -> Set `idle.lock` to `600` in `~/.config/maitri/shell.json`
- "Reset shell/bar to defaults" -> `maitri refresh shell`
- "Record my screen" -> `maitri screenrecord --fullscreen`, then `maitri screenrecord --stop-recording` (see `capture.md`)
- "Report this bug to maitri" -> Gather diagnostics and a capture of the problem, then file it (see `contributing.md`)
