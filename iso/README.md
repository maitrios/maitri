# maitri ISO

The maitri ISO is the only supported way to install maitri. It boots a live Arch environment with
the maitri configurator, installs Arch and the maitri packages from a mirror bundled inside the
ISO (so the install works offline), runs maitri's system setup in the target, creates the user with
fish as the login shell, and finalizes the user. It is Omarchy's ISO builder, rebranded and pointed at
the `[maitri]` channel.

## Creating the ISO

```bash
iso/bin/maitri-iso-make                 # published stable packages, maitri + maitri-settings
iso/bin/maitri-iso-make --edge          # edge channel: maitri-dev + maitri-settings-dev
iso/bin/maitri-iso-make --local-source ~/dev/kindness/maitri ~/dev/kindness/maitri-pkgs
```

Output lands in `./release`. The build runs inside an `archlinux/archlinux` container with Docker
(privileged, for `mkarchiso`) and needs roughly 30 GB of free disk. `--local-source` builds the dev
package pair and `maitri-nvim` from the two checkouts and drops them into the offline mirror.
`--no-boot-offer` skips the QEMU prompt at the end; `--debug` writes build info into the live root.

The builder trusts the maitri signing key from `builder/maitri.gpg`, installs `maitri-keyring`, and
fills the offline mirror from `configs/pacman-online-<channel>.conf`: official Arch mirrors plus the
`[maitri]` GitHub Release for the channel. It reads the package lists straight out of the runtime
package it downloads (or the `--local-source` checkout).

## Testing the ISO

`iso/bin/maitri-iso-boot release/maitri-*.iso` boots it in QEMU with OVMF (`--reuse` keeps the disk,
`--ssh-port` forwards SSH, `--` passes extra QEMU args). `iso/test/all` runs the unit tests.

## Autoinstall

Attach a drive labelled `cidata` carrying the configurator's own output files
(`user_configuration.json`, `user_credentials.json`, optionally `user_full_name.txt`,
`user_email_address.txt`, `user_encrypt_installation.txt`, `authorized_keys`, `tailscale_authkey`) and
the installer skips the wizard. Run one interactive install and copy what it wrote into `/root` to
get a starting set; hash the password with `openssl passwd -6`.

## CI

[`build-iso.yml`](../.github/workflows/build-iso.yml) builds on a published release (after waiting for
the stable channel to carry that version) or on demand, pushes the ISO to Docker Hub as an OCI artifact
via ORAS, and attaches the `.sha256` to the release. See [RELEASING.md](../RELEASING.md).
