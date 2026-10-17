echo "Theme GTK and libadwaita apps from the current maitri theme"

state="$HOME/.local/state/maitri/current"
[[ -s $state/theme.name ]] || exit 0

if [[ -f $state/theme/gtk.css ]]; then
  maitri-theme-set-gtk || true
else
  theme_name=$(<"$state/theme.name") || exit 0
  [[ -d $MAITRI_PATH/themes/$theme_name || -d $HOME/.config/maitri/themes/$theme_name ]] || exit 0
  maitri-theme-refresh || true
fi
