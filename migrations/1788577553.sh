echo "Install Cursor CLI via mise wrapper"

# Cursor's own installer links ~/.local/bin/cursor-agent, so an existing
# command is the user's and stays. The wrapper resolves cursor-agent through
# mise's registry, which lists it from 2026.8.15 on.
if maitri-cmd-missing cursor-agent && [[ ! -f $HOME/.local/state/maitri/preinstalls-removed ]]; then
  maitri-mise-install cursor-agent
fi
