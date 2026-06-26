# Vicinae launcher (Phase 1: runs alongside Walker; Super+Space opens Vicinae)
#
# vicinae-bin is currently AUR-only. Once it is mirrored into the [maitri]
# package channel, move it to install/maitri-apps.packages and drop this install.
if maitri-cmd-missing vicinae; then
  maitri-pkg-aur-add vicinae-bin
fi

# The package ships a user service; enable it so Vicinae starts on login.
# (uwsm setups use the unit rather than a Hyprland exec-once line.)
if maitri-cmd-present vicinae; then
  systemctl --user enable vicinae.service &>/dev/null || true
fi

# Seed the maitri Vicinae config.
maitri-refresh-config vicinae/settings.json

# Generate the Vicinae theme from the current maitri theme, if one is set.
maitri-theme-set-vicinae

# Install the maitri Vicinae extension by fetching a prebuilt bundle (best-effort).
maitri-refresh-vicinae-extension || true

# Restart Vicinae after package upgrades so the running server picks up changes.
sudo mkdir -p /etc/pacman.d/hooks
sudo tee /etc/pacman.d/hooks/vicinae-restart.hook > /dev/null << EOF
[Trigger]
Type = Package
Operation = Upgrade
Target = vicinae
Target = vicinae-bin
Target = vicinae-git

[Action]
Description = Restarting Vicinae after system update
When = PostTransaction
Exec = $MAITRI_PATH/bin/maitri-restart-vicinae
EOF
