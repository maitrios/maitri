echo "Re-stage the current theme so Neovim switches to maitri's own colorscheme"

theme_name_path="$HOME/.local/state/maitri/current/theme.name"
neovim_theme="$HOME/.local/state/maitri/current/theme/neovim.lua"

[[ -s $theme_name_path && -f $neovim_theme ]] || exit 0
grep -q "aether" "$neovim_theme" || exit 0

theme_name=$(<"$theme_name_path")
[[ -d $MAITRI_PATH/themes/$theme_name || -d $HOME/.config/maitri/themes/$theme_name ]] || exit 0

maitri-theme-refresh
