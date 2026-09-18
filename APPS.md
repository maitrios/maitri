# maitri — Apps & Packages

What a fresh maitri install carries. The source of truth is
[`install/maitri-base.packages`](install/maitri-base.packages) (pacstrapped by the ISO) plus
[`install/maitri-other.packages`](install/maitri-other.packages) (hardware-conditional extras);
this page is the human-readable summary.

## Defaults

- **Shell** → fish with the pure prompt (`maitri-fish` carries the functions and completions; bash stays configured)
- **Browser** → Helium (also the engine behind the web-app launchers)
- **Editor** → VS Code
- **Terminal** → foot (Alacritty, kitty and Ghostty are one `maitri install terminal` away)
- **Launcher** → Vicinae, with the maitri menu as a Vicinae extension
- **Theme** → Spark (deep blue); six more under `themes/`

## Desktop

Hyprland · the maitri Quickshell shell (bar, notifications, OSD, lock screen, panels) · Vicinae ·
SDDM · Plymouth · uwsm · xdg-desktop-portal-hyprland · fcitx5

## Web apps

`applications/*.desktop`, launched through `maitri-launch-webapp` in Helium: GitHub · Figma ·
YouTube · Discord · Zoom (registers the `zoommtg://` handler)

## Editors & dev tooling

VS Code · Sublime Text · Warp · Neovim (`maitri-nvim`, LazyVim) · vim · nano · chezmoi · git ·
lazygit · lazydocker · Docker (compose, buildx) · mise (Node via mise, `maitri-mise-install` stubs) ·
ripgrep · fd · fzf · zoxide · eza · bat · btop · tmux · herdr · tldr · tree-sitter

## AI

Claude Code, opencode, pi, omp and grok CLIs via mise stubs; Codex, Gemini and Copilot are opt-in
from the menu (`Install › AI`), as are Claude Desktop, ChatGPT Desktop, Hermes, OpenClaw, Cursor,
LM Studio and T3 Code.

## GUI apps

Nautilus · Obsidian · LibreOffice · Kdenlive · OBS Studio · Pinta · Xournal++ · Evince · imv · mpv ·
Spotify · Signal · 1Password · LocalSend · omawrite · omacalc · omacut · cliamp · aether

## Optional installs from the menu

Browsers (Chromium, Chrome, Brave, Edge, Firefox, Zen) · gaming (Steam, RetroArch, Heroic, Lutris,
Battle.net, Moonlight, Sunshine, Xbox controllers) · services (Dropbox, Tailscale, NordVPN, ONCE) ·
dev environments · Windows VM · dictation (voxtype)

## Where things are served from

Everything resolves from the official Arch repos except the packages served from the `[maitri]`
channel; the header of `install/maitri-base.packages` lists them. Adding a non-Arch package to the
loadout means adding its PKGBUILD to maitri-pkgs first.
