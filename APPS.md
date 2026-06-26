# maitri — Apps & Packages

The inventory of what maitri installs. This is the single source of truth for the loadout — keep it
updated as things change. maitri's desktop/package machinery began as a fork of
[Omarchy](https://github.com/basecamp/omarchy); the "differs from stock Omarchy" notes below are
historical origin context.

## Defaults

- **Shell** → fish
- **Browser** → Helium (also the engine behind the web-app launchers)
- **Editor** → VS Code
- **Theme** → Spark (deep blue)

## Web apps

Source: [`install/packaging/webapps.sh`](install/packaging/webapps.sh). Helium PWA launchers; sessions
persist in the shared profile so you stay logged in.

| App | Notes |
|-----|-------|
| GitHub | |
| Figma | |
| YouTube | |
| Discord | |
| Zoom | registers the `zoommtg://` handler |

## Editors & dev tooling

VS Code (default editor) · Sublime Text · nvim · vim · nano · chezmoi (dotfile sync) · lazygit · lazydocker ·
docker (+ compose, buildx) · github-cli · mise · rust · clang · llvm · tree-sitter-cli · dotnet-runtime ·
Cursor on demand (`maitri install cursor`)

## Terminals & shell

Warp · fish (default shell) · alacritty · starship · tmux · fzf · zoxide · eza · bat · fd · ripgrep · jq ·
gum · tldr · btop · fastfetch · plocate · bluetui (Bluetooth) · impala (Wi-Fi)

## AI / coding CLIs

Source: [`install/packaging/npx.sh`](install/packaging/npx.sh) + package channel.

claude-code · opencode · playwright · voxtype (voice typing, opt-in) · codex & gemini available as optional
installers (`maitri install codex` / `gemini`)

## Browser

**Helium** (default, and the engine behind the web-app launchers)

## Media & creative

mpv · obs-studio · kdenlive · spotify · pinta · imagemagick · ffmpegthumbnailer · grim + slurp + satty
(screenshots) · gpu-screen-recorder

## Productivity

obsidian · typora · libreoffice-fresh · xournalpp · signal-desktop · 1password (+ cli) · evince (PDF) ·
localsend · gnome-calculator

## Desktop (Hyprland) stack

hyprland (+ hypridle, hyprlock, hyprpicker, hyprsunset) · waybar · mako · walker (launcher, from AUR) ·
swaybg · swayosd · sddm (login) · plymouth (boot splash) · uwsm · xdg-desktop-portals · gnome-keyring ·
polkit-gnome

## Files, system & input

nautilus (+ sushi, gvfs) · gnome-disk-utility · imv (images) · printing (cups + system-config-printer) ·
fcitx5 (input methods) · tesseract (OCR) · ufw (firewall) · iwd · power-profiles-daemon · avahi · yay

## Fonts

JetBrains Mono Nerd · iA Writer · Noto (+ CJK, emoji) · Font Awesome · `maitri.otf` (brand heart + Waybar logo glyph)

## Themes

Source: [`themes/`](themes/). Seven original maitri themes — **Spark** (default), Harbor, Orchid, Ember,
Garnet, Amethyst, plus **Daybreak** (the one light theme). Switch with `Super + Ctrl + Shift + Space` or
`maitri theme set "Daybreak"`. (Stock Omarchy themes are not included.)

## Optional installers (on demand)

`maitri install <name>` (or via the menu): **cursor** · **codex** · **gemini** · zed · helix · alternate
browsers/terminals · docker databases · dropbox · nordvpn · tailscale · gaming (steam, lutris, heroic,
retroarch, moonlight, geforce-now).

## Differs from stock Omarchy

- **Added:** fish, Helium, VS Code, Sublime, Warp, chezmoi; seven maitri themes; maitri branding.
- **Removed:** Omarchy's 37signals/Google/etc. web apps and its stock themes (catppuccin, tokyo-night,
  gruvbox, nord, …); ruby/luarocks; the copilot CLI.

## Where to change things

| Want to change… | Edit… |
|---|---|
| Web apps | `install/packaging/webapps.sh` |
| Core packages | `install/maitri-base.packages` |
| GUI apps from AUR (VS Code, Sublime, Warp, Helium) | `install/packaging/maitri-apps.sh` |
| AI / coding CLIs | `install/packaging/npx.sh` |
| Default browser / editor / file handlers | `install/config/mimetypes.sh` |
| 1Password ↔ Helium browser integration | `install/config/1password-browser.sh` |
| Default shell | `install/config/fish-shell.sh` |
| Default theme | `install/config/theme.sh` |
