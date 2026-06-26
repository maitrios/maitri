# Set up hourly/daily /home snapshots with snapper, separate from the root config.
# Best-effort and idempotent: safe to source from the installer or a migration.

# chrootable_systemctl_enable is exported during install but not in a migration
# subshell, so pull it in if it isn't already defined.
if ! declare -F chrootable_systemctl_enable >/dev/null; then
  source "$MAITRI_PATH/install/helpers/chroot.sh"
fi

# Home snapshots need snapper and a btrfs root — bail quietly otherwise.
command -v snapper &>/dev/null || exit 0
command -v btrfs &>/dev/null || exit 0
[[ $(findmnt -n -o FSTYPE /) == btrfs ]] || exit 0

home_config_exists() {
  sudo snapper --csvout list-configs 2>/dev/null | awk -F, 'NR>1 {print $1}' | grep -qx home
}

# $1 = path to the mounted /home subvolume to register the config against
install_home_config() {
  if ! home_config_exists; then
    sudo snapper -c home create-config "$1"
  fi
  # Like the root config, replace snapper's generated file with ours (enables the timeline)
  sudo cp "$MAITRI_PATH/default/snapper/home" /etc/snapper/configs/home
}

enable_timers() {
  # Root stays TIMELINE_CREATE="no", so these timers only ever snapshot /home
  chrootable_systemctl_enable snapper-timeline.timer
  chrootable_systemctl_enable snapper-cleanup.timer
}

# Already its own subvolume (e.g. archinstall's default @home)? Just configure it.
if sudo btrfs subvolume show /home &>/dev/null; then
  install_home_config /home
  enable_timers
  exit 0
fi

# /home is a plain directory on the root subvolume. Converting it to its own
# subvolume is destructive-adjacent and only safe on a live, booted system, so
# skip it during a chroot install — those run on archinstall's @home layout anyway.
[[ -n ${MAITRI_CHROOT_INSTALL:-} ]] && exit 0

home_fstype=$(findmnt -n -o FSTYPE -T /home)
if [[ $home_fstype != btrfs ]]; then
  echo "Skipping /home snapshots: /home lives on a separate $home_fstype filesystem, which can't be converted."
  exit 0
fi

device=$(findmnt -n -o SOURCE -T /home | sed 's/\[.*//')
root_device=$(findmnt -n -o SOURCE -T / | sed 's/\[.*//')
if [[ $device != "$root_device" ]]; then
  echo "Skipping /home snapshots: /home is on a separate btrfs filesystem ($device); convert it manually if you want snapshots."
  exit 0
fi

echo "/home isn't its own btrfs subvolume yet, so it can't be snapshotted."
echo "maitri can convert it to an @home subvolume. Your files are reflink-copied"
echo "(instant, no extra disk), but the switch needs a reboot to take effect."
gum confirm "Convert /home to a btrfs subvolume now?" || {
  echo "Skipped /home conversion — no home snapshots set up."
  exit 0
}

# Safety net before we touch the layout
sudo snapper -c root create -c number -d "pre @home conversion" 2>/dev/null || true

uuid=$(findmnt -n -o UUID -T /home)
# Reuse the root entry's mount options, swapping in the @home subvolume
opts=$(awk '$2=="/" && $3=="btrfs" {print $4}' /etc/fstab | head -1 | sed -E 's/,?subvol(id)?=[^,]*//g')
[[ -n $opts ]] || opts="defaults"

top=$(mktemp -d)
sudo mount -o subvolid=5 "$device" "$top"

if [[ -e $top/@home ]]; then
  echo "An @home subvolume already exists on $device — aborting to avoid clobbering it." >&2
  sudo umount "$top" && rmdir "$top"
  exit 0
fi

sudo btrfs subvolume create "$top/@home"
sudo cp -a --reflink=always /home/. "$top/@home/"

# Files written to /home between this copy and the reboot are NOT carried into
# @home, so we force a reboot below to keep that window as small as possible
# rather than trying to quiesce a live session.

# Register the config now, against the new subvolume at its temporary mount; our
# config file rewrites SUBVOLUME to /home, where it lands after the reboot.
install_home_config "$top/@home"

sudo umount "$top" && rmdir "$top"

# Mount @home at /home on every boot
if ! awk '$2=="/home"' /etc/fstab | grep -q .; then
  echo "UUID=$uuid /home btrfs ${opts},subvol=/@home 0 0" | sudo tee -a /etc/fstab >/dev/null
fi

enable_timers

# In a live migration the new mount only activates after a reboot, and every write
# to the old /home until then is lost — so force it promptly. (The installer
# reboots on its own at the end, so leave it alone there.)
if [[ -z ${MAITRI_INSTALL:-} ]]; then
  echo "/home is ready as an @home subvolume. Rebooting in 10s to activate snapshots — save your work."
  sleep 10
  sudo reboot
fi
