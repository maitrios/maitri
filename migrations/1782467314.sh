echo "Remove the legacy Walker + Elephant launcher (replaced by Vicinae)"

# Stop and disable the old user services.
for unit in app-walker@autostart.service elephant.service; do
  if systemctl --user list-unit-files "$unit" &>/dev/null; then
    systemctl --user disable --now "$unit" &>/dev/null || true
  fi
done

# Remove autostart entry, service drop-in, and user configs.
rm -f ~/.config/autostart/walker.desktop
rm -rf ~/.config/systemd/user/app-walker@autostart.service.d
rm -rf ~/.config/walker ~/.config/elephant
systemctl --user daemon-reload &>/dev/null || true

# Drop the pacman hook that restarted Walker on upgrade.
sudo rm -f /etc/pacman.d/hooks/walker-restart.hook

# Uninstall the packages if they are still present (raw pacman: maitri-pkg-remove
# is an interactive picker, unsuitable for an unattended migration).
for pkg in walker elephant-all; do
  if pacman -Q "$pkg" &>/dev/null; then
    sudo pacman -Rns --noconfirm "$pkg" &>/dev/null || true
  fi
done
