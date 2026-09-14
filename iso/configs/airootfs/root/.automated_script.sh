#!/usr/bin/env bash
#
# Live ISO entry point on tty1: set up the live VT, run the configurator
# wizard, then hand off to the Python install orchestrator. Mirrors the
# stream/env contract from the previously-working installer:
#   - stdout teed to /var/log/maitri-install.log (CSI-stripped) AND to tty
#   - stderr direct to /dev/tty so gum (which draws its TUI on stderr)
#     renders correctly
#   - CLICOLOR_FORCE/FORCE_COLOR so gum emits ANSI even with stdout piped
#   - COLUMNS/LINES so gum picks up real terminal size
set -euo pipefail

[[ $(tty) == /dev/tty1 ]] || exit 0

export MAITRI_MIRROR="$(cat /root/maitri_mirror)"
if [[ -f /root/maitri_iso_ref ]]; then
  export MAITRI_ISO_REF="$(cat /root/maitri_iso_ref)"
fi
if [[ -f /usr/share/maitri-iso/package-targets ]]; then
  # shellcheck disable=SC1091
  source /usr/share/maitri-iso/package-targets
  export MAITRI_RUNTIME_PACKAGE MAITRI_SETTINGS_PACKAGE MAITRI_NVIM_PACKAGE
fi
export MAITRI_PATH=/usr/share/maitri
export MAITRI_INSTALL=$MAITRI_PATH/install
export MAITRI_INSTALL_LOG_FILE=/var/log/maitri-install.log
if [[ -f /usr/share/maitri-iso/install-debug ]]; then
  export MAITRI_INSTALL_DEBUG=1
fi

# Spark palette so the live VT matches the installed look.
set_spark_colors() {
  echo -en "\e]P00b0f17"; echo -en "\e]P1ff6e6e"; echo -en "\e]P27de38b"
  echo -en "\e]P3ffd479"; echo -en "\e]P482aaff"; echo -en "\e]P5c99bff"
  echo -en "\e]P66fe6d9"; echo -en "\e]P7b8bed0"; echo -en "\e]P82c3548"
  echo -en "\e]P9ff8b8b"; echo -en "\e]PA9ceba6"; echo -en "\e]PBffe099"
  echo -en "\e]PCa0c0ff"; echo -en "\e]PDdbb6ff"; echo -en "\e]PE97f0e6"
  echo -en "\e]PFffffff"
  echo -en "\033[0m"
  clear
}
set_spark_colors

mkdir -p /var/log
touch "$MAITRI_INSTALL_LOG_FILE"

export COLUMNS=$(tput cols)
export LINES=$(tput lines)
exec > >(tee >(sed -u 's/\x1b\[[0-9;?]*[A-Za-z]//g' >>"$MAITRI_INSTALL_LOG_FILE") 2>/dev/null) 2>/dev/tty
export CLICOLOR_FORCE=1
export FORCE_COLOR=1

if [[ ${MAITRI_INSTALL_DEBUG:-} == "1" ]]; then
  echo "=== maitri ISO debug build ==="
  [[ -f /usr/share/maitri-iso/build-info ]] && cat /usr/share/maitri-iso/build-info
  pacman -Q maitri-settings maitri-keyring 2>/dev/null || true
  echo "================================"
fi

# Warm the page cache for the bundled packages while the user works through the
# wizard. The install reads ~3GB out of the offline mirror, and pacman consumes
# it at only ~33MB/s, so on media slower than that the install is read-bound and
# every byte cached here is a byte it never waits for. On faster media this costs
# nothing but otherwise-idle bandwidth: the medium is untouched while the user
# types, and the target disk it writes to later is a different device.
#
# Clean page cache only, so the kernel reclaims it under pressure instead of
# OOMing, and a budget so small machines never evict what was just warmed.
# Set MAITRI_NO_PREFETCH=1 to A/B the same ISO with this disabled.
warm_offline_mirror() {
  local mirror=/var/cache/maitri/mirror/offline
  local budget_kb spent_kb=0 size_kb path

  [[ ${MAITRI_NO_PREFETCH:-} == 1 ]] && return 0
  [[ -d $mirror ]] || return 0

  budget_kb=$(($(awk '/^MemAvailable:/ { print $2 }' /proc/meminfo) / 2))
  ((budget_kb > 262144)) || return 0

  # Largest first: the install reads most of the mirror, so when the budget
  # cannot cover all of it this still front-loads the bytes that dominate.
  while read -r size_kb path; do
    ((spent_kb + size_kb > budget_kb)) && continue
    cat -- "$path" >/dev/null 2>&1 || true
    spent_kb=$((spent_kb + size_kb))
  done < <(du -k "$mirror"/*.pkg.tar.zst 2>/dev/null | sort -rn)
}

warm_offline_mirror &
warm_pid=$!
trap 'kill "$warm_pid" 2>/dev/null' EXIT

cd /root
# Autoinstall: a cidata drive carrying the configurator's own output files
# stands in for the wizard. maitri-cidata-load copies them into /root and
# everything downstream runs the ordinary path against ordinary inputs.
if /usr/local/bin/maitri-cidata-load; then
  echo "Autoinstall configuration found on cidata drive; skipping the configurator."
  export MAITRI_UI_INTERACTIVE=no
else
  ./configurator
fi

# Deferred-provisioning installs skip the celebration/reboot prompt and reboot on
# their own — the owner completes setup at first boot. Signalled by the config's
# defer_provisioning flag (interactive) or the defer-provisioning marker (cidata).
# Parse the flag with jq (the same JSON semantics the orchestrator uses) rather
# than a line regex, so a reformatted config can't read as a direct install.
if [[ -f /root/defer-provisioning ]] ||
  [[ "$(jq -r '.maitri_install.defer_provisioning // false' /root/user_configuration.json 2>/dev/null)" == "true" ]]; then
  export MAITRI_UI_DEFER_PROVISIONING=yes
fi

# The foreground dashboard is now the sole visible install UI owner. It starts
# the actual installer as a non-interactive child, logs child output, waits for
# completion, then renders the final installed-time/reboot prompt itself.
export MAITRI_DASHBOARD_TTY="$(tty)"
rm -f /run/maitri-install/state.json
/usr/local/bin/maitri-install-dashboard \
  "$MAITRI_INSTALL_LOG_FILE" \
  /run/maitri-install/state.json \
  -- \
  /usr/local/bin/maitri-iso-install \
    --config /root/user_configuration.json \
    --creds /root/user_credentials.json \
    --full-name-file /root/user_full_name.txt \
    --email-file /root/user_email_address.txt \
    --encrypt-file /root/user_encrypt_installation.txt \
    --authorized-keys-file /root/authorized_keys \
    --tailscale-authkey-file /root/tailscale_authkey \
    --defer-provisioning-file /root/defer-provisioning
