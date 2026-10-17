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

1. Fetches `channels/stable/manifest.json`, refusing anything over 1 MiB. If
   that fails (offline, a 5xx or 429, a 404, or something that isn't a
   manifest), it prints one line and exits 0 without touching anything.
2. Checks each entry: `file` must match
   `^themes/[a-z0-9-]+/[0-9a-f]{64}\.(jpg|png|webp|avif)$`, its directory must
   be the entry's `theme`, its name must be the entry's `sha256`, and its `size`
   must be at most 64 MiB.
3. Skips anything already recorded in
   `~/.local/state/maitri/wallpapers/installed`. A wallpaper you delete stays
   deleted; it isn't fetched again on the next update.
4. Downloads the rest to a temp directory with curl's `--max-filesize` set one
   byte over the entry's `size`, so a response that runs long is cut off there
   rather than filling the disk, then checks each file's size and sha256.
   Anything that fails is reported, deleted and never installed.
5. Moves the verified files into `~/.config/maitri/backgrounds/<theme>/`, the
   user backgrounds directory that `maitri theme bg next` and the switcher
   already read, then records them.

If the network drops partway through, nothing is installed and it exits 0, so
the next update starts over cleanly. If any entry was rejected it exits 1;
`maitri update` reports that and carries on. A run where every entry was
rejected doesn't record the manifest's release. `MAITRI_WALLPAPERS_URL` points
it at another base URL, which the tests use.

Switching theme picks the theme's own wallpaper first, and `maitri theme bg
next` cycles from there through the theme's `backgrounds/` and then the
downloaded ones in manifest order, so a newly published wallpaper never
replaces a theme's default.

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

The `release` environment only accepts `v*` tags. A release event deploys from
its tag, so it just works; a manual run has to be started on the tag with
`--ref vX.Y.Z` and the same `tag` input. A run started from `main` is refused
by the environment, and the workflow itself refuses a `tag` input that isn't
the ref it was started on.

### Shipping wallpapers with a release

The picked wallpapers aren't in git, so they ride along on the release as a
`wallpapers.tar` asset. From a checkout of `main`:

1. Stage each pick as `wallpapers/<theme>/<any name>.<ext>`, where `<theme>` is
   a directory under `themes/` and `<ext>` is `jpg`, `jpeg`, `png` or `webp`.
   `wallpapers/` is gitignored apart from its README.
2. Check the plan without credentials. It reads the live stable manifest, says
   which files it would upload, and prints the manifest it would publish:

   ```bash
   tools/wallpapers-upload.sh --dry-run vX.Y.Z
   ```

3. Pack the staging directory:

   ```bash
   tar -cf wallpapers.tar -C wallpapers --exclude README.md .
   ```

4. Publish the release with the tar attached (the full commands are in
   `RELEASING.md`). `gh release create` with an asset creates a draft, uploads
   the asset and only then publishes, so the workflow sees the tar:

   ```bash
   gh release create vX.Y.Z --repo maitrios/maitri --target main --title "maitri vX.Y.Z" --generate-notes wallpapers.tar
   ```

A release without `wallpapers.tar` still gets a manifest, carrying the current
wallpapers forward.

### Adding wallpapers to a published release

If the tar missed the release, attach it and rerun the workflow on the tag.
A release's manifest only grows, so the rerun adds the new files and keeps
everything it already listed:

```bash
gh release upload vX.Y.Z wallpapers.tar --repo maitrios/maitri
```

```bash
gh workflow run wallpapers.yml --repo maitrios/maitri --ref vX.Y.Z -f tag=vX.Y.Z
```

To rehearse a run in CI without uploading anything:

```bash
gh workflow run wallpapers.yml --repo maitrios/maitri --ref vX.Y.Z -f tag=vX.Y.Z -f dry_run=true
```

### What the workflow does

1. Checks out `main` and refuses to go on unless the tag's commit is the one
   the run was started for and is in `main`'s history, so the bucket token only
   ever reaches reviewed code. This step runs before anything sees the
   secrets, and the uploader it runs is `main`'s copy.
2. Reads the release. A release marked as a prerelease only gets its own
   manifest. If `wallpapers.tar` is attached and is at most 1 GiB, it's
   downloaded.
3. Runs `tools/wallpapers-upload.sh --tar wallpapers.tar vX.Y.Z`, which:
   1. Refuses a tar holding anything but directories and plain files, or a
      member that climbs out with `..`.
   2. Checks every file: a plain file directly in a directory named after a
      maitri theme, a `jpg`, `png` or `webp` by both its name and its first
      bytes, and between 1 byte and 64 MiB. It hashes each one.
   3. Reads the current stable manifest straight from the bucket and builds
      the release's manifest from it plus the new files.
   4. Stops before uploading anything if `releases/<tag>/manifest.json`
      already lists a file the new manifest doesn't.
   5. HEADs `themes/<theme>/<sha256>.<ext>` for each file and uploads it only
      if it isn't there, with its Content-Type and
      `Cache-Control: public, max-age=31536000, immutable`.
   6. Writes `releases/<tag>/manifest.json`, then rewrites
      `channels/stable/manifest.json` with the same content, unless the
      release is a prerelease (marked as one, or a tag like `v1.2.0-rc.1`) or
      stable is already on a newer release. Both get
      `Cache-Control: public, max-age=60`.

On `release: published`, GitHub runs the workflow file from the tag, so a tag
pushed at an unreviewed commit could carry its own copy of this workflow
without the check. The check guards against a tag at a commit that only
changes the uploader; the `release` environment's `v*` tag policy is what
decides who can reach the secrets at all.

## Tests

`test/shell.d/wallpapers-test.sh` serves a manifest and files from a local
HTTP server and covers the install, an idempotent re-run, a deleted wallpaper
staying deleted, a bad checksum being rejected, an offline run exiting 0, a
300 MB body for a 5 KB entry (with and without a Content-Length) being cut off
without landing on disk, and an oversized manifest. On the publishing side it
builds a manifest with `tools/wallpapers-upload.sh --dry-run` from both a
staging directory and a `wallpapers.tar`, refuses bad tars, and runs a real
upload against a stub `aws` to check the keys, headers, prerelease handling,
attaching wallpapers after a release and the grow-only release manifest, then
installs from the result. It also checks that a theme switch and `maitri theme
bg next` put the theme's own wallpaper ahead of downloaded ones.
