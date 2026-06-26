echo "Drop Chromium — Helium is now the engine behind the web-app launchers"

# Web apps now launch through Helium (the default browser) and fall back to Helium
# rather than Chromium, so the Chromium package is no longer needed.

# Move any install still defaulting to Chromium over to Helium first.
if [[ "$(xdg-settings get default-web-browser)" == "chromium.desktop" ]]; then
  maitri-default-browser helium
fi

# Remove the package and its now-dead config.
if maitri-cmd-present chromium; then
  maitri-pkg-drop chromium
fi
rm -f ~/.config/chromium-flags.conf
sudo rm -f /usr/lib/chromium/initial_preferences
sudo rm -rf /etc/chromium

# Refresh Helium's flags so existing installs pick up the copy-url extension that
# the web-app launchers previously got via Chromium.
maitri-refresh-config helium-browser-flags.conf
