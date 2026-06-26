echo "Move the Vicinae launcher + extension onto the [maitri] package channel (offline-capable)"

# Offline parity: vicinae-bin and the maitri Vicinae extension now ship via the [maitri]
# channel (install/maitri-apps.packages) instead of AUR + a GitHub release fetched at setup.
# Pull them in (best-effort and tolerant: if the channel hasn't published them yet, the
# extension's GitHub fallback still applies and an existing AUR vicinae-bin keeps working),
# then reinstall the extension so it comes from the packaged bundle under /usr/share/maitri.
maitri-pkg-add vicinae-bin maitri-vicinae-extension || true
maitri-refresh-vicinae-extension || true
