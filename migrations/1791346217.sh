echo "Create the /home/.snapshots subvolume for home snapshots"

as_root() {
  if (( EUID == 0 )); then
    "$@"
  else
    sudo "$@"
  fi
}

command -v snapper >/dev/null || exit 0
[[ -f /etc/snapper/configs/home ]] || exit 0
as_root btrfs subvolume show /home >/dev/null 2>&1 || exit 0
as_root btrfs subvolume show /home/.snapshots >/dev/null 2>&1 && exit 0

MAITRI_PATH="${MAITRI_PATH:-/usr/share/maitri}"
as_root env MAITRI_PATH="$MAITRI_PATH" bash -euo pipefail "$MAITRI_PATH/install/config/snapper.sh"
