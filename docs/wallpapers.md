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
| `themes/<theme>/<sha256>.preview.webp` | once, never overwritten | a year, immutable |
| `releases/<tag>/manifest.json` | once per release | 60 s |
| `channels/stable/manifest.json` | rewritten for each release | 60 s |

`<theme>` is `[a-z0-9-]+`, `<sha256>` is the lowercase hex sha256 of the
file's bytes, and `<ext>` is `jpg`, `png`, `webp` or `avif`. A preview sits next
to its original under the original's sha256. Nothing else goes
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
      "size": 812345,
      "preview": "themes/amethyst/<sha256>.preview.webp",
      "preview_sha256": "<sha256 of the preview>"
    }
  ]
}
```

Every release's manifest lists every wallpaper published so far; nothing is
pruned.

`preview` and `preview_sha256` are optional and come together. `preview` is
exactly `themes/<theme>/<sha256>.preview.webp` for the entry's own theme and
sha256, and `preview_sha256` is the lowercase hex sha256 of that object's
bytes. The preview is a WebP of the original at most 960 pixels wide (never scaled up), for pages that
show a lot of wallpapers at once, like the theme browser on the site. A consumer
that wants a preview falls back to `file` when an entry has none. Entries
published before previews existed have none until their release is published
again (see [Backfilling previews](#backfilling-previews)).

`maitri-update-wallpapers` ignores both and only installs originals, and so
does every updater shipped before the fields existed, since they only read
`theme`, `file`, `sha256` and `size`. A manifest without them is as valid as it
ever was.

Previews are made with vips from the original: `vips thumbnail` to 960 pixels
wide with `--size down`, saved as WebP with `Q=80,effort=6,keep=none`, so no
EXIF, XMP or ICC profile survives. The same original and the same vips give the
same bytes. A preview's key comes from the original's sha256 and is never
overwritten, so a rerun under a newer vips keeps the first preview, and
`preview_sha256` is always the hash of the object in the bucket.

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

The workflow only runs when it's started by hand on `main`, with the release
tag as its `tag` input. Its job uses the `release` environment, which holds the
bucket-scoped token in the secrets `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`
and `R2_ENDPOINT` (Andrew sets these from 1Password
`k7 Provisioner/k7m - R2 maitri upload`) and only accepts `main`. Run it after
the release is published, so the wallpapers land with the packages.

### Shipping wallpapers with a release

The picked wallpapers aren't in git, so they ride along on the release as a
`wallpapers.tar` asset. From a checkout of `main`, once
`gh release create vX.Y.Z` has published the release:

1. Stage each pick as `wallpapers/<theme>/<any name>.<ext>`, where `<theme>` is
   a directory under `themes/` and `<ext>` is `jpg`, `jpeg`, `png` or `webp`.
   `wallpapers/` is gitignored apart from its README.
2. Check the plan without credentials. It reads the live stable manifest, makes
   the previews with vips (part of maitri's base packages), says which files
   it would upload, and prints the manifest it would publish:

   ```bash
   tools/wallpapers-upload.sh --dry-run vX.Y.Z
   ```

3. Pack the staging directory:

   ```bash
   tar -cf wallpapers.tar -C wallpapers --exclude README.md .
   ```

4. Attach it to the release:

   ```bash
   gh release upload vX.Y.Z wallpapers.tar --repo maitrios/maitri
   ```

5. Publish:

   ```bash
   gh workflow run wallpapers.yml --repo maitrios/maitri --ref main -f tag=vX.Y.Z
   ```

A release with no new wallpapers only needs step 5. It still gets a manifest,
carrying the current wallpapers forward, and moves stable to it.

To add wallpapers to a release that was already published, repeat steps 1 to 5
for it. A release's manifest only grows, so the rerun adds the new files and
keeps everything it already listed.

### Backfilling previews

Wallpapers published before previews existed have no `preview` in the
manifest. Publishing their release again puts it there: the run finds the
originals already in the bucket, uploads only the missing previews, and
rewrites the release's manifest and stable with them. It needs the release's
`wallpapers.tar` still attached, and stable only moves if that release is still
the newest. For v0.7.0:

```bash
gh workflow run wallpapers.yml --repo maitrios/maitri --ref main -f tag=v0.7.0
```

To rehearse a run in CI without uploading anything:

```bash
gh workflow run wallpapers.yml --repo maitrios/maitri --ref main -f tag=vX.Y.Z -f dry_run=true
```

### What the workflow does

It runs two jobs. Both check out `main`, refuse to go on unless the run was
started on `main`, and run `tools/wallpapers-check-tag.sh`, which checks that
the tag is `vX.Y.Z` or `vX.Y.Z-<pre>`, exists on the remote, and points at a
commit in `main`'s history. Nothing from the tag's tree is checked out or run.

The `previews` job has no environment, no secrets and only `contents: read`.
If `wallpapers.tar` is attached and is at most 1 GiB, it downloads it, installs
`libvips-tools` from Ubuntu's archive, and runs
`tools/wallpapers-upload.sh --make-previews <dir> --tar wallpapers.tar vX.Y.Z`.
That checks the files the same way the publish job does (steps 1 and 2 below),
writes each preview, and refuses to run at all while any `R2_*` or `AWS_*`
variable is set or `~/.aws/credentials` exists. The previews go to the publish job as a workflow artifact.

The `publish` job is the only one in the `release` environment. It runs after
`previews`, checks the tag before any step that sees a secret, reads the
release (a release marked as a prerelease only gets its own manifest),
downloads `wallpapers.tar` again along with the previews artifact, and runs
`tools/wallpapers-upload.sh --tar wallpapers.tar --previews <dir> vX.Y.Z`,
which:

1. Refuses anything but a plain, uncompressed ustar archive, checked by its
   magic bytes before tar sees it. tar then reads it from a pipe, where GNU tar
   refuses compressed input instead of running a decompressor. It also refuses
   a tar holding anything but directories and plain files, or a member that
   climbs out with `..`.
2. Checks every file: a plain file directly in a directory named after a
   maitri theme, a name with no control characters or backslashes, a `jpg`,
   `png` or `webp` by both its name and its first bytes, and between 1 byte
   and 64 MiB. It hashes each one.
3. Checks the previews without decoding them. The artifact may hold only plain
   files, each named `themes/<theme>/<sha256>.preview.webp` after a file from
   step 2. A preview already in the bucket is fetched and hashed instead. Any
   other preview must be in the artifact, start with WebP's `RIFF....WEBP`
   bytes and be between 1 byte and 4 MiB. Each one's sha256 goes in the
   manifest.
4. Reads the current stable manifest straight from the bucket and builds the
   release's manifest from it plus the new files, each with its `preview` and
   `preview_sha256`. A file that's already listed gains both. The whole
   manifest must pass the same checks the stable one does (paths, 64-hex
   sha256s, whole-number sizes, previews) and fit in the 1 MiB the updater
   reads.
5. Stops before uploading anything if `releases/<tag>/manifest.json` already
   lists a file the new manifest doesn't. Only `theme`, `file`, `sha256` and
   `size` count, so gaining a preview isn't a change.
6. HEADs `themes/<theme>/<sha256>.<ext>` for each file and uploads it, and
   each preview that isn't in the bucket yet, with its Content-Type and
   `Cache-Control: public, max-age=31536000, immutable`.
7. Writes `releases/<tag>/manifest.json`, then rewrites
      `channels/stable/manifest.json` with the same content, unless the
   release is a prerelease (marked as one, or a tag like `v1.2.0-rc.1`) or
   stable is already on a newer release. Both get
   `Cache-Control: public, max-age=60`.

### What keeps the token safe

GitHub runs a workflow from the ref it was started on, so a tag at an
unreviewed commit runs that commit's workflow files. Those runs aren't on
`main`, and the `release` environment only accepts `main`, so none of them get
the token. Every run that can get it uses a workflow file from `main`, and
changes to `main` go through a reviewed pull request. That only holds while
the `R2_*` secrets live in the `release` environment and nowhere else: never
add them as repository or organization secrets.

The tag is checked so that only a real release gets published, but anyone who
can start the workflow and attach a release asset can publish any wallpaper
that passes the checks above. The checks cover each file's shape, not what it
shows.

The same goes for decoding. `wallpapers.tar` can come from anyone who can
attach a release asset, so an image crafted for a bug in libjpeg, libpng,
libwebp, libexif or lcms2 could run code in whatever decodes it. Only the
`previews` job decodes, and it has nothing worth stealing: no environment, no
secrets and a read-only token. The worst it can do is hand over bad previews,
and the publish job checks those by name, size and first bytes without ever
decoding an image. Keep vips and every other decoder out of the publish job.

## Tests

`test/shell.d/wallpapers-test.sh` serves a manifest and files from a local
HTTP server and covers the install, an idempotent re-run, a deleted wallpaper
staying deleted, a bad checksum being rejected, an offline run exiting 0, a
300 MB body for a 5 KB entry (with and without a Content-Length) being cut off
without landing on disk, and an oversized manifest. On the publishing side it
builds a manifest with `tools/wallpapers-upload.sh --dry-run` from both a
staging directory and a `wallpapers.tar`, refuses bad tars and file names, and
runs a real upload against a stub `aws` to check the keys, headers, prerelease
handling, attaching wallpapers after a release, the grow-only release manifest
and the manifest size limit, then installs from the result. For previews it
checks that each staged file gets a 960-pixel WebP with no metadata, a small
one isn't scaled up, an undecodable image is refused before anything uploads,
a preview or `preview_sha256` that isn't the entry's own is refused, and that
rerunning a release whose manifests have no previews uploads only the
previews, the same bytes as before, and adds them to both manifests. Every
publish runs with stub decoders on its `PATH` that fail the test if called.
The uploader won't decode with a token in its environment, a real run without
`--previews` is refused, and so are artifacts holding an extra file, a missing
preview, a non-WebP, a preview over 4 MiB or a symlink. A rerun with different
preview bytes keeps the bucket's preview and its hash, and changing a published
entry's size counts as dropping it.
`test/shell.d/wallpapers-release-guard-test.sh` runs
`tools/wallpapers-check-tag.sh` against a scratch remote (tags on and off
`main`, moved, local, malformed and missing) and checks that the workflow only
runs from `main` and checks the tag before any secret, that the `previews` job
has no environment and no secrets and is the only one that makes previews, and
that the publish job never installs or runs a decoder. It also checks that a theme switch and `maitri theme
bg next` put the theme's own wallpaper ahead of downloaded ones.
