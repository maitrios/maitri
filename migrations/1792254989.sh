echo "Point gh and glow at the current theme's glamour style from fish"

fish_config="$HOME/.config/fish/config.fish"
style_line='test -r "$HOME/.local/state/maitri/current/theme/glamour.json"; and set -gx GLAMOUR_STYLE "$HOME/.local/state/maitri/current/theme/glamour.json"; and set -gx GLOW_STYLE $GLAMOUR_STYLE # maitri:glamour-style'
theme_name_path="$HOME/.local/state/maitri/current/theme.name"

# A config that already names a style, maitri's or the user's own, keeps it.
if [[ -f $fish_config ]] && ! grep -qE 'maitri:glamour-style|GLAMOUR_STYLE|GLOW_STYLE' "$fish_config"; then
  printf '\n%s\n' "$style_line" >>"$fish_config"
fi

[[ -s $theme_name_path ]] || exit 0
[[ ! -f $HOME/.local/state/maitri/current/theme/glamour.json ]] || exit 0

theme_name=$(<"$theme_name_path")
[[ -d $MAITRI_PATH/themes/$theme_name || -d $HOME/.config/maitri/themes/$theme_name ]] || exit 0

maitri-theme-refresh
