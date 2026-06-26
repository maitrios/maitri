# Set links for Nautilus action icons
sudo ln -snf /usr/share/icons/Adwaita/symbolic/actions/go-previous-symbolic.svg /usr/share/icons/Yaru/scalable/actions/go-previous-symbolic.svg
sudo ln -snf /usr/share/icons/Adwaita/symbolic/actions/go-next-symbolic.svg /usr/share/icons/Yaru/scalable/actions/go-next-symbolic.svg

# Setup user theme folder
mkdir -p ~/.config/maitri/themes

# Helium (Chromium fork) policy directory for theme
sudo mkdir -p /etc/helium/policies/managed
sudo chmod a+rw /etc/helium/policies/managed

# Set initial theme
maitri-theme-set "Spark"

# Set specific app links for current theme
mkdir -p ~/.config/btop/themes
ln -snf ~/.config/maitri/current/theme/btop.theme ~/.config/btop/themes/current.theme

mkdir -p ~/.config/mako
ln -snf ~/.config/maitri/current/theme/mako.ini ~/.config/mako/config
