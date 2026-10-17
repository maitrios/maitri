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
4. Publish the GitHub release, which triggers the ISO build:

   ```bash
   gh release create vX.Y.Z --repo maitrios/maitri --target main --title "maitri vX.Y.Z" --generate-notes
   ```

   `build-iso.yml` waits for the `stable` channel to carry `maitri X.Y.Z`, builds the ISO, pushes it
   to Docker Hub as an OCI artifact (GitHub caps release assets at 2 GiB), attaches the `.sha256`,
   and appends the download link to the release notes.
5. Smoke test the ISO in QEMU (`iso/bin/maitri-iso-boot`).

Release notes are generated from merged pull requests, so land changes through PRs with clear titles.

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
4. Check that `build-iso.yml` started for the release. If it didn't, start it with
   `gh workflow run build-iso.yml -R maitrios/maitri -f release_tag=vX.Y.Z` (see its inputs).
5. Comment on the issue with the tag, the maitri-pkgs commit and the release link, then close it.
   The QEMU smoke test stays with Andrew.

## Edge

Every push to `main` triggers `notify-pkgs.yml`, which asks maitri-pkgs to rebuild `maitri-dev` and
`maitri-settings-dev` onto the `edge` channel. `maitri channel set edge` follows it.

## Repackage without a new tag

`scripts/bump-maitri vX.Y.Z --rebuild` in maitri-pkgs bumps `pkgrel`.

## ISO hosting

The offline ISO is several gigabytes, so `build-iso.yml` pushes it to Docker Hub as an OCI artifact via
[ORAS](https://oras.land). Repo settings needed: `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` (secrets)
and optionally `DOCKERHUB_NAMESPACE` (variable). Users download with:

```sh
oras pull docker.io/<namespace>/maitri-iso:<tag>
```
