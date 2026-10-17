# Wallpaper staging

Wallpapers don't live in git. This directory is where they're staged for an
upload: `wallpapers/<theme>/<any name>.{jpg,png,webp}`, one directory per theme
under `themes/`. Everything here except this README is ignored.

To ship them with a release, pack this directory and attach it to the release
as `wallpapers.tar`; `.github/workflows/wallpapers.yml` uploads the files under
their sha256 and publishes the manifest. Check what it would do first:

```bash
tools/wallpapers-upload.sh --dry-run vX.Y.Z
tar -cf wallpapers.tar -C wallpapers --exclude README.md .
```

The whole flow is in [`docs/wallpapers.md`](../docs/wallpapers.md).
