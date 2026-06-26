# Vicinae launcher integration.
#
# The vicinae-bin package and the prebuilt maitri-vicinae-extension bundle both ship
# via the [maitri] channel (install/maitri-apps.packages), so the launcher is already
# installed here — and works on an offline install. vicinae-bin ships its own pacman
# hook to restart the user service after upgrades, so we don't add one.

# The package ships a user service; enable it so Vicinae starts on login.
# (uwsm setups use the unit rather than a Hyprland exec-once line.)
if maitri-cmd-present vicinae; then
  systemctl --user enable vicinae.service &>/dev/null || true
fi

# Seed the maitri Vicinae config.
maitri-refresh-config vicinae/settings.json

# Generate the Vicinae theme from the current maitri theme, if one is set.
maitri-theme-set-vicinae

# Install the maitri Vicinae extension into the user's extensions dir (from the
# packaged bundle, falling back to a GitHub release on dev machines).
maitri-refresh-vicinae-extension || true
