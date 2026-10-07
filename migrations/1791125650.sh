echo "Install the fingerprint resume hook on existing fingerprint setups"

# Existing enrolled machines never rerun setup. Install only missing files
# so administrator changes survive an upgrade.

hook_src="${MAITRI_FPRINTD_RESUME_SRC:-$MAITRI_PATH/default/systemd/system-sleep/fprintd-resume}"
hook_dst="${MAITRI_FPRINTD_RESUME_DST:-/usr/lib/systemd/system-sleep/fprintd-resume}"
stop_timeout_src="${MAITRI_FPRINTD_STOP_TIMEOUT_SRC:-$MAITRI_PATH/default/systemd/system/fprintd.service.d/10-stop-timeout.conf}"
stop_timeout_dst="${MAITRI_FPRINTD_STOP_TIMEOUT_DST:-/etc/systemd/system/fprintd.service.d/10-stop-timeout.conf}"
lock_pam="${MAITRI_LOCK_FINGERPRINT_PAM:-/etc/pam.d/maitri-lock-fingerprint}"

[[ -f $lock_pam ]] || exit 0

if [[ -f $hook_src && ! -e $hook_dst ]]; then
  echo "Installing the fprintd resume hook"
  sudo install -Dm755 "$hook_src" "$hook_dst"
fi

if [[ -f $stop_timeout_src && ! -e $stop_timeout_dst ]]; then
  sudo install -Dm644 "$stop_timeout_src" "$stop_timeout_dst"
  sudo systemctl daemon-reload
fi
