# maitri — Maintenance Guide

**maitri** (pronounced *MY-tree*) is an Arch-based Hyprland desktop made by [Kindness](https://kindness.ai).
It is a rebranded fork of [Omarchy](https://github.com/basecamp/omarchy) that tracks upstream releases. <!-- rebrand:keep -->

## The three repositories

| Repo | What lives there |
|---|---|
| [maitrios/maitri](https://github.com/maitrios/maitri) | The desktop: `bin/` commands, `install/` setup, `default/` and `config/` defaults, `etc/` drop-ins, `shell/` (Quickshell), `themes/`, `migrations/`, the ISO builder under `iso/` |
| [maitrios/maitri-pkgs](https://github.com/maitrios/maitri-pkgs) | PKGBUILDs and the CI that builds and signs the `[maitri]` pacman repository, including the `maitri` and `maitri-settings` packages built from this repo |
| [maitrios/maitri-vicinae](https://github.com/maitrios/maitri-vicinae) | The Vicinae extension that renders the maitri menu, keybindings and pickers |

## How a maitri install is wired

- **Packages.** This repo is built into two pacman packages: `maitri` (runtime: `bin/`, `install/`,
  `migrations/`, `themes/`, `shell/`) and `maitri-settings` (`/etc/skel` seeds from `config/`, the
  `/etc` drop-ins, fonts, Plymouth and SDDM themes). `maitri-dev` and `maitri-settings-dev` are the
  same built from the `main` branch head. See [docs/file-layout.md](docs/file-layout.md).
- **Channels.** Arch packages come from the official mirrors (`geo.mirror.pkgbuild.com`). The
  `[maitri]` repo is a GitHub Release per channel on maitri-pkgs: `stable` and `edge`. `maitri channel
  set dev` links the runtime to a git checkout instead (`maitri dev link`). There is no rc channel.
- **Signing.** Packages are signed with the maitri key shipped by `maitri-keyring`; `SigLevel =
  Required` for `[maitri]`.
- **Install.** The ISO pacstraps Arch plus `maitri-keyring`, `maitri-settings` and `maitri` from a
  bundled offline mirror, runs `maitri-apply-system` in the chroot, creates the user with fish as the
  login shell, and runs `maitri-provision-user --force --first-install`. There is no curl installer.
- **Updates.** `maitri update` runs the pacman transaction (guarded by an ALPM hook that aborts raw
  `pacman -Syu`), then `maitri-migrate` for pending per-user migrations, then post-update hooks.
  See [docs/update-process.md](docs/update-process.md).
- **Launcher.** Vicinae is the launcher, clipboard and emoji picker. The maitri menu is the
  maitri-vicinae extension rendering `default/maitri/maitri-menu.jsonc`; `maitri-menu` routes to it,
  and `maitri-menu-select` / `maitri-menu-input` are its dmenu. The Quickshell menu, emoji and
  clipboard plugins stay shipped but disabled in `config/maitri/shell.json`.

## Keeping up with Omarchy <!-- rebrand:keep -->

The `upstream` branch holds a **rebranded** copy of each Omarchy tag. Never merge a raw Omarchy tag <!-- rebrand:keep -->
into `main`; every upstream line containing "omarchy" would conflict with the rename. <!-- rebrand:keep -->

```bash
tools/sync-upstream.sh v4.1.0   # rebrand the tag onto `upstream`, then merge into the current branch
# resolve conflicts, then:
tools/rebrand.sh --paths <conflicted files>
tools/rebrand.sh --check
./test/cli && ./test/shell
```

`tools/rebrand.sh` is the single source of truth for the rename: the omarchy→maitri substitution, <!-- rebrand:keep -->
the path renames, the protected upstream tokens (attribution and upstream URLs), and the list of
upstream-only files maitri deletes (stock themes, the rc channel, the v3-to-v4 upgrader, Omarchy's <!-- rebrand:keep -->
web apps). Anything maitri removes from upstream permanently belongs in that delete list, or the
next sync brings it back. `test/shell.d/rebrand-test.sh` fails the suite if the upstream brand leaks
back in.

The legacy git-pull based maitri 0.x line is preserved on the `legacy` branch and the `v0.1-legacy`
tag. It shares no history with `main`; 0.x machines reinstall from the ISO.

## Developing

```bash
./test/cli && ./test/shell          # run on any machine; the runner points them at this checkout
maitri channel set dev              # on a maitri machine: link the runtime to ~/maitri
maitri dev link ~/dev/kindness/maitri
maitri dev pkg-test maitri-settings-dev ~/dev/kindness/maitri   # build and install the packages from a checkout
```

Contributor conventions live in [AGENTS.md](AGENTS.md) and `agents/skills/`.

## License

MIT — like Omarchy, the project maitri grew from. <!-- rebrand:keep -->
