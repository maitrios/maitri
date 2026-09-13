# fish is maitri's default login shell. Bash stays configured for bash -lc,
# SSH commands and scripts; the maitri-fish package carries the fish side.
# Runs as root in the target chroot, so the login shell is set here rather
# than from the unprivileged per-user finalize step.
fish_path=/usr/bin/fish

if [[ -x $fish_path ]]; then
  grep -qxF "$fish_path" /etc/shells || echo "$fish_path" >>/etc/shells

  if [[ -n ${MAITRI_INSTALL_USER:-} ]]; then
    usermod -s "$fish_path" "$MAITRI_INSTALL_USER"
  fi
fi
