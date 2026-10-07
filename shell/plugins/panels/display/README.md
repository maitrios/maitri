# Display

maitri's display panel (`maitri.display`). It's the front end for
[hyprmoncfg](https://github.com/crmne/hyprmoncfg): monitor layouts and profiles
that `hyprmoncfgd` applies on hotplug, lid and resume, plus brightness and text
size. hyprmoncfgd is the only thing that writes monitor config; this panel only
talks to it over its socket.

## Provenance

Vendored from [crmne/omarchy-hyprmoncfg](https://github.com/crmne/omarchy-hyprmoncfg)
by Carmine Paolino, MIT (see `LICENSE`).

- Tag `v2.7.0` (`a93d3dc4f37a1c49911035cd3558fe718c5386ed`). The vendored files
  are identical at `193e5611f934eec42460ef75f3f46c2a8bd0252a`.
- Vendored: every `*.qml` and `*.js` at the repo root, `LICENSE`, `tests/*.test.js`
  and `tests/qml/`. Left out: README, DESIGN, `design/`, screenshots, `.github/`
  and the upstream `manifest.json`.

## maitri changes

1. Id `maitri.display` (upstream `crmne.hyprmoncfg`), with the shell-managed IPC
   target `maitri.display`.
2. No install or upgrade flow. hyprmoncfg ships with maitri, so a missing or
   outdated backend gets a plain explanation instead of an AUR install button.
3. `maitri-brightness-display` and `maitri-display-text-size` replace the
   upstream brightness and text-size commands. Text size is always available,
   since the command ships with maitri.
4. The layout editor opens with `maitri-launch-or-focus-tui hyprmoncfg` instead
   of the upstream desktop launcher.
5. Remaining upstream brand strings went through `tools/rebrand.sh --paths`.
6. A Scale row in the compact view, between Text size and Monitor Management,
   for the selected display (the one Brightness follows, which starts as the
   focused display). Picking a scale edits the draft through hyprmoncfgd and
   previews it, so Keep or Revert decides it like any other layout change. Keep
   saves it into the active profile. On the keyboard, Text size is row -2 and
   Scale is row -1: h/l moves the highlight and Enter applies it. The idea comes
   from the universal scale row in
   [gdeyoung/omarchy-displayplus](https://github.com/gdeyoung/omarchy-displayplus)
   (`UniversalScaleControl.qml` at `c7b6425`, MIT), narrowed to one display.
   `ScaleField` gained `cursorValue` for the keyboard highlight, and
   `tests/focused-scale.test.js` covers the row.

The vendored tests are updated to match each change. `test/shell.d/display-plugin-test.sh`
runs them.

## Syncing a new upstream release

1. Export the old and new tags: `git archive vOLD | tar -x -C old`, and the same
   for `vNEW` into `new`.
2. Run `tools/rebrand.sh --paths` over both trees so their brand strings line
   up with ours.
3. For each vendored file, `git merge-file shell/plugins/panels/display/<file> old/<file> new/<file>`.
   Copy in new upstream files and delete removed ones.
4. Grep for anything that needs the changes above again:
   `gtk-launch|pkg aur|installCommand|command -v`, and re-check the cursor
   slots around `compactTextSize` and `compactScaleField`.
5. Update the tests, bump `version` in `manifest.json`, the tag and commit here,
   then run `test/shell.d/display-plugin-test.sh` and `tools/rebrand.sh --check`.
