# Update localdb so locate can find the installed system files immediately.
# Match the scheduled service while installation runs without a system manager.
updatedb --prune-bind-mounts=no --add-prunepaths="/.snapshots /var/lib/docker" --add-prunenames="node_modules .venv target .next .turbo .cache"
