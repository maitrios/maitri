echo "Move anyone on the retired Orchid theme to Amethyst"

theme_name_path="$HOME/.local/state/maitri/current/theme.name"

[[ -s $theme_name_path ]] || exit 0
[[ $(<"$theme_name_path") == "orchid" ]] || exit 0
[[ ! -d $HOME/.config/maitri/themes/orchid ]] || exit 0

maitri-theme-set "Amethyst"
