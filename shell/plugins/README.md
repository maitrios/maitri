# First-party plugins

These plugins ship with maitri and are discovered by the shell at startup.
They use the same `manifest.json` contract as third-party plugins; the
only difference is that the shell flags them with `__isFirstParty: true`.
First-party non-bar plugins are enabled unless listed in `disabledPlugins[]`;
`maitri.bar` is the default bar option and becomes inactive only while another
`kind: "bar"` plugin is selected. Services and keep-loaded panels are mounted
at startup; other panels, overlays, and menus are loaded on demand.

User-installed plugins live alongside these conceptually but on disk under
`~/.config/maitri/plugins/<plugin-id>/` rather than in this directory.

| Plugin        | id                        | kinds                   | entry point                           |
|---------------|---------------------------|-------------------------|---------------------------------------|
| Bar           | `maitri.bar`             | `bar`                   | `bar/Bar.qml`                         |
| Image picker  | `maitri.image-picker`    | `overlay`               | `image-picker/ImagePicker.qml`        |
| Emojis        | `maitri.emojis`          | `overlay`               | `emojis/Emojis.qml`                   |
| Clipboard mgr | `maitri.clipboard`       | `overlay`               | `clipboard/Clipboard.qml`             |
| Reminders     | `maitri.reminders`       | `overlay`               | `reminders/ReminderFlow.qml`          |
| maitri menu  | `maitri.menu`            | `menu`, `bar-widget`    | `menu/Menu.qml`, `menu/BarWidget.qml` |
| Notifications | `maitri.notifications`   | `service`               | `notifications/Service.qml`           |
| Audio         | `maitri.audio`           | `bar-widget`            | `panels/audio/Panel.qml`              |
| Bluetooth     | `maitri.bluetooth`       | `bar-widget`            | `panels/bluetooth/Panel.qml`          |
| Clock         | `maitri.clock`           | `bar-widget`            | `panels/clock/BarWidget.qml`          |
| Monitor       | `maitri.monitor`         | `bar-widget`            | `panels/monitor/Panel.qml`            |
| Network       | `maitri.network`         | `bar-widget`            | `panels/network/Panel.qml`            |
| Power         | `maitri.power`           | `bar-widget`            | `panels/power/Panel.qml`              |
| Tailscale     | `maitri.tailscale`       | `bar-widget`            | `panels/tailscale/Panel.qml`          |
| Agents   | `maitri.agents`     | `bar-widget`            | `agents/Panel.qml`               |
| Weather       | `maitri.weather`         | `bar-widget`            | `panels/weather/BarWidget.qml`        |
| Media         | `maitri.media`           | `service`, `bar-widget` | `services/media/Service.qml`, `services/media/BarWidget.qml` |
| Battery       | `maitri.battery`         | `service`               | `services/battery/Service.qml`        |
| Idle          | `maitri.idle`            | `service`               | `services/idle/Service.qml`           |
| Night light   | `maitri.nightlight`      | `service`               | `services/nightlight/Service.qml`     |
| Lock screen   | `maitri.lock`            | `service`               | `lock/Service.qml`                    |
| OSD           | `maitri.osd`             | `panel`                 | `osd/Osd.qml`                         |
| Polkit agent  | `maitri.polkit`          | `service`               | `polkit/PolkitAgent.qml`              |

First-party bar-only widgets also carry manifests next to their QML files,
e.g. `bar/widgets/Workspaces.manifest.json`. Rich popup widgets live in their
own plugin directories, each with its own `manifest.json`.

## Bar

The built-in status bar and default full-bar option. Layout lives in the
top-level `bar:` subtree of `~/.config/maitri/shell.json` (with the shell
providing [`config/maitri/shell.json`](../../config/maitri/shell.json) when
the user has no file). See [`bar/README.md`](bar/README.md) for the widget catalogue
and customization schema.

## Image picker

Fullscreen image-grid selector overlay. Used by `maitri-menu-images`
(wallpaper picker) and `maitri-theme-switcher` (theme picker) and any
other caller that wants to present a directory of images with previews.

Two ways to drive it:

- Shell-level summon: `maitri-shell shell summon maitri.image-picker '<jsonPayload>'`.
  The payload can carry `imageDirs`, `imageRows`, `selectedImage`,
  `selectionFile`, `doneFile`, `showLabels`, `filterable`. Best for
  in-shell callers that already speak JSON.
- Direct IPC target: `maitri-shell image-selector open <imageDirs> <imageRowsB64> <selectedImage> <selectionFile> <doneFile> <showLabels> <filterable>`.
  Positional args; `imageRowsB64` is base64-encoded so embedded newlines /
  tabs survive the bash argv handoff. This is what `maitri-menu-images`
  uses. Colors come from the central shell theme singleton; there is no
  per-call override surface.

The selection round-trip remains file-based: callers create a
`selection_file` and `done_file` (both `mktemp`), pass the paths, and
poll `done_file` for existence. The plugin writes the chosen path into
`selection_file` and touches `done_file` when it's done. `cancel` IPC
clears it without writing a selection.

The plugin has `keepLoaded: true` so the layer-shell window survives
between summons within a single shell session.

## Lock screen

Session-lock surface using Quickshell's native `WlSessionLock` and two
separate PAM services: `maitri-lock-password` for password auth and,
only when fingerprints are enrolled, `maitri-lock-fingerprint` for
fingerprint auth. It mirrors the previous lock screen field dimensions,
colors, blurred wallpaper, placeholder, and Hyprland-driven corners.
The plugin sets `keepLoaded: true` so a plugin hot-reload (for example
an installed bar widget changing on disk) does not destroy the lock
client while Hyprland still holds the session lock.

## Polkit agent

Theme-aware authentication dialog for privileged actions. It uses
Quickshell's native `Quickshell.Services.Polkit.PolkitAgent` backend and
runs inside the long-lived `maitri-shell` process, replacing the old
`polkit-gnome-authentication-agent-1` autostart.

## maitri menu

Quickshell-powered maitri command menu.
The menu UI lives in `menu/Menu.qml` as a first-party `menu` plugin and is
summoned through the shell (`maitri-shell shell summon maitri.menu ...`),
so it shares the long-running `maitri-shell` process instead of starting a
second Quickshell instance.

The menu definition lives outside the shell host code:

- defaults: `default/maitri/maitri-menu.jsonc`
- user extensions: `~/.config/maitri/extensions/maitri-menu.jsonc`

The shell parses both JSONC files at startup (with `watchChanges: true`
so edits take effect without a restart), evaluates `when:` / `checked:`
bash expressions in a single batched subprocess, and executes the
selected `action:` string directly via `Quickshell.execDetached`. The
long-running shell process keeps the parsed menu in memory, so the
keybind → IPC → visible path costs ~30ms cold.

## Coming soon

- `maitri.theme-switcher` — folds theme switching into the shell.
