# maitri CLI

maitri is usually controlled through the hotkeys and the maitri menu (`Super + Space`). But you can also control it through the `maitri` CLI. This is particularly helpful when you're having an AI agent work with you on customization or configuration.

The CLI has access to all the internal tooling that is used both via the menu and otherwise. You can see everything that's available by running `maitri` in the terminal.

It looks something like this:

```
~ ❯ maitri
maitri command center

Usage:
  maitri <command> [args...]
  maitri commands [--all] [--json] [--check]
  maitri <group> --help
  maitri <group> <command> --help

Common commands:
  maitri update              Update maitri and system packages
  maitri theme list          List available themes
  maitri theme set <name>    Apply a theme
  maitri font list           List available fonts
  maitri screenshot          Take a screenshot
  maitri debug               Print debugging information

Groups:
  agent          AI coding agent usage data
  audio          Audio input and output controls
  bar            maitri shell bar layout and settings
  battery        Battery status helpers
  bluetooth      Bluetooth device controls
  branch         maitri git branch management
  branding       About and screensaver branding
  brightness     Display and keyboard brightness
  capture        Screenshots and screen recording
  channel        maitri release channel management
  clipboard      Clipboard helpers
  cmd            Command and shortcut helpers
  config         System configuration helpers
  debug          Diagnostics and support logs
  ...
```

And you can dive deeper on every group:

```
~ ❯ maitri capture
Capture commands — Screenshots and screen recording:
  maitri capture qr                                                                                                                                                                                                       Decode a QR code from a screenshot region
  maitri capture screenrecording [--fullscreen] [--with-desktop-audio] [--with-microphone-audio] [--with-webcam] [--webcam-device=<device>] [--webcam-size=<small|medium|large>] [--resolution=<size>] [--stop-recording]  Start or stop screen recording
  maitri capture screenrecording with webcam                                                                                                                                                                              Pick a webcam and start a screen recording with it
  maitri capture screenshot [smart|region|windows|fullscreen] [slurp|copy|save] [--editor=<name>]                                                                                                                         Take a screenshot
  maitri capture text                                                                                                                                                                                                     Extract text from a screenshot region with OCR
  maitri capture webcam resize <smaller|larger|reset|small|medium|large>                                                                                                                                                  Resize the active webcam recording overlay
```

Every command takes `--help` too, whether you ask a whole group (`maitri capture --help`) or a single command (`maitri capture screenshot --help`).

### Opening the menu from the terminal

The maitri menu is scriptable as well, which is handy for your own keybindings. `maitri menu` opens it at the root, and you can jump straight to any point in the tree by naming it: `maitri menu summon style.theme` goes right to the theme picker, `maitri menu toggle system` opens the system menu and closes it again if it's already up, and `maitri menu close` puts it away.
