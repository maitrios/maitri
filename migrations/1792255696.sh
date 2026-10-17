echo "Run herdr in ghostty and add the ghostty and herdr launchers"

maitri-pkg-add ghostty

if [[ ! -e ~/.config/ghostty && ! -L ~/.config/ghostty ]]; then
  mkdir -p ~/.config
  cp -R "$MAITRI_PATH/config/ghostty" ~/.config/
fi

maitri-refresh-applications
