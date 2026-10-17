# Wallpapers

maitri's extra wallpapers don't live in git. They sit in the `maitri-assets`
R2 bucket behind `https://maitri.cdn.k7.dev`, listed in a manifest that
`maitri update` reads, verifies and installs from. The wallpapers that ship
inside each theme's `backgrounds/` directory are unchanged.

## The bucket

Infra owns the bucket (k7lab/infra#286, `docs/tripod/notes/286.md` there). The
layout is fixed:

| Key | Written | Cache |
| --- | --- | --- |
| `themes/<theme>/<sha256>.<ext>` | once, never overwritten | a year, immutable |
| `releases/<tag>/manifest.json` | once per release | 60 s |
| `channels/stable/manifest.json` | rewritten for each release | 60 s |

`<theme>` is `[a-z0-9-]+`, `<sha256>` is the lowercase hex sha256 of the
file's bytes, and `<ext>` is `jpg`, `png`, `webp` or `avif`. Nothing else goes
at the top level apart from infra's `smoke/`.

A manifest looks like this:

```json
{
  "release": "v1.2.0",
  "files": [
    {
      "theme": "amethyst",
      "file": "themes/amethyst/<sha256>.jpg",
      "sha256": "<sha256>",
      "size": 812345
    }
  ]
}
```

Every release's manifest lists every wallpaper published so far; nothing is
pruned.

## Installing: `maitri-update-wallpapers`

`maitri update` runs `maitri-update-wallpapers` after the package steps. It:

1. Fetches `channels/stable/manifest.json`. If that fails (offline, a 5xx, a
   404, or something that isn't a manifest), it prints one line and exits 0
   without touching anything.
2. Checks each entry: `file` must match
   `^themes/[a-z0-9-]+/[0-9a-f]{64}\.(jpg|png|webp|avif)$`, its directory must
   be the entry's `theme`, and its name must be the entry's `sha256`.
3. Skips anything already recorded in
   `~/.local/state/maitri/wallpapers/installed`. A wallpaper you delete stays
   deleted; it isn't fetched again on the next update.
4. Downloads the rest to a temp directory and checks each file's size and
   sha256. Anything that fails is reported and never installed.
5. Moves the verified files into `~/.config/maitri/backgrounds/<theme>/`, the
   user backgrounds directory that `maitri theme bg next` and the switcher
   already read, then records them.

If the network drops partway through, nothing is installed and it exits 0, so
the next update starts over cleanly. If any entry was rejected it exits 1;
`maitri update` reports that and carries on. `MAITRI_WALLPAPERS_URL` points it
at another base URL, which the tests use.

The bg switcher doesn't list `avif` yet, so the uploader below only publishes
`jpg`, `png` and `webp`; the updater accepts `avif` because the contract allows
it.

## Publishing: `.github/workflows/wallpapers.yml`

The workflow runs when a `v*` GitHub release is published, in the `release`
environment, with the bucket-scoped token in its secrets `R2_ACCESS_KEY_ID`,
`R2_SECRET_ACCESS_KEY` and `R2_ENDPOINT` (Andrew sets these from 1Password
`k7 Provisioner/k7m - R2 maitri upload`). It runs on the published release
rather than the tag push because `RELEASING.md` pushes the tag before the
packages reach stable, and the wallpapers should land with the packages.

The wallpapers ride along on the release as a `wallpapers.tar` asset, since
they aren't in the checkout:

1. Stage the approved wallpapers as `wallpapers/<theme>/<any name>.<ext>`.
   `wallpapers/` is gitignored apart from its README, and `<theme>` must be a
   directory under `themes/`.
2. Check the plan without credentials:

   ```bash
   tools/wallpapers-upload.sh --dry-run vX.Y.Z
   ```

   It reads the live stable manifest, says which files it would upload, and
   prints the manifest it would publish.
3. Pack the staging directory and attach it when publishing the release:

   ```bash
   tar -cf wallpapers.tar -C wallpapers --exclude README.md .
   gh release create vX.Y.Z --repo maitrios/maitri ... wallpapers.tar
   ```

The workflow unpacks the tar into `wallpapers/` and runs
`tools/wallpapers-upload.sh`, which:

1. Reads the current stable manifest straight from the bucket.
2. For each staged file, HEADs `themes/<theme>/<sha256>.<ext>` and uploads it
   only if it isn't there, with its Content-Type and
   `Cache-Control: public, max-age=31536000, immutable`.
3. Writes the stable manifest's files plus the new ones as
   `releases/<tag>/manifest.json`. If that key already exists with a different
   file list, it stops: a published release's wallpapers are fixed.
4. Rewrites `channels/stable/manifest.json` with the same content, unless
   stable is already on a newer release.

A release without `wallpapers.tar` still gets a manifest, carrying the current
wallpapers forward. To publish for an existing release (or rehearse one), run
the workflow by hand with its `tag` input, and `dry_run` to only report:

```bash
gh workflow run wallpapers.yml --repo maitrios/maitri -f tag=vX.Y.Z -f dry_run=true
```

## Tests

`test/shell.d/wallpapers-test.sh` serves a manifest and files from a local
`python3 -m http.server` and covers the install, an idempotent re-run, a
deleted wallpaper staying deleted, a bad checksum being rejected, and an
offline run exiting 0. It also builds a manifest with
`tools/wallpapers-upload.sh --dry-run` and installs from it, so the two sides
round-trip.
