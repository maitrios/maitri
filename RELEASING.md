# Releasing maitri

A release is a git tag here, a pair of pinned packages on maitri-pkgs, and an ISO built from them.

## Versioning

maitri uses SemVer tags `vMAJOR.MINOR.PATCH`. `v0.x` is pre-stable; `v0.3.0` is the first release of
**Karuna**, maitri's package-backed generation (built on Omarchy 4). Tags from the 0.x git-pull line end at `v0.1-legacy`; the old `v0.2.0` release belongs to that line. Tags from the 0.x git-pull line end at `v0.1-legacy`. <!-- rebrand:keep -->

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
