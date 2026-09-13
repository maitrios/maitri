SNAPPER_CONFIG_PATH="${MAITRI_SNAPPER_CONFIG_PATH:-/etc/snapper/configs/root}"
SNAPPER_CONF_PATH="${MAITRI_SNAPPER_CONF_PATH:-/etc/conf.d/snapper}"
template="${MAITRI_SNAPPER_TEMPLATE:-${MAITRI_PATH:-/usr/share/maitri}/default/snapper/root}"

echo "Configuring maitri Snapper snapshot retention"

if [[ ! -f $SNAPPER_CONFIG_PATH ]]; then
  mkdir -p "$(dirname "$SNAPPER_CONFIG_PATH")"

  if [[ ${MAITRI_SNAPPER_CONFIGURE_TEST:-0} == "1" ]]; then
    : >"$SNAPPER_CONFIG_PATH"
  else
    snapper --no-dbus -c root create-config / >/dev/null 2>&1 || snapper -c root create-config / >/dev/null
  fi
fi

install -m 0644 "$template" "$SNAPPER_CONFIG_PATH"

# /home gets its own config with hourly/daily timeline snapshots, so a botched
# dotfile edit is recoverable without rolling the whole system back. The ISO
# lays /home out as the @home subvolume; a plain directory is left alone
# (maitri-setup-home-snapshots converts it on a running system).
HOME_SNAPPER_CONFIG_PATH="${MAITRI_SNAPPER_HOME_CONFIG_PATH:-/etc/snapper/configs/home}"
home_template="${MAITRI_SNAPPER_HOME_TEMPLATE:-${MAITRI_PATH:-/usr/share/maitri}/default/snapper/home}"
snapper_configs="root"

home_is_subvolume() {
  if [[ ${MAITRI_SNAPPER_CONFIGURE_TEST:-0} == "1" ]]; then
    [[ ${MAITRI_SNAPPER_HOME_SUBVOLUME_TEST:-0} == "1" ]]
  else
    btrfs subvolume show /home >/dev/null 2>&1
  fi
}

if home_is_subvolume; then
  if [[ ! -f $HOME_SNAPPER_CONFIG_PATH ]]; then
    mkdir -p "$(dirname "$HOME_SNAPPER_CONFIG_PATH")"

    if [[ ${MAITRI_SNAPPER_CONFIGURE_TEST:-0} == "1" ]]; then
      : >"$HOME_SNAPPER_CONFIG_PATH"
    else
      snapper --no-dbus -c home create-config /home >/dev/null 2>&1 || snapper -c home create-config /home >/dev/null
    fi
  fi

  install -m 0644 "$home_template" "$HOME_SNAPPER_CONFIG_PATH"
  snapper_configs="root home"
fi

mkdir -p "$(dirname "$SNAPPER_CONF_PATH")"
printf 'SNAPPER_CONFIGS="%s"\n' "$snapper_configs" >"$SNAPPER_CONF_PATH"
chmod 0644 "$SNAPPER_CONF_PATH"

# The root config keeps TIMELINE_CREATE="no", so the timeline timer only ever
# snapshots /home; without a home config there is nothing for it to do.
if [[ $snapper_configs == *home* ]]; then
  systemctl enable --now snapper-timeline.timer >/dev/null 2>&1 || true
else
  systemctl disable --now snapper-timeline.timer >/dev/null 2>&1 || true
fi
systemctl enable --now snapper-cleanup.timer limine-snapper-sync.service >/dev/null 2>&1 || true
