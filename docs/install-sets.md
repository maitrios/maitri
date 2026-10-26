# Install sets

An install set is your version of maitri in one small file: the apps you add, the theme, font,
plugins, default browser, editor, terminal and agent, and a pointer to your dotfiles. Apply it on
any fresh install and the machine ends up set up the way you like it.

```bash
maitri set export --id bob/laptop --output laptop.maitri-set.toml   # write one from this machine
maitri set validate laptop.maitri-set.toml
maitri set apply laptop.maitri-set.toml --dry-run                   # see the plan, change nothing
maitri set apply laptop.maitri-set.toml
maitri set apply https://example.com/laptop.maitri-set.toml --sha256 <hex>
```

`maitri install set` is an alias for `maitri set apply`.

## What apply does

`maitri set apply` validates the set, compares it with the machine, prints a plan and asks before
running it. It only adds what is missing, so running it again is safe, and a second run on a
machine that already matches prints "Nothing to do". The phases run in this order: channel, repo
packages, removals (with `--prune`), AUR packages, flatpaks, installers, font, theme, defaults,
web apps, plugins, setup steps, and dotfiles last.

- Removals listed under `packages.remove` and `webapps.remove` only run with `--prune`.
- If one phase fails, the rest still run. Apply reports what failed, logs it to
  `~/.local/state/maitri/sets/apply.log`, and exits non-zero. Fix the problem and apply again.
- Installers and setup steps are recorded in `~/.local/state/maitri/sets/done/`, so they run once.
- `--sha256` (or `#sha256=<hex>` on the URL) refuses a set whose bytes changed since you took the
  hash. Use it for any set you fetch from a URL; `--yes` refuses a URL without it.
- The dotfiles step always asks in a terminal, even with `--yes`, and is skipped without one.

## The file

`maitri-set.toml`, schema 1. Unknown keys are errors at every level, so a typo can't be ignored
without you noticing.

```toml
schema = 1
id = "bob/laptop"                  # <handle>/<name>
name = "Bob's laptop"
description = "optional"
maitri = ">=0.7.1"                 # optional minimum maitri version

[channel]
maitri = "stable"                  # stable | edge

[packages]
add = ["doctl", "wev"]             # official Arch repos and [maitri]
remove = ["obsidian"]              # only with --prune; only maitri's removable preinstalls or your own packages
aur = [
  { name = "beeper-bin", pkgbuild_sha256 = "<sha256 of the PKGBUILD>" },  # pin is optional
]

[flatpak]
apps = ["us.zoom.Zoom"]            # from Flathub, installed per user

[installers]
run = ["browser:zen", "service:1password", "ai:chatgpt", "voxtype"]

[theme]
name = "amethyst"                  # a shipped theme or one already in ~/.config/maitri/themes

[fonts]
mono = "Iosevka Nerd Font"         # installed font family; add its package under packages.add

[defaults]
browser = "zen"
editor = "code"
terminal = "foot"
agent = "claude"

[plugins]
add = [
  { id = "maitrios.trackpoint", git = "https://github.com/maitrios/maitri-trackpoint.git",
    rev = "<full commit sha>", enable = true, when = "laptop" },
]

[[webapps.add]]
name = "Linear"
url = "https://linear.app"
icon = "https://linear.app/favicon.png"

[hardware]
form_factor = "laptop"             # laptop | desktop | auto; a mismatch is only a warning

[steps]
run = ["fido2", "home-snapshots"]

[dotfiles]
chezmoi = "https://github.com/bob/dotfiles"   # runs chezmoi init --apply after asking
```

Installers are `browser:<chromium|chrome|brave|brave-origin|edge|firefox|zen>`,
`terminal:<alacritty|ghostty|kitty>`, `editor:<emacs|helix|vscode|zed>`,
`service:<1password|dropbox|nordvpn|once|signal|spotify|sunshine|tailscale>`,
`gaming:<battlenet|geforce-now|gpu-lib32|heroic|lutris|retroarch|steam|xbox-cloud|xbox-controllers>`,
`ai:<chatgpt|hermes|openclaw|t3-code>`, `dev-env:<language>` and `voxtype`. Each one runs the matching
`maitri-install-*` command. Steps are `hibernation`, `home-snapshots`, `fido2`, `fingerprint`,
`sudoless-docker` and `sshd`, each a `maitri-setup-*` command. A plugin's `when` is one of `laptop`,
`desktop`, `intel`, `nvidia`, `fingerprint`, `touchpad`, `touchscreen`, `framework16`, `surface` or
`asus-rog`.

## Trust

A set can't run shell, but what it installs can: AUR build scripts, plugins (QML that runs in the
shell) and your chezmoi repo's scripts all run code their authors wrote. Applying a set means
trusting its author and the authors of what it lists, so read the plan, and pin what you can.

## What a set can't do

- **Run shell.** Every effect is a key into a fixed table of maitri commands. A set you can share as
  a URL must be safe to read in a minute, and anything that needs a script belongs in your own
  chezmoi `run_once_` scripts.
- **Remove maitri.** `packages.remove` can't name anything in maitri's own package lists apart from
  the preinstalls Remove Preinstalls already drops (LibreOffice, Xournal++, Pinta, Obsidian, OBS,
  Kdenlive, Moonlight, lazydocker).
- **Carry control characters.** Escape sequences and bidi overrides could rewrite the plan apply
  prints before you confirm it, so any string holding one is refused.
- **Hold secrets.** The validator refuses keys that name credentials (`token`, `secret`, `password`,
  `key`…) and values (and comment lines) that look like tokens, private keys, 1Password references, email
  addresses, URLs with credentials, or long random strings. It's a safety net, not a guarantee:
  short secrets get past it, and a URL with a long random path can be refused. Hashes in `pkgbuild_sha256` and `rev` are allowed.
  Logins, keys, hostnames and anything about your employer go in chezmoi.

## AUR packages

The AUR is unreviewed, and malware has shipped through it. Prefer `packages.add` (Arch and
`[maitri]`) or an installer when one exists. An AUR entry with `pkgbuild_sha256` installs only while
the PKGBUILD still hashes to that value, so a changed recipe stops the install until you review it
and update the pin. The pin covers the PKGBUILD only, not the package's other files or its AUR
dependencies. Unpinned entries are flagged in the plan.

## Not in schema 1 yet

`extends`, signed sets, themes from git, backgrounds, hardware profiles (ROCm and similar), the
website at `/me/<handle>/<name>`, and building an ISO from a set.
