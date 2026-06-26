echo "Set up hourly/daily /home snapshots with snapper"

# The setup script is idempotent and self-guarding (it sources its own helpers,
# bails on non-btrfs, and only converts /home when needed), so sourcing it here
# applies the same setup existing installs never ran during login.
source "$MAITRI_PATH/install/login/home-snapshots.sh"
