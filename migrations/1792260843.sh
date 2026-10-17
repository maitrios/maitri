echo "Point gh and glow at the current theme's glamour style from fish"

fish_config="${XDG_CONFIG_HOME:-$HOME/.config}/fish/config.fish"
theme_name_path="$HOME/.local/state/maitri/current/theme.name"
glamour_style="$HOME/.local/state/maitri/current/theme/glamour.json"

if [[ -f $fish_config ]] && ! grep -qF '# maitri:glamour-style' "$fish_config"; then
  target=$(readlink -f "$fish_config")
  if [[ ! -w $target || ! -w ${target%/*} ]]; then
    echo "Leaving $fish_config alone: it isn't writable. Copy the two '# maitri:glamour-style' lines from $MAITRI_PATH/config/fish/config.fish into it yourself."
  else
    { echo; grep -F '# maitri:glamour-style' "$MAITRI_PATH/config/fish/config.fish"; } >>"$fish_config"
  fi
fi

[[ -s $theme_name_path ]] || exit 0

theme_name=$(<"$theme_name_path")
if [[ ! -d $MAITRI_PATH/themes/$theme_name && ! -d $HOME/.config/maitri/themes/$theme_name ]]; then
  rm -f "$glamour_style"
  exit 0
fi

if ! maitri-theme-refresh; then
  rm -f "$glamour_style"
  echo "Couldn't refresh the $theme_name theme; gh and glow use their own style until the next maitri theme set." >&2
fi
