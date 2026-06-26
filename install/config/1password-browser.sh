# maitri: let the 1Password desktop app accept connections from Helium, our default
# browser. 1Password only talks to a known set of browsers out of the box; Helium isn't
# one of them, so its native-messaging connection is refused until it's listed here.
# Each line in this file is a browser process name (Helium's binary is "helium").

allowed=/etc/1password/custom_allowed_browsers
sudo mkdir -p "$(dirname "$allowed")"
if ! sudo grep -qxF helium "$allowed" 2>/dev/null; then
  echo helium | sudo tee -a "$allowed" >/dev/null
fi
