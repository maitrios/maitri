# Releasing maitri

A release is a git tag here, a pair of pinned packages on maitri-pkgs, and an ISO built from them.

## Versioning

maitri uses SemVer tags `vMAJOR.MINOR.PATCH`. `v0.x` is pre-stable; `v0.3.0` is the first release of
**Karuna**, maitri's package-backed generation (built on Omarchy 4). Tags from the 0.x git-pull line end at `v0.1-legacy`; the old `v0.2.0` release belongs to that line. <!-- rebrand:keep -->

## Cut a stable release

1. Land everything on `main`, set the `version` file to `X.Y.Z`, and make sure `./test/cli` and
   `./test/shell` are green.
2. Tag, but do not publish a GitHub release yet:

   ```bash
   git tag vX.Y.Z && git push origin vX.Y.Z
   ```

3. In maitri-pkgs, pin the release pair and push; CI builds and publishes `stable` and `edge`:

   ```bash
   scripts/bump-maitri vX.Y.Z
   ```

   Verify with `gh release view stable -R maitrios/maitri-pkgs` (or `pacman -Sy && pacman -Si
   maitri` on a stable machine).
4. Publish the GitHub release, then start the ISO build. The run has to start on `main`:

   ```bash
   gh release create vX.Y.Z --repo maitrios/maitri --target main --title "maitri vX.Y.Z" --generate-notes
   ```

   ```bash
   gh workflow run build-iso.yml --repo maitrios/maitri --ref main -f release_tag=vX.Y.Z
   ```

   `build-iso.yml` checks that the tag is a release tag on `main`, waits for the `stable` channel to
   carry `maitri X.Y.Z`, builds the ISO, pushes it to Docker Hub as an OCI artifact (GitHub caps
   release assets at 2 GiB), attaches the `.sha256`, and appends the download link to the release
   notes.

5. If there are new wallpapers, stage them under `wallpapers/<theme>/`, pack them and attach them
   to the release:

   ```bash
   tar -cf wallpapers.tar -C wallpapers --exclude README.md .
   ```

   ```bash
   gh release upload vX.Y.Z wallpapers.tar --repo maitrios/maitri
   ```

6. Publish the wallpaper manifest, with or without new wallpapers. The run has to start on `main`:

   ```bash
   gh workflow run wallpapers.yml --repo maitrios/maitri --ref main -f tag=vX.Y.Z
   ```

7. Smoke test the ISO in QEMU (`iso/bin/maitri-iso-boot`).

Release notes are generated from merged pull requests, so land changes through PRs with clear titles.

Wallpapers attached to a release after step 6 ship by attaching `wallpapers.tar` and running step 6
again; a release's wallpaper manifest only grows. See [`docs/wallpapers.md`](docs/wallpapers.md).

## Releasing as a flare

A `version` change landing on `main` (usually inside an approved `upstream-sync` PR) makes
`.github/workflows/release-watch.yml` open a "Release maitri X.Y.Z" issue. A flare on the agent box
takes it; Andrew's approval of the PR that bumped `version` was the approval for the release.

1. Tag the commit named in the issue with an annotated tag, like the earlier releases, and push only
   that tag (never `git push --tags`; a sync fetches upstream's tags into the local namespace):
   `git tag -a vX.Y.Z <sha> -m "maitri vX.Y.Z" && git push origin refs/tags/vX.Y.Z`.
2. In a fresh clone of maitri-pkgs, run `scripts/bump-maitri vX.Y.Z`. It needs pacman's `vercmp`,
   so run it in an Arch container and push from the box:

   ```bash
   name="$(git config user.name)" email="$(git config user.email)"
   docker run --rm -v "$PWD:/w" -w /w -e GIT_AUTHOR_NAME="$name" -e GIT_AUTHOR_EMAIL="$email" \
     -e GIT_COMMITTER_NAME="$name" -e GIT_COMMITTER_EMAIL="$email" archlinux:latest bash -c \
     'pacman -Sy --noconfirm --needed git >/dev/null && git config --global --add safe.directory /w && scripts/bump-maitri vX.Y.Z'
   git push origin main
   ```

   Without the identity, the container can't commit and leaves the PKGBUILD edits staged; clear them
   with `git reset --hard origin/main` before retrying. The push publishes; wait for `build-pkgs.yml`
   (`gh run watch`) and check `gh release view stable -R maitrios/maitri-pkgs`.
3. Publish the release with a short prose summary above the generated notes (what changed for users,
   security fixes first, which upstream release or backports it carries). The issue links the
   compare range from the previous release; `git log --first-parent vPREV..vX.Y.Z` shows the same
   merges locally:
   `gh release create vX.Y.Z --repo maitrios/maitri --target <sha> --title "maitri vX.Y.Z" --notes-file <summary> --generate-notes`.
   If Andrew handed over a `wallpapers.tar` for the release, attach it:
   `gh release upload vX.Y.Z wallpapers.tar --repo maitrios/maitri`. Then publish the wallpaper
   manifest, with or without new wallpapers, and check that the run passed:
   `gh workflow run wallpapers.yml --repo maitrios/maitri --ref main -f tag=vX.Y.Z`.
4. Start the ISO build and check that the run passed:
   `gh workflow run build-iso.yml --repo maitrios/maitri --ref main -f release_tag=vX.Y.Z`.
   If only its `publish` job failed, re-run that job with `gh run rerun <run-id> --failed --repo
   maitrios/maitri`; it reuses the build, which is kept for 7 days.
5. Comment on the issue with the tag, the maitri-pkgs commit and the release link, then close it.
   The QEMU smoke test stays with Andrew.

## Edge

Every push to `main` triggers `notify-pkgs.yml`, which asks maitri-pkgs to rebuild `maitri-dev` and
`maitri-settings-dev` onto the `edge` channel. `maitri channel set edge` follows it.

## Repackage without a new tag

`scripts/bump-maitri vX.Y.Z --rebuild` in maitri-pkgs bumps `pkgrel`.

## ISO hosting

The offline ISO is several gigabytes, so `build-iso.yml` pushes it to Docker Hub as an OCI artifact via
[ORAS](https://oras.land). Its `build` job builds the tag's tree with no environment, no secrets and a
read-only token. Its `publish` job checks out only `main`, checks the tag again, refuses the ISO
unless the tag still points at the commit it was built from, and is the only job in the `docker-hub`
environment, which holds `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` (see
[Secrets](#secrets)). `DOCKERHUB_NAMESPACE`, a repository variable, is optional. Users download with:

```sh
oras pull docker.io/<namespace>/maitri-iso:<tag>
```

## Secrets

Every secret the workflows use lives in a GitHub environment that only accepts `main`:

| Environment | Secrets | Used by |
| --- | --- | --- |
| `release` | `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`, `R2_ENDPOINT` | `wallpapers.yml`, `publish` job |
| `docker-hub` | `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN` | `build-iso.yml`, `publish` job |
| `maitri-pkgs` | `MAITRI_PKGS_DISPATCH_TOKEN` | `notify-pkgs.yml` |

GitHub runs a workflow from the ref it starts on, so a run on any branch or tag uses that commit's
workflow files, reviewed or not. Those runs aren't on `main`, and the environments turn them away. Every
run that can reach a secret uses a workflow file from `main`, and the jobs that hold one check out
only `main`, so every script that sees a secret is main's reviewed copy.

That only holds while the secrets live in their environment and nowhere else. Never add them as
repository or organization secrets: re-tagging an old commit would bring back a workflow that reads
them from there. A new environment gets the same deployment rule (selected branches, `main` only)
and goes in the list in `test/shell.d/workflow-secrets-guard-test.sh`, which fails when a workflow
reads a secret outside one of them, in a job that isn't gated on `main`, or in a job that checks out
another ref or runs anything but main's code.
