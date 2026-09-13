# Setup user theme folder and seed the default only when no theme exists yet.
mkdir -p ~/.config/maitri/themes

if [[ ! -s $HOME/.local/state/maitri/current/theme.name ]]; then
  # iso-chroot and provision-owner both run without a live session to notify.
  if [[ ${MAITRI_SETUP_CONTEXT:-runtime} != "runtime" ]]; then
    MAITRI_THEME_HEADLESS=1 maitri-theme-set "Tokyo Night"
    rm -f ~/.config/chromium/SingletonLock # otherwise archiso owns the Chromium singleton
  else
    maitri-theme-set "Tokyo Night"
  fi
fi
maitri-theme-set-pi --activate

mkdir -p ~/.config/btop/themes
ln -snf "$HOME/.local/state/maitri/current/theme/btop.theme" ~/.config/btop/themes/current.theme
