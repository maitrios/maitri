echo "Point gh and glow at the current theme's glamour style from fish"

fish_config="${XDG_CONFIG_HOME:-$HOME/.config}/fish/config.fish"
theme_name_path="$HOME/.local/state/maitri/current/theme.name"

if [[ -f $fish_config ]] && ! grep -qF '# maitri:glamour-style' "$fish_config"; then
  { echo; grep -F '# maitri:glamour-style' "$MAITRI_PATH/config/fish/config.fish"; } >>"$fish_config"
fi

[[ -s $theme_name_path ]] || exit 0
[[ ! -f $HOME/.local/state/maitri/current/theme/glamour.json ]] || exit 0

theme_name=$(<"$theme_name_path")
[[ -d $MAITRI_PATH/themes/$theme_name || -d $HOME/.config/maitri/themes/$theme_name ]] || exit 0

maitri-theme-refresh
