# maitri theming

maitri themes live under `themes/<name>/` in the source tree (installed at
`/usr/share/maitri/themes/<name>/`), with optional user themes under
`~/.config/maitri/themes/<name>/`. A theme normally starts with a
`colors.toml`; maitri generates the active theme files from
`default/themed/*.tpl` when `maitri-theme-set <name>` runs.

Beyond `colors.toml` and hand-written config overrides, every first-party theme
ships:

- `backgrounds/` (users overlay their own via
  `~/.config/maitri/backgrounds/<name>/`; the active image is the
  `~/.local/state/maitri/current/background` symlink)
- `icons.theme`
- `unlock.png`, the Plymouth boot logo `maitri-plymouth-set-by-theme` installs
- `preview-unlock.png`, the thumbnail `maitri-plymouth-switcher` shows; a theme
  without one is left out of `maitri-plymouth-list`

Daybreak also ships a legacy `light.mode` marker, though its `colors.toml`
already sets `mode = "light"`, which takes precedence.

A theme may ship a `preview.png` for the theme switcher, but none of the
first-party themes do: `maitri-theme-switcher` falls back to the first image in
`backgrounds/`.

A theme installed from a git repo is held to a much shorter list; see [What an installed theme may not ship](#what-an-installed-theme-may-not-ship).

## Theme activation flow

`maitri-theme-set <name>` builds a clean staging directory at
`~/.local/state/maitri/current/next-theme`:

1. Copy the first-party theme from `themes/<name>/`.
2. Overlay `~/.config/maitri/themes/<name>/`, in full when the user wrote it and filtered when it came from a git repo, naming anything it dropped on stderr.
3. If needed, generate `colors.toml` from `alacritty.toml`.
4. Run `maitri-theme-set-templates` to render templates into the staging
   theme.
5. Move the staging theme into `~/.local/state/maitri/current/theme`, write
   `~/.local/state/maitri/current/theme.name`, and notify the running shell.

Template rendering only happens when the staged theme has `colors.toml`.
Existing files are never overwritten by a template, so a hand-written
`themes/<name>/shell.toml` or `hyprland.lua` wins over
`default/themed/shell.toml.tpl` or `hyprland.lua.tpl`.

User templates in `~/.config/maitri/themed/*.tpl` are processed before the
built-in templates. If a user template has the same output filename as a
built-in template, the built-in output is skipped.

After activation, `maitri-theme-set` fires the `theme-set` hook
(`~/.config/maitri/hooks/theme-set*`, theme name in `$1`) and dispatches a
parallel retint of running apps — terminals, Hyprland, btop, editors,
and the rest of the `post_theme_commands` list in `bin/maitri-theme-set`.
Making a new app follow theme changes means adding its restart/retint command
to that list. Runs serialize on a `flock`, so scripted theme changes queue
instead of racing.

## What an installed theme may not ship

`themes/<name>/` in this repo is maitri's own code and is trusted. So is a theme the user wrote by hand in `~/.config/maitri/themes/<name>/`: it is their machine and their file, and both stage in full.

`maitri theme install <url>` is different. It clones a stranger's git repo straight into that same directory, so the contents are whatever the theme author pushed. `maitri-theme-set` tells the two apart the way `maitri-theme-extras` already does — a `.git` directory means it was cloned, while a plain directory or a symlink to a working copy is the user's own — and from a cloned one it drops only what can run code or fake what the browser shows:

- any `*.lua` — Hyprland `require`s a theme's `hyprland.lua` and `gum_env.lua` at login, and Neovim loads its `neovim.lua` at startup
- `alacritty.toml`, `foot.ini`, `ghostty.conf`, `kitty.conf` — each names the program the terminal launches
- `vscode.json` — names the extension `maitri-theme-set-vscode` installs, and a VS Code extension is arbitrary JavaScript
- `emacs-theme.el` — Elisp, which Emacs runs when it loads the theme
- `herdr.toml` — `maitri-theme-set-herdr` splices it into herdr's own `config.toml`, which runs commands
- `glamour.json` — gh and glow write its prefix strings to the terminal as they are, so an escape sequence in one could rewrite the clipboard
- `firefox-userChrome.css`, `firefox-userContent.css` — browser chrome CSS can draw over the URL bar, which is enough to fake the address a page shows

A theme's `gtk.css` is kept, but `maitri-theme-set-gtk` only splices it into the user's GTK config when every line is an `@define-color name #RRGGBB;`, a comment or blank; otherwise GTK apps drop back to their own look. With the `skip-gtk-theme-changes` toggle on, `maitri-theme-set-gtk` leaves GTK alone and the colours of the last theme it applied stay in place. It rewrites gtk.css by moving a new copy into place, which keeps the file's mode but not ACLs or extended attributes; a symlinked or hard-linked gtk.css is left alone with a hint instead.

Symlinks are dropped with them, at any depth; in a cloned theme they point wherever the theme author chose. Everything a cloned theme ships that is colour is kept, including files maitri would otherwise have generated — `btop.theme`, `helix.toml`, `shell.toml`, `zed.json`, `jetbrains.icls`, `icons.theme`, `keyboard.rgb` and the rest — so a theme can still say exactly how it wants each app to look. What is dropped gets generated from `default/themed/*.tpl` instead, and is named on stderr.

A denylist is only right while it is maintained. Adding a template for another terminal, or for another editor whose theme file runs code (Neovim's Lua, Emacs' Elisp; Zed and JetBrains only read colours), means adding it to `INSTALLED_THEME_DENIED` in `bin/maitri-theme-set`; `test/shell.d/theme-staging-test.sh` fails on any `default/themed/*.tpl` whose output is recorded as neither code nor colour, so a new template cannot be added without that decision being made.

A theme predating `colors.toml` is not left without a palette: its `alacritty.toml` is read through `maitri-theme-colors-from-alacritty` into a scratch directory and only the resulting `colors.toml` is staged, so the colors survive and the terminal config does not.

The restriction lives in `maitri-theme-set` rather than in `maitri-theme-install` on purpose. Filtering at staging also covers themes installed before the rule existed and files a theme gains later through `maitri theme update`.

What this does not cover: a theme distributed as an archive rather than a git repo, extracted into `~/.config/maitri/themes/` by hand, is indistinguishable from one the user wrote and stages in full. `maitri theme install` only takes git URLs, so the supported path is always filtered, but the check is a statement about where a theme came from and not a sandbox.

## `colors.toml`

`colors.toml` provides the palette keys used by templates. Keys are grouped
semantic-first: accent/selection/muted, then the backgrounds, then the
foregrounds, then the named colors:

```toml
mode = "dark"

accent = "#7aa2f7"
selection = "#292e42"
muted = "#414868"
border = "#5b6382"
border_focus = "#4f6aa8"
hint = "#7aa2f7"
link = "#bb9af7"

background = "#1a1b26"
dark_background = "#13141c"
darker_background = "#0e0e14"
lighter_background = "#24283b"

foreground = "#a9b1d6"
dark_foreground = "#565f89"
light_foreground = "#b4bee6"
bright_foreground = "#c0caf5"

red = "#f7768e"
blue = "#7aa2f7"
```

Any key can be referenced from a template with `{{ key }}`. The foundational
shell palette is loaded from:

- `foreground` — primary readable text color
- `background` — primary background color
- `accent` — the theme's highlight color. Falls back to `blue` (`color4`).
- `muted` — structural de-emphasis: dividers, borders, separators, indent
  guides, scrollbar tracks; also serves as ANSI `color8`. It is a *line* color,
  not a text color — in the shipped palettes it sits at 1.5–3.9:1 against
  `background`, so text set in it is unreadable.
- `dark_foreground` — de-emphasized *text*: comments, placeholders, line
  numbers, secondary labels. This is the key templates should use whenever the
  value ends up as glyphs a person reads. Falls back to `color8`, then
  `foreground`, so it always resolves.
- `comment` — the same value as `dark_foreground`, under the name editors use.
  Falls back to `dark_foreground` moved toward `foreground` until it clears
  4.5:1, so a theme with only `color0` to `color15` doesn't get a `color8`
  comment at 2:1. When `foreground` itself is under 4.5:1, the fallback stops
  at `foreground`, so comments are never louder than body text.
- `selection` — the selection fill: a tint of `accent`, light enough that
  `foreground` stays readable on it. Text on `selection` is `foreground` (or
  `bright_foreground`). `accent` isn't a text color there: on daybreak it's
  3.8:1. A theme with neither `selection` nor `selection_background` gets
  `background` mixed 26% toward `accent` (or `blue`), and further until it
  sits 1.5:1 off the background, so a selection is never plain grey.
- `border` — neutral lines that need to be seen: input outlines, panel and
  table edges. Unlike `muted` it clears 3:1 against `background`. Falls back to
  `muted` moved toward `foreground` until it clears 3:1.
- `border_focus` — the focused or floating border, a step of `accent` toward
  `background` that clears 3:1. Falls back to `background` mixed 60% toward
  `accent`, then moved back toward `accent` until it clears 3:1, the same
  step the Neovim palette takes. If that lands within 1.3:1 of the accent
  (an accent that only just clears 3:1 itself), it steps the other way, from
  the accent toward black on a light background or white on a dark one,
  until it sits 1.3:1 off the accent.
- `hint` — hint diagnostics. It's `accent` unless the accent sits near `red`,
  `orange`, `cyan` or `green` (error, warning, info, ok), when it's the next
  hue that doesn't. Falls back to `accent`, so a theme whose accent is orange,
  red or cyan should set `hint` itself.
- `link` — links, drawn underlined. It stays at least 60° of hue from
  `accent` so a link never reads as a heading. Falls back to the first of
  `blue`, `magenta`, `magenta` mixed half toward `red`, and `orange` that is
  60° clear of the accent, the order the Neovim palette tries, moved toward
  `foreground` until it clears 4.5:1.
- `urgent` / `red` / `color1`

Themes and user templates using the legacy short names remain supported.
Canonical names take precedence when both forms are defined, and resolved
canonical values are also exposed through their legacy names:

| Canonical | Legacy |
|-----------|--------|
| `background` | `bg` |
| `dark_background` | `dark_bg` |
| `darker_background` | `darker_bg` |
| `lighter_background` | `lighter_bg` |
| `foreground` | `fg` |
| `dark_foreground` | `dark_fg` |
| `light_foreground` | `light_fg` |
| `bright_foreground` | `bright_fg` |

The neutral ramp is centered on `background -> bright_foreground`. Dark themes
should read from darkest to lightest; light themes should read from lightest to
darkest. Terminal and editor cursors use `bright_foreground`; there is no
separate cursor palette key. `selection` is the text-selection background stop
in that ramp; maitri derives `selection_background = selection` and
`selection_foreground = bright_foreground`. Use
`maitri dev theme-preview [theme]` to inspect that ramp, including
`dark_background`, `darker_background`, and a selected-text sample.

### The hue model

The first-party themes share one set of syntax hues, and each theme's accent
takes the slot nearest to it. `test/shell.d/theme-hue-test.sh` holds every
shipped theme to these rules (hue angles are HSL, the same measure the Neovim
palette uses to keep links off the accent):

- `red`, `orange`, `yellow`, `green`, `cyan`, `blue` and `magenta` sit at
  355°, 25°, 56°, 125°, 172°, 220° and 270°, so no two are closer than 30°.
  They're built at one OKLCH chroma (0.14) in a narrow lightness band, so no
  hue shouts over the others. The slot the accent takes keeps the accent's
  own chroma. Where sRGB can't reach that chroma (blue on
  dark, cyan and yellow on light) it gets as close as it can, so the test
  allows a spread of 0.03 on dark themes and 0.06 on daybreak.
- The syntax hue nearest the accent *is* the accent: amethyst's and daybreak's
  `magenta`, spark's `blue`, harbor's `cyan`, ember's `orange`, garnet's `red`.
  Every other syntax hue is at least 30° from it, so the accent never sits a
  few degrees off a code color. It shows up in each theme's code on purpose.
- `link` is at least 60° from the accent and `hint` at least 40° from `red`,
  `orange`, `cyan` and `green`. (Neovim's own guard on a `hint` is a distance
  in RGB rather than hue, which every shipped theme clears by a wide margin.)
- Every syntax color, `link`, `hint` and `dark_foreground` clears 4.5:1, and
  `border` and `border_focus` clear 3:1. Daybreak, the light theme, uses the
  same angles at its own lightness and is measured against
  `dark_background`, the float surface, so text holds up there too.
- The `bright_*` colors are the same hues, a step lighter on dark themes. On
  daybreak they also clear 4.5:1, since terminals draw bold text in them.

A user theme doesn't have to follow any of this. The fallbacks above fill in
the new roles from the ones it already has.

## Template placeholders

Templates are plain files ending in `.tpl`. `maitri-theme-set-templates`
replaces placeholders with values from `colors.toml`.

### Color placeholders

For a color key such as `accent = "#7aa2f7"`:

| Placeholder | Output |
|-------------|--------|
| `{{ accent }}` | `#7aa2f7` |
| `{{ accent_strip }}` | `7aa2f7` |
| `{{ accent_rgb }}` | `122,162,247` |

### Color mixing

`mix`, `mix_strip`, and `mix_rgb` blend two hex colors by a fraction or
percentage:

```text
{{ mix background foreground 15% }}
{{ mix_strip background accent 0.35 }}
{{ mix_rgb color0 color7 50 }}
```

### Readable text

`readable` moves a color toward `foreground` until it clears 4.5:1 on a
surface, given as a key or as the same arguments `mix` takes:

```text
{{ readable green background }}
{{ readable green dark_background accent 30% }}
```

Use it for text drawn on a fill the theme doesn't define, such as git colors
on a selected row. On a fill where the color already clears 4.5:1 it comes
back unchanged.

`outline` takes the same arguments and stops at 3:1, for borders and other
lines, such as `{{ outline border lighter_background background 50% }}` for an
outline on a raised surface.

### Gradient helpers

Some theme keys can be either a solid color or a Hyprland-style gradient:

```toml
hyprland_active_border = "rgba(33ccffee) rgba(00ff99ee) 45deg"
```

Gradient helper placeholders understand those values:

| Helper | Use | Example output |
|--------|-----|----------------|
| `{{ hypr_gradient hyprland_active_border accent }}` | Hyprland Lua config | `{ colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 }` |
| `{{ shell_gradient hyprland_active_border accent }}` | shell border tokens | `rgba(33ccffee) rgba(00ff99ee) 45deg` |
| `{{ gradient_start hyprland_active_border accent }}` | flat-color-only consumers | `#33ccff` |

The second argument is a fallback. For example,
`{{ shell_gradient hyprland_active_border accent }}` means: use
`hyprland_active_border` if the theme defines it; otherwise use `accent`.
The helper does not choose the first color unless you use `gradient_start`.

## `shell.toml`

`shell.toml` contains shell surface roles, control states, spacing, typography,
and bar sizing. The default generated file comes from
`default/themed/shell.toml.tpl`.

Themes can override the entire generated file by shipping `shell.toml`, or just
one section by shipping `shell.<section>.toml`. For example,
`shell.lock.toml` replaces only the `[lock]` section after the default
`shell.toml` has been generated:

```toml
text        = "#ffffff"
placeholder = "#ffffff"
border      = "#ffffff"
```

The filename decides the target section, so the `[lock]` header is optional.

The running shell reads `shell.toml` into two QML singletons:

- `Color` for palette and surface roles like `Commons.Color.menu.border`.
- `Style` for controls, spacing, font scale, corner radius, and bar sizing.

### Borders

Shell border tokens accept either a solid color or a gradient in the same key:

```toml
[notifications]
border = "#7aa2f7"
```

or:

```toml
[notifications]
border = "rgba(33ccffee) rgba(00ff99ee) 45deg"
```

Do not add a separate `border-gradient` key for new themes. The parser still
accepts `border-gradient` and `*-border-gradient` for compatibility with older
configs, but the canonical form is the border key itself.

Border alphas apply to solid borders and to every gradient stop:

```toml
[notifications]
border       = "rgba(33ccffee) rgba(00ff99ee) 45deg"
border-alpha = 0.8
```

If a color stop already includes alpha, the stop alpha and `border-alpha` are
combined.

### Border widths

Border widths accept CSS-style lists:

```toml
border-width = 2          # all sides
border-width = "2 4"      # top/bottom, right/left
border-width = "2 4 6"    # top, right/left, bottom
border-width = "2 4 6 8"  # top, right, bottom, left
```

Per-side keys override the list:

```toml
[notifications]
border-width = 2
border-width-left = 6
```

That gives notifications a 2px border on the top, right, and bottom, and a 6px
left edge.

State-specific borders follow the same pattern. A selected menu row can use a
different width from the card border:

```toml
[menu]
selected-border = "accent"
selected-border-width = "1 1 1 4"
```

For state-specific surfaces such as lock and polkit, the token name prefixes
the width key:

```toml
[lock]
border-active = "rgba(33ccffee) rgba(00ff99ee) 45deg"
border-active-width-left = 6
```

### Control borders

`[controls]` governs shared controls such as buttons, dropdowns, text fields,
toggles, and cursor rows. Each state has a fill color, optional border value,
border width, and border alpha:

```toml
[controls]
normal-color        = "#a9b1d6"
normal-border       = "#a9b1d6"
normal-border-width = 1
normal-border-alpha = 0.4

hover-cursor-color        = "#a9b1d6"
hover-cursor-border       = "#a9b1d6"
hover-cursor-border-width = 1
hover-cursor-border-alpha = 0.25
```

The `*-border` keys can also be gradients:

```toml
[controls]
focus-border = "rgba(33ccffee) rgba(00ff99ee) 45deg"
focus-border-width = "2 2 2 4"
```

Set a border width to `0` to keep the fill but remove that state border.

### Surface sections

Common shell sections include:

- `[bar]`
- `[controls]`
- `[popups]`
- `[tooltip]`
- `[notifications]`
- `[launcher]`
- `[menu]`
- `[polkit]`
- `[lock]`
- `[image-picker]`
- `[spacing]`
- `[font]`

Clipboard and emojis inherit menu tokens. Popups are used by bar flyouts,
dropdowns, OSD, and popup cards.

## QML border API

Plugin and shell QML should use `BorderSurface` for theme-aware borders:

```qml
import qs.Commons
import qs.Ui

BorderSurface {
  color: Commons.Color.popups.background
  borderSpec: Border.surfaceSpec("popups", "border", Commons.Color.popups.border, 2)
  padding: Style.spacing.popupPadding

  Item {
    anchors.fill: parent
    anchors.topMargin: parent.contentTopInset
    anchors.rightMargin: parent.contentRightInset
    anchors.bottomMargin: parent.contentBottomInset
    anchors.leftMargin: parent.contentLeftInset
  }
}
```

Use `Border.surfaceSpec(section, token, fallbackColor, fallbackWidth)` for
shell theme tokens, `Border.controlSpec(state, foreground, accent)` for shared
controls, and `Border.flat(color, width)` for a deliberate local border that
should not be overridden by the active theme. `Commons.Color.<section>.border` is the
flat first-stop color for consumers that cannot render full border specs.

## Hyprland templates

Hyprland theme output is generated from `default/themed/hyprland.lua.tpl`.
Use `hypr_gradient` for border values because Hyprland's Lua config wants a
Lua string for solid colors and a Lua table for gradients:

```lua
local active_border_color = {{ hypr_gradient hyprland_active_border accent }}
```

For a solid fallback this renders:

```lua
local active_border_color = "#7aa2f7"
```

For a gradient it renders:

```lua
local active_border_color = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 }
```

## gh and glow

`default/themed/glamour.json.tpl` renders a glamour style to
`~/.local/state/maitri/current/theme/glamour.json` on every theme set, so gh,
glow and other glamour-based Markdown renderers draw in the theme: headings on
the accent ramp, links in `link`, quote bars and rules in `border`, and code on
the shared syntax mapping.

maitri's fish config points them at it with two marked lines
(`# maitri:glamour-style`): `GLAMOUR_STYLE` when gh or glow is installed, and
`GLOW_STYLE` when glow is. Each is only set when it isn't already, so a style you
export yourself, from the session environment, `conf.d` or a universal variable,
wins. The file's path never changes, so gh and glow pick up a new theme on their
next run. One catch: glow ranks `GLOW_STYLE` above the `style:` key in its own
`glow.yml`, so to use a style from there, set `GLOW_STYLE` to it yourself or
drop the marked line.

## Zed, JetBrains and Emacs

Each editor gets a theme rendered from `colors.toml`, installed by its own
`maitri-theme-set-*` hook only when that editor is on the machine. None of the
hooks touch the editor's own settings, so pick the theme once:

- **Zed** — `maitri-theme-set-zed` writes `~/.config/zed/themes/maitri.json`
  (under `XDG_CONFIG_HOME` when it's set), and Zed reloads it live. Set
  `"theme": "maitri"` in Zed's `settings.json`.
- **JetBrains** — `maitri-theme-set-jetbrains` copies `maitri.icls` into
  `colors/` in every versioned IDE config dir under `~/.config/JetBrains/` (and
  Android Studio's under `~/.config/Google/`), with a light parent scheme on
  light themes. Pick `maitri` under Settings → Editor → Color Scheme. The IDE
  reads the file at startup, so a theme change shows after a restart.
- **Emacs** — `maitri-theme-set-emacs` installs `maitri-theme.el` into
  `themes/` under the dir Emacs uses: the XDG dir (`~/.config/emacs`) when it
  exists and none of `~/.emacs.d`, `~/.emacs` or `~/.emacs.el` do, otherwise
  `~/.emacs.d`, so a fresh machine gets `~/.emacs.d`. Load it from your init
  file:

  ```elisp
  (add-to-list 'custom-theme-load-path (locate-user-emacs-file "themes"))
  (load-theme 'maitri t)
  ```

  A running Emacs picks up new colours on the next `load-theme`.

## Neovim

`default/themed/neovim.lua.tpl` renders a Lazy plugin spec that loads maitri's
own colorscheme from `default/nvim/maitri-theme` and hands it the theme's
`colors.toml` values as `opts`. The colorscheme works out everything else from
those roles in Lua: diff, search and selection tints, the heading ramp (H1 in
`accent`, each lower level a step toward `foreground`, all bold), float and
border colors, the lualine theme and `g:terminal_color_0..15`. It starts from
the theme's `selection` for Visual, `border_focus` for float borders, `border`
for window separators, and `hint`, `link` and `comment`, so Neovim and the
other apps begin from the same values. A `link` within 60° of the accent, a
`hint` too close to a diagnostic color, a `selection` under 1.3:1 against the
background or a `border_focus` that's just the accent is
replaced with what the colorscheme works out from the base roles, and any of
them that falls under its floor on Neovim's own surfaces is moved as described
below, so on dark themes `comment` reads a shade lighter in Neovim than
elsewhere.

Floats, popup menus, the statusline and code blocks sit on their own surface,
stepped 1.22:1 off `background`, so they read as separate without leaning on
their borders. Light themes step down from `dark_background`, with the
cursorline at 1.16:1. Dark themes step up from `background` toward
`lighter_background` (when it's lighter than the background and clear of
`foreground`) and then `foreground`, which keeps them dark. On dark themes the
cursorline sits a further 1.05:1 above the float, so a window with a raised
background still shows it, chips and section blocks 1.1:1 above, and `muted`
lines are lifted to 2:1 on the float so scrollbars and indent guides survive
there. Any text color (`accent`, `comment`, `hint`, `link` and the syntax
colors) that falls under 4.5:1 on the hardest text surface (the float on
light themes, the cursorline on dark ones) is moved toward `foreground` until
it clears that, so a user theme with a pale `orange` still reads. The float
border is moved toward `accent` (toward `foreground` on light themes) until it
clears 3:1 on the float. The terminal colors Neovim hands to
`:terminal` stay exactly as the theme sets them. When `accent` sits close to
`red`, `orange`, `cyan` or `green`, diagnostic hints use `magenta` (or `blue`)
instead, and lualine's other modes step off any hue that matches the accent,
so a hint never looks like a warning.

`~/.config/nvim/lua/plugins/theme.lua` links to the rendered file, and the
`theme-hotreload` plugin swaps it when the theme changes. That reload finds
the colorscheme by the spec's name, `maitri-theme`, so keep the name stable.

To change the colorscheme for every theme, copy the template to
`~/.config/maitri/themed/neovim.lua.tpl` and point its `dir` at your own copy
of `default/nvim/maitri-theme`.

## Launcher icons

`default/icons/` holds maitri's launcher icons, one file per app, named after
the `Icon=` key in that app's `.desktop` file (`vscode.png` for `Icon=vscode`,
`Alacritty.png` for `Icon=Alacritty`). Icons are 256px PNGs with every
ancillary chunk stripped; an SVG named the same way works too.

The set is opt-in, from Style > App Icons in the menu or the commands:

- `maitri-icons-set` walks the launchers the way the desktop resolves them: the
  user dir (`$XDG_DATA_HOME/applications`, or `~/.local/share/applications`)
  first, then each `$XDG_DATA_DIRS/applications`. It reads only the
  `[Desktop Entry]` group. For every launcher the menu shows (no
  `NoDisplay=true` or `Hidden=true` there) whose `Icon=` key has a file in
  `default/icons/` (a trailing `.png`, `.svg` or `.xpm` on the key is ignored),
  it points each `Icon=` line with that key at the file's absolute path. A
  launcher in a system dir gets a copy in the user dir; one already in the user
  dir is edited in place after its original is saved.
- Running `maitri-icons-set` again swaps launchers installed since, and
  launchers whose icon was put back by hand or by `maitri-refresh-applications`
  (which runs it again itself when a swap is on). It also keeps each copy in
  step with its system launcher: an app update refreshes the copy, and an app
  that's gone takes its copy with it. A copy you edited is left as you wrote it;
  if its app is gone, only its icon goes back. It writes the manifest after
  every change, so a run cut short leaves nothing restore can't find, and it
  stops without touching anything when `default/icons/` is missing.
- `maitri-icons-restore` undoes every swap still in place and clears the
  record. Given desktop file names (`maitri-icons-restore code`, with or
  without `.desktop`), it undoes only those.
- Removing a swapped app from the launcher's Remove action drops its swap
  first, along with the copy even if you edited it, so the app itself is
  uninstalled rather than just the icon override.

The record lives in `~/.local/state/maitri/icons/`:

- `manifest`: one tab-separated line per launcher it changed,
  `<desktop file name>\t<created|replaced>\t<icon path>\t<sha256>`, where the
  hash is of the launcher as `set` wrote it, or `-` when a copy from before the
  hash column had already been edited. On its first run `set` hashes three-field
  lines from before that column, comparing each copy with its system launcher.
- `originals/<desktop file name>`: the user-dir launcher as it was before a
  `replaced` swap.

Restore only touches a launcher whose `Icon=` still points at the recorded
icon path; anything else changed since is left as it is. When the launcher
still matches its hash, it deletes a `created` copy and moves a `replaced`
original back. When it was edited after the swap, or its original is missing,
only the `Icon=` lines go back to the key, so the edits stay.

The icon path is absolute, so a swap made under `maitri dev link` points at the
checkout until it is restored and set again.

## Adding or overriding theme files

- Add palette values to `themes/<name>/colors.toml`.
- Hand-written overrides work everywhere except a `.lua`, a terminal config or a `vscode.json` in a theme cloned from a git repo; see [What an installed theme may not ship](#what-an-installed-theme-may-not-ship).
- Prefer generated files when the theme can be expressed with templates.
- Add a hand-written file in `themes/<name>/` only when that theme needs to
  override the generated output entirely.
- Add a new built-in template under `default/themed/<file>.tpl` when every
  theme should generate that file.
- Add a user-wide template under `~/.config/maitri/themed/<file>.tpl` when a
  local customization should apply across themes.

When changing templates or theme helpers, run focused tests such as:

```bash
./test/cli
./test/shell
```
