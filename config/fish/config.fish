# maitri fish config. The maitri-fish package provides the shell functions,
# aliases, completions, the pure prompt and tool integrations (mise, zoxide, fzf)
# from its vendor conf.d, so this file only carries the maitri environment. The
# colours follow the maitri theme as universal variables, so a set -g
# fish_color_* here would pin them. Add your own aliases, functions and exports
# below.

# MAITRI_PATH: /etc/maitri.conf is written by `maitri dev link`; otherwise the
# package-backed install at /usr/share/maitri. Its bin/ only needs to be on
# PATH in dev-link mode, since the package installs /usr/bin/maitri-*.
if test -r /etc/maitri.conf
    set -l maitri_conf_path (string match -r '^MAITRI_PATH=(.*)$' -g < /etc/maitri.conf)
    if test -n "$maitri_conf_path"
        set -gx MAITRI_PATH $maitri_conf_path
    else
        set -gx MAITRI_PATH /usr/share/maitri
    end
else
    set -gx MAITRI_PATH /usr/share/maitri
end
if test "$MAITRI_PATH" != /usr/share/maitri
    fish_add_path --prepend "$MAITRI_PATH/bin"
end
fish_add_path --append "$HOME/.local/share/mise/shims" "$HOME/.local/bin"
test -r "$HOME/.local/state/maitri/current/theme/glamour.json"; and begin; command -q gh; or command -q glow; end; and not set -q GLAMOUR_STYLE; and set -gx GLAMOUR_STYLE "$HOME/.local/state/maitri/current/theme/glamour.json" # maitri:glamour-style
test -r "$HOME/.local/state/maitri/current/theme/glamour.json"; and command -q glow; and not set -q GLOW_STYLE; and set -gx GLOW_STYLE "$HOME/.local/state/maitri/current/theme/glamour.json" # maitri:glamour-style
