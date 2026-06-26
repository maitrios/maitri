# maitri — Maintenance Guide

**maitri** (pronounced *MY-tree*) is an independent, Arch-based Hyprland desktop made by
[Kindness](https://kindness.ai). *Maitrī* is Sanskrit for loving-kindness.

maitri began as a config/branding fork of [Omarchy](https://github.com/basecamp/omarchy) by DHH, and owes
its Hyprland config, theming engine, and update machinery to that project — huge thanks to DHH and the
Omarchy community. maitri is now a standalone project: its own `maitri-*` commands, its own package repo,
and its own identity. We no longer track Omarchy upstream, so all future maintenance lives here.

## How maitri is wired

- **Repo:** `kindness-ai/maitri` (public). Installs clone it over HTTPS — no token.
- **Branch:** `main`.
- **Installer:** `boot.sh` clones the repo to `~/.local/share/maitri` and runs `install.sh`.
- **Updates:** `maitri update` runs `git pull` from `origin`, applies pending migrations, then `pacman -Syu`.
- **Command center:** `bin/maitri` is the dispatcher; every `bin/maitri-*` is a subcommand, discovered via
  its `# maitri:` metadata header. Run `maitri commands` to list them and `maitri commands --check` to
  validate metadata and routes.

## Packages

- **Base packages** come from the **official Arch mirrors** (`geo.mirror.pkgbuild.com`).
- **maitri's own packages** (currently the signing keyring) come from the **`[maitri]`** pacman repo,
  hosted as a GitHub release under `kindness-ai/maitri-pkgs` and signed with the maitri signing key
  (delivered by the `maitri-keyring` package).
- A few apps (the Vicinae launcher, optional dictation) install from the **AUR** via `yay`.

## Migrations

`maitri update` runs `bin/maitri-migrate`, which applies any `migrations/*.sh` not yet recorded under
`~/.local/state/maitri/migrations/`. Fresh installs mark them all as applied *without* running them
(`install/preflight/migrations.sh`), so migrations only ever move existing machines forward. History was
reset at the maitri fork — see [`migrations/README.md`](migrations/README.md).

Migrating a legacy `~/.local/share/omarchy` install? Run `maitri migrate-from-omarchy` — a one-time,
copy-based relocation to the maitri paths.

## Building & testing

There's no build step for the script install — `boot.sh` clones and runs the repo. Validate off-Arch:

- `bash -n` on every shell script
- `shellcheck` on changed scripts
- `maitri commands --check` (validates command metadata + routes; needs bash 5)

Full install/update flows must be exercised on an **Arch Linux** target (a VM is fine):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/kindness-ai/maitri/main/boot.sh)
```

## ISO

For bare-metal installs, maitri ships an ISO builder under [`iso/`](iso/) plus a GitHub Action
([`build-iso.yml`](.github/workflows/build-iso.yml)). Trigger it from **Actions** → *Build maitri ISO*;
the ISO is published to the [Releases](https://github.com/kindness-ai/maitri/releases) page. Details in
[`iso/README.md`](iso/README.md).

## License

MIT — like Omarchy, the project maitri grew from.
