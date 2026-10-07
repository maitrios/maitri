# Acceptance Tests

Read this before writing or running the graphical acceptance suite under
`test/acceptance.d/`.

The graphical acceptance suite lives in `test/acceptance` with test files under
`test/acceptance.d/*-test.sh`. It exercises a real installed maitri desktop,
including session health, shell surfaces, panels, keyboard navigation,
representative applications, and system setup. Source
`test/acceptance.d/base-test.sh` for the shared helpers.

Run acceptance tests in a disposable VM, not in the active development session.
The suite opens and closes applications and temporarily changes desktop
configuration.

## Running the suite

There is currently no automated VM runner. Comments in `test/acceptance` and
`test/acceptance.d/security-test.sh` mention a `maitri-iso-test` harness, but
it isn't in this repo, so the loop is manual, using the ISO tools under
`iso/bin/` (see [`iso/README.md`](../../iso/README.md)):

1. Build an ISO. Changes to package manifests, installation, finalization, or
   shipped defaults need one built from your local checkouts:

   ```bash
   iso/bin/maitri-iso-make --no-boot-offer --keep-pkg-cache --local-source <maitri checkout> <maitri-pkgs checkout>
   ```

   The ISO lands in `iso/release/`. Without `--keep-pkg-cache` the build first
   wipes the host's pacman package cache with sudo. For changes that only touch
   the suite, any recent ISO will do.

2. Boot it in QEMU and install through the configurator:

   ```bash
   iso/bin/maitri-iso-boot --ssh-port 2222 iso/release/<iso>.iso
   ```

   Pass `--reuse` on later boots to keep the installed disk. To reach the guest
   over SSH, either autoinstall with an `authorized_keys` on a `cidata` drive
   (the ISO then enables sshd and opens the firewall for it), or run
   `maitri-setup-security-sshd` in the guest.

3. Copy the checkout's `test/` directory into the guest (the `maitri` package
   doesn't ship it) and run `test/acceptance` as the desktop user. The runner
   finds the graphical session on its own, so it works over SSH as well as from
   a terminal in the VM. It tests the installed tree under `/usr/share/maitri`
   unless `MAITRI_PATH` says otherwise, so source changes outside `test/` have
   to reach the guest as packages (a fresh ISO) or through `maitri dev link` on
   a checkout in the guest.

Useful knobs:

- `MAITRI_ACCEPTANCE_DIR` - where screenshots and logs land (default
  `/tmp/maitri-acceptance`); copy it back out of the guest to review a run.
- `MAITRI_ACCEPTANCE_SUDO_PASSWORD` - opts in to the sshd hardening exercise in
  `security-test.sh`, which reconfigures the machine. Only set it on a
  throwaway VM.
- `MAITRI_ACCEPTANCE_IGNORE_UNITS` - an extended regex of failed units
  `session-test.sh` should tolerate.
- `MAITRI_ACCEPTANCE_BOOT_TIMEOUT` / `MAITRI_ACCEPTANCE_TEST_TIMEOUT` - seconds
  to wait for Hyprland, and per test file.

## Writing tests

Keep unrelated acceptance workflows in separate test files. The runner records
a failed file and continues with the remaining files, which preserves as much
diagnostic coverage as possible. Restore modified user state with traps, close
anything the test opens, and capture every visually distinct state (including
entered input where relevant) as `success-<step>.png`; failure helpers capture
`failure-<step>.png`.

In-guest `wtype` is suitable for typing into focused controls, but it does not
reliably prove that a global Hyprland keybinding works. Nothing in the tree
sends compositor-level key chords from the host yet, so check global shortcuts
by hand in the VM window.
