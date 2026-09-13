# Capture and Sharing

Read this before taking screenshots or screen recordings, extracting text from
the screen, or sharing files with other machines.

## Screenshots

```bash
maitri screenshot                            # Interactive smart-region flow
maitri capture screenshot region             # Select a region
maitri capture screenshot windows            # Pick a window
maitri capture screenshot fullscreen save    # Full screen, straight to disk (no editor)
```

The first argument picks the mode (`smart|region|windows|fullscreen`), the
second what happens with it (`slurp|copy|save`). `save` skips the annotation
editor and prints the saved path. Screenshots land in the configured Pictures
directory (override with `MAITRI_SCREENSHOT_DIR`).

## Screen Recording

```bash
maitri screenrecord --fullscreen             # Start recording the full screen
# ...exercise whatever you want on film...
maitri screenrecord --stop-recording         # Stop; prints the saved path
```

Optional flags: `--with-desktop-audio`, `--with-microphone-audio`,
`--with-webcam` (plus `--webcam-device=` and `--webcam-size=`), and
`--resolution=<size>`. Without `--fullscreen` a region picker opens first.
Recordings land in the configured Videos directory (override with
`MAITRI_SCREENRECORD_DIR`). Resize a live webcam overlay with
`maitri capture webcam resize <smaller|larger|reset|small|medium|large>`.

If recording fails to start, rerun with `MAITRI_SCREENRECORD_DEBUG=true` to
collect a log at `/tmp/maitri-screenrecord.log` worth attaching to a bug
report.

## Text Capture (OCR)

```bash
maitri capture text    # Select a region; extracted text goes to the clipboard
```

## Sharing Files

```bash
maitri share clipboard               # Share the clipboard via LocalSend
maitri share file <path...>          # Share files with nearby devices
maitri share folder <path>           # Share a folder

maitri tailscale send <machine> <file...>    # Taildrop to a tailnet machine
maitri tailscale receive [directory]         # Save incoming Taildrop files
```

Shrink large captures before sharing them:

```bash
maitri transcode <input> [format] [resolution]   # Re-encode pictures/videos for sharing
```
