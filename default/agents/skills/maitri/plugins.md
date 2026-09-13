# maitri Shell: Bar, Plugins, and Idle

Read this before changing the status bar, notifications, shell plugins,
widgets, or idle/lock behavior.

The bar, notification daemon, settings panel, and assorted overlays all run
inside a single long-running Quickshell process (`maitri-shell`).

```
~/.config/maitri/shell.json             # User overrides: bar, plugins, idle
~/.config/maitri/plugins/<plugin-id>/   # User-owned shell plugins
$MAITRI_PATH/config/maitri/shell.json  # Canonical defaults
```

The shell hot-reloads `shell.json` on save — no restart needed for layout
changes. `idle.screensaver` and `idle.lock` are seconds since user idle began.

**Commands:** `maitri restart shell`, `maitri refresh shell`

## Bar Layout

Use the `maitri bar` group to move and manage widgets:

```bash
maitri bar move maitri.clock --section right
```

For layout edits beyond what the commands cover, edit the bar configuration
in `~/.config/maitri/shell.json`; it hot-reloads on save.

## Customizing Built-In Plugins and Widgets

To customize a built-in bar widget, never edit `$MAITRI_PATH/shell/plugins/`.
Clone it into the user plugin directory instead:

```bash
maitri plugin clone maitri.workspaces
# Edit ~/.config/maitri/plugins/<username>.workspaces/; saved changes reload automatically.
```

Cloning switches the bar to the cloned copy (e.g. `<username>.workspaces`),
which is yours to edit and survives updates.

Saving a file anywhere under `~/.config/maitri/plugins/` reloads plugin code
automatically. If a change somehow fails to apply, force a reload with
`maitri-shell shell rescanPlugins`.

## Idle and Lock

Set `idle.screensaver` and `idle.lock` in `~/.config/maitri/shell.json`,
in seconds since user idle began. Example: "lock after ten minutes" means
setting `idle.lock` to `600`.
