#!/bin/bash

set -e

MAITRI_ISO_REF="${MAITRI_ISO_REF:-main}"
MAITRI_MIRROR="${MAITRI_MIRROR:-stable}"

# Edge, dev, and local-source ISOs install the dev packages explicitly. Those
# package recipes track the main branch. This avoids relying on pacman's
# provides=maitri resolution and shows the real package names being tested in
# the offline mirror and target install. Every other ref, the default main
# build included, installs the published maitri packages.
case "$MAITRI_ISO_REF" in
  edge|dev|local)
    : "${MAITRI_RUNTIME_PACKAGE:=maitri-dev}"
    : "${MAITRI_SETTINGS_PACKAGE:=maitri-settings-dev}"
    ;;
  *)
    : "${MAITRI_RUNTIME_PACKAGE:=maitri}"
    : "${MAITRI_SETTINGS_PACKAGE:=maitri-settings}"
    ;;
esac
: "${MAITRI_NVIM_PACKAGE:=maitri-nvim}"
export MAITRI_RUNTIME_PACKAGE MAITRI_SETTINGS_PACKAGE MAITRI_NVIM_PACKAGE

# Packages installed into the Arch container used to build the ISO.
pacman-key --init
pacman --noconfirm -Sy archlinux-keyring
# Full upgrade, not just -Sy: docker never re-pulls :latest once it's cached,
# so this container can be months behind the mirror it installs from. A plain
# -Sy install is then a partial upgrade — new packages linked against a glibc
# the container doesn't have yet.
pacman --noconfirm -Syu archiso git sudo base-devel jq grub imagemagick neovim nodejs npm tree-sitter-cli

# Pre-import the maitri signing key (so pacman trusts our [maitri] repo
# during the build without keyserver lookups).
pacman-key --add /builder/maitri.gpg
pacman-key --lsign-key B15B4ED7BC9470F1710484ABB9562AC7D0D9EA1F

# maitri-keyring is needed inside the offline mirror too.
pacman --config /configs/pacman-online-${MAITRI_MIRROR}.conf --noconfirm -Sy maitri-keyring
pacman-key --populate maitri

# Append the [maitri] repo to the container's /etc/pacman.conf so subsequent
# tools (notably makepkg in build-maitri-packages.sh) can resolve maitri-
# only build deps like limine-snapper-sync and limine-mkinitcpio-hook.
if ! grep -q '^\[maitri\]' /etc/pacman.conf; then
  awk '/^\[maitri\]/,/^$/' /configs/pacman-online-${MAITRI_MIRROR}.conf >> /etc/pacman.conf
fi

# Build locations
build_cache_dir=/var/cache
offline_mirror_dir="$build_cache_dir/airootfs/var/cache/maitri/mirror/offline"
mkdir -p "$build_cache_dir" "$offline_mirror_dir"

# Seed from the official Arch releng profile shipped by the archiso package.
cp -r /usr/share/archiso/configs/releng/* "$build_cache_dir/"
rm "$build_cache_dir/airootfs/etc/motd"

# We rely on the global CDN; drop reflector.
rm -rf "$build_cache_dir/airootfs/etc/systemd/system/multi-user.target.wants/reflector.service"
rm -rf "$build_cache_dir/airootfs/etc/systemd/system/reflector.service.d"
rm -rf "$build_cache_dir/airootfs/etc/xdg/reflector"

# Bring in our archiso profile additions.
cp -r /configs/* "$build_cache_dir/"
mkdir -p "$build_cache_dir/airootfs/usr/share/maitri-iso"
echo "$MAITRI_MIRROR" > "$build_cache_dir/airootfs/root/maitri_mirror"
echo "$MAITRI_ISO_REF" > "$build_cache_dir/airootfs/root/maitri_iso_ref"
cat > "$build_cache_dir/airootfs/usr/share/maitri-iso/package-targets" <<EOF
MAITRI_RUNTIME_PACKAGE=$MAITRI_RUNTIME_PACKAGE
MAITRI_SETTINGS_PACKAGE=$MAITRI_SETTINGS_PACKAGE
MAITRI_NVIM_PACKAGE=$MAITRI_NVIM_PACKAGE
EOF

if [[ ${MAITRI_INSTALL_DEBUG:-} == "1" ]]; then
  touch "$build_cache_dir/airootfs/usr/share/maitri-iso/install-debug"
  {
    echo "debug=1"
    echo "built_at=$(date -Is)"
    echo "ref=$MAITRI_ISO_REF"
    echo "mirror=$MAITRI_MIRROR"
    echo "runtime_package=$MAITRI_RUNTIME_PACKAGE"
    echo "settings_package=$MAITRI_SETTINGS_PACKAGE"
    echo "nvim_package=$MAITRI_NVIM_PACKAGE"
    if [[ -d /maitri-source ]]; then
      echo "maitri_source=/maitri-source"
      git -c safe.directory=/maitri-source -C /maitri-source rev-parse HEAD 2>/dev/null | sed 's/^/maitri_commit=/' || true
      git -c safe.directory=/maitri-source -C /maitri-source status --short 2>/dev/null | sed 's/^/maitri_status=/' || true
    fi
    if [[ -d /maitri-pkgs ]]; then
      echo "maitri_pkgs_source=/maitri-pkgs"
      git -c safe.directory=/maitri-pkgs -C /maitri-pkgs rev-parse HEAD 2>/dev/null | sed 's/^/maitri_pkgs_commit=/' || true
      git -c safe.directory=/maitri-pkgs -C /maitri-pkgs status --short 2>/dev/null | sed 's/^/maitri_pkgs_status=/' || true
    fi
  } > "$build_cache_dir/airootfs/usr/share/maitri-iso/build-info"
fi

# When --local-source is in effect, build maitri* from the mounted source
# trees and drop them in the offline mirror. Otherwise pacman -Syw below
# downloads the published versions from the maitri network mirror.
if [[ -d /maitri-source && -d /maitri-pkgs ]]; then
  bash /builder/build-maitri-packages.sh "$offline_mirror_dir"
  LOCAL_MAITRI_BUILD=1
fi

# Node.js binary for offline mise install.
NODE_DIST_URL="https://nodejs.org/dist/latest"
NODE_SHASUMS=$(curl -fsSL "$NODE_DIST_URL/SHASUMS256.txt")
NODE_FILENAME=$(echo "$NODE_SHASUMS" | grep "linux-x64.tar.gz" | awk '{print $2}')
NODE_SHA=$(echo "$NODE_SHASUMS" | grep "linux-x64.tar.gz" | awk '{print $1}')
curl -fsSL "$NODE_DIST_URL/$NODE_FILENAME" -o "/tmp/$NODE_FILENAME"
echo "$NODE_SHA /tmp/$NODE_FILENAME" | sha256sum -c -
mkdir -p "$build_cache_dir/airootfs/opt/packages/"
cp "/tmp/$NODE_FILENAME" "$build_cache_dir/airootfs/opt/packages/"

# Packages installed into the live ISO environment itself (NOT the target system).
# The selected maitri-settings package is needed here so its post_install hook
# drops maitri's plymouthd.conf into /etc/plymouth before mkarchiso builds the
# live initramfs.
arch_packages=(linux-t2 git gum jq openssl plymouth ttfx tzupdate maitri-keyring "$MAITRI_SETTINGS_PACKAGE" lvm2 cryptsetup parted)
printf '%s\n' "${arch_packages[@]}" >> "$build_cache_dir/packages.x86_64"

# The live ISO boots linux-t2 (see airootfs/etc/mkinitcpio.d/linux-t2.preset), so
# stock linux is a second kernel nobody boots: ~147MB of ISO, plus its own archiso
# initramfs, copied into both the ISO tree and the size-constrained FAT EFI image.
#
# It cannot just be deleted — releng's broadcom-wl hard-depends on it, and it is
# the only releng package that does, so pacman would drag the kernel straight back
# in. broadcom-wl is a prebuilt module for stock linux and cannot load on the
# kernel we boot, so it has done nothing since we started booting T2 anyway. The
# install is entirely offline and the live environment needs no Wi-Fi driver.
#
# Anchored so linux-t2 and linux-firmware are untouched.
sed -i -E '/^(linux|broadcom-wl)$/d' "$build_cache_dir/packages.x86_64"

# Build the offline mirror: everything pacstrap might want during the target
# install. With --local-source, the maitri* packages we just built are
# already in the mirror and we filter them out below. Without it, pacman -Syw
# pulls the published maitri* from the network mirror like any other package.
if [[ -d /maitri-source ]]; then
  base_pkg_lists=(/maitri-source/install/maitri-base.packages /maitri-source/install/maitri-other.packages)
  setup_form=/maitri-source/install/provisioning/setup-form.sh
else
  # Pull the same package lists out of the freshly-downloaded maitri runtime
  # package so we don't need a local checkout in the non-local-source path.
  bootstrap_cache_dir=/tmp/maitri-pkg-bootstrap
  rm -rf "$bootstrap_cache_dir" /tmp/offlinedb-bootstrap /tmp/maitri-pkglists
  mkdir -p "$bootstrap_cache_dir" /tmp/offlinedb-bootstrap
  pacman --config /configs/pacman-online-${MAITRI_MIRROR}.conf --noconfirm -Syw "$MAITRI_RUNTIME_PACKAGE" --cachedir "$bootstrap_cache_dir" --dbpath /tmp/offlinedb-bootstrap >/dev/null
  maitri_pkg=$(find "$bootstrap_cache_dir" -maxdepth 1 -type f -name "$MAITRI_RUNTIME_PACKAGE-*.pkg.tar.zst" | sort | head -1)
  if [[ -z $maitri_pkg ]]; then
    echo "ERROR: downloaded package for $MAITRI_RUNTIME_PACKAGE not found in $bootstrap_cache_dir" >&2
    exit 1
  fi
  mkdir -p /tmp/maitri-pkglists
  bsdtar -xf "$maitri_pkg" -C /tmp/maitri-pkglists usr/share/maitri/install/maitri-base.packages usr/share/maitri/install/maitri-other.packages
  base_pkg_lists=(/tmp/maitri-pkglists/usr/share/maitri/install/maitri-base.packages /tmp/maitri-pkglists/usr/share/maitri/install/maitri-other.packages)
  # Extracted on its own, tolerating a miss: bsdtar exits non-zero for a member
  # it can't find, so asking for this alongside the package lists would abort the
  # build here (set -e) with a bare "Not found in archive" instead of the
  # actionable error below.
  bsdtar -xf "$maitri_pkg" -C /tmp/maitri-pkglists usr/share/maitri/install/provisioning/setup-form.sh 2>/dev/null || true
  setup_form=/tmp/maitri-pkglists/usr/share/maitri/install/provisioning/setup-form.sh
fi

mkdir -p "$build_cache_dir/airootfs/usr/share/maitri-iso"
cp "${base_pkg_lists[0]}" "$build_cache_dir/airootfs/usr/share/maitri-iso/maitri-base.packages"
cp "${base_pkg_lists[1]}" "$build_cache_dir/airootfs/usr/share/maitri-iso/maitri-other.packages"

# The configurator's setup form comes from the runtime this ISO bundles, so the
# installer and the first-boot setup that finishes a deferred install can never
# disagree. A runtime predating the split ships no such file, which would leave
# the configurator with no prompts at all.
if [[ ! -f $setup_form ]]; then
  if [[ -d /maitri-source ]]; then
    echo "ERROR: the --local-source checkout ships no install/provisioning/setup-form.sh" >&2
    remedy="Update the checkout to a revision carrying the shared setup form."
  else
    echo "ERROR: $MAITRI_RUNTIME_PACKAGE does not ship install/provisioning/setup-form.sh" >&2
    remedy="Publish a runtime carrying the shared setup form, or build with --local-source against a checkout that has it."
  fi
  echo "       The configurator sources its prompts from that file, so this ISO" >&2
  echo "       would boot into an installer with no questions to ask." >&2
  echo "       $remedy" >&2
  exit 1
fi
cp "$setup_form" "$build_cache_dir/airootfs/usr/share/maitri-iso/setup-form.sh"

# Collect every package we want available in the offline mirror.
declare -a all_packages
mapfile -t all_packages < <(
  {
    cat "$build_cache_dir/packages.x86_64"
    grep -hv '^#\|^$' "${base_pkg_lists[@]}"
    grep -hv '^#\|^$' /builder/archinstall.packages
    # Always include the selected maitri packages so the target install can
    # find the runtime and companion packages in the offline mirror.
    printf '%s\n' "$MAITRI_RUNTIME_PACKAGE" "$MAITRI_SETTINGS_PACKAGE" "$MAITRI_NVIM_PACKAGE"
  } | sort -u
)

# Arch dropped the prebuilt broadcom-wl on 2026-09-02 and rebuilt broadcom-wl-dkms
# with replaces=(broadcom-wl). A replaces entry only helps upgrades of an already
# installed package; as an explicit pacman target the old name now fails with
# "target not found". Published maitri runtime packages that predate the rename
# still list it in maitri-other.packages, so map it here until every channel
# ships a runtime that names broadcom-wl-dkms itself.
mapfile -t all_packages < <(
  printf '%s\n' "${all_packages[@]}" | sed 's/^broadcom-wl$/broadcom-wl-dkms/' | sort -u
)

# With --local-source we already built these maitri* packages directly into
# the mirror; strip them from the pacman -Syw list so it doesn't try to fetch
# the published versions on top.
if [[ -n ${LOCAL_MAITRI_BUILD:-} ]]; then
  mapfile -t all_packages < <(
    printf '%s\n' "${all_packages[@]}" |
      grep -Fxv \
        -e "$MAITRI_RUNTIME_PACKAGE" \
        -e "$MAITRI_SETTINGS_PACKAGE" \
        -e "$MAITRI_NVIM_PACKAGE" || true
  )
fi

mkdir -p /tmp/offlinedb
download_offline_packages() {
  pacman --config /configs/pacman-online-${MAITRI_MIRROR}.conf --noconfirm -Syw \
    "${all_packages[@]}" --cachedir "$offline_mirror_dir/" --dbpath /tmp/offlinedb --needed
}

# A repository may occasionally republish a package without changing its
# filename. Pacman detects that the persistent cached copy no longer matches
# the refreshed repository checksum and deletes it, but still fails the
# transaction. Retry once so the now-missing package is downloaded.
if ! download_offline_packages; then
  echo "Offline package download failed; retrying after pacman cleaned invalid cached files..." >&2
  download_offline_packages
fi

# Resolve the exact filenames chosen by the same synced package databases used
# for the download. Pruning by this transaction (rather than merely keeping the
# newest version of every cached package name) removes packages that have left
# the lists or dependency closure, such as an old Electron major version.
if ! resolved_package_files="$(
  pacman --config "/configs/pacman-online-${MAITRI_MIRROR}.conf" --noconfirm \
    --dbpath /tmp/offlinedb -S --print --print-format '%f' "${all_packages[@]}"
)"; then
  echo "ERROR: could not resolve the package files required by the offline mirror" >&2
  exit 1
fi
mapfile -t required_package_files <<< "$resolved_package_files"

# The online transaction intentionally excludes packages built from the local
# checkouts. Add those exact artifacts back to the keep-set after verifying
# that the local build left exactly one file for each selected package name.
if [[ -n ${LOCAL_MAITRI_BUILD:-} ]]; then
  for local_package_name in \
    "$MAITRI_RUNTIME_PACKAGE" "$MAITRI_SETTINGS_PACKAGE" "$MAITRI_NVIM_PACKAGE"; do
    local_package_file=""
    for candidate in "$offline_mirror_dir/$local_package_name-"*.pkg.tar.*; do
      [[ -f $candidate && $candidate != *.sig ]] || continue
      read -r candidate_name _ < <(pacman -Qp "$candidate" 2>/dev/null) || continue
      [[ $candidate_name == "$local_package_name" ]] || continue
      if [[ -n $local_package_file ]]; then
        echo "ERROR: multiple local builds found for $local_package_name" >&2
        exit 1
      fi
      local_package_file="${candidate##*/}"
    done
    if [[ -z $local_package_file ]]; then
      echo "ERROR: local build not found for $local_package_name" >&2
      exit 1
    fi
    required_package_files+=("$local_package_file")
  done
fi

printf '%s\n' "${required_package_files[@]}" |
  bash /builder/prune-offline-mirror.sh "$offline_mirror_dir"

# Rebuild the offline repo db from scratch so size/checksum/depends entries
# always reflect only the package files selected for this build.
rm -f "$offline_mirror_dir"/offline.db* "$offline_mirror_dir"/offline.files*
repo-add "$offline_mirror_dir/offline.db.tar.gz" "$offline_mirror_dir/"*.pkg.tar.zst

# mkarchiso expects the mirror at /var/cache/maitri/mirror/offline inside the
# container (the airootfs path); symlink rather than duplicate.
mkdir -p /var/cache/maitri/mirror
ln -sf "$offline_mirror_dir" /var/cache/maitri/mirror/offline

# Denominator for the install dashboard's progress bar. Resolving the mirror's
# own package lists against the mirror we just indexed, with an empty local db,
# is the question pacstrap asks at install time — same resolver, same repo, same
# lists — so no hand-kept constant can drift.
#
# It over-counts by ~1 in 925: archinstall.packages lists both amd-ucode and
# intel-ucode because the mirror must contain either. phases.py records expected
# and actual in the timing JSON, so growing drift shows up in acceptance runs.
# The early-bootstrap set is already inside this closure, so restating it would
# only add a second list to drift.
resolve_expected_packages() {
  local resolve_root=/tmp/maitri-expected-packages
  local resolved
  local -a targets

  rm -rf "$resolve_root"
  mkdir -p "$resolve_root/var/lib/pacman"

  mapfile -t targets < <(
    {
      grep -hv '^#\|^$' /builder/archinstall.packages
      # Read the shipped copy, which is what _runtime_package_list reads at
      # install time, not the build-time source it came from.
      grep -hv '^#\|^$' \
        "$build_cache_dir/airootfs/usr/share/maitri-iso/maitri-base.packages"
      printf '%s\n' "$MAITRI_RUNTIME_PACKAGE" "$MAITRI_SETTINGS_PACKAGE" \
        "$MAITRI_NVIM_PACKAGE"
    } | sort -u
  )

  pacman --config "$build_cache_dir/pacman-offline.conf" \
    --root "$resolve_root" --dbpath "$resolve_root/var/lib/pacman" \
    --noconfirm -Sy >/dev/null || return 1

  # Capture before counting: no pipefail here, so a pacman failure inside a
  # pipeline would become a plausible partial count, which never trips the
  # dashboard's fallback.
  resolved="$(pacman --config "$build_cache_dir/pacman-offline.conf" \
    --root "$resolve_root" --dbpath "$resolve_root/var/lib/pacman" \
    --noconfirm -S --print --print-format '%n' "${targets[@]}")" || return 1

  printf '%s\n' "$resolved" | sort -u | grep -c .
}

# Worth failing the build over: -S --print only aborts when a target is missing
# from the offline repo, which would fail pacstrap the same way. A count that
# merely looks wrong is not — the dashboard falls back without the file.
if ! expected_packages="$(resolve_expected_packages)"; then
  echo "ERROR: could not resolve the target package count from the offline mirror." >&2
  echo "       pacman -S --print aborts the whole transaction if any single target" >&2
  echo "       is missing, so this almost certainly means pacstrap would fail the" >&2
  echo "       same way at install time." >&2
  exit 1
fi
if (( expected_packages < 600 || expected_packages > 2000 )); then
  echo "WARNING: resolved target package count $expected_packages is outside the" >&2
  echo "         expected 600-2000 range; shipping no denominator so the install" >&2
  echo "         dashboard falls back to its time-based curve." >&2
else
  printf '%s\n' "$expected_packages" \
    >"$build_cache_dir/airootfs/usr/share/maitri-iso/expected-packages"
  echo "Target install resolves to $expected_packages packages."
fi

# Live ISO uses the same offline pacman.conf.
cp "$build_cache_dir/pacman-offline.conf" "$build_cache_dir/airootfs/etc/pacman.conf"

# Build the ISO.
mkarchiso -v -w "$build_cache_dir/work/" -o /out/ "$build_cache_dir/"

# Match host UID/GID on output.
if [[ -n $HOST_UID && -n $HOST_GID ]]; then
  chown -R "$HOST_UID:$HOST_GID" /out/
fi
