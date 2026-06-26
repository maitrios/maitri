echo "Set up the Vicinae launcher alongside Walker (install, service, theme, extension)"

# Existing installs never run install/config/vicinae.sh, so apply the same setup
# here. The script self-guards and is idempotent (refresh backs up configs), so
# sourcing it is safe to re-run. The Hyprland keybind/layer changes live under
# default/ and are sourced live, so they need no migration.
source "$MAITRI_PATH/install/config/vicinae.sh"

# The install script only enables the service (starts on next login); start it
# now so Super+Space works without a relogin.
systemctl --user start vicinae.service 2>/dev/null || true
