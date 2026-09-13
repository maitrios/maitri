echo "Switch Brave Origin from the beta to the stable release"

if maitri-pkg-present brave-origin-beta-bin; then
  default_browser=$(xdg-settings get default-web-browser 2>/dev/null || true)

  maitri-pkg-aur-add brave-origin-bin
  maitri-pkg-drop brave-origin-beta-bin

  mkdir -p ~/.config
  cp -f "$MAITRI_PATH/config/chromium-flags.conf" ~/.config/brave-origin-flags.conf
  rm -f ~/.config/brave-origin-beta-flags.conf

  if [[ $default_browser == "brave-origin-beta.desktop" ]]; then
    maitri-default-browser brave-origin
  fi
fi
