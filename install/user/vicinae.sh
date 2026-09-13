# The Vicinae launcher and the maitri extension ship as packages, and
# /etc/skel already seeded ~/.config/vicinae/settings.json. What is left is
# per-user: the generated theme and the extension copy Vicinae loads from
# ~/.local/share. The user service is enabled at first run with the other
# user units, once the user manager is live.
maitri-theme-set-vicinae
maitri-refresh-vicinae-extension || true
