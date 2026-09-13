# maitri fish config. The maitri-fish package provides the shell functions,
# aliases, completions and tool integrations (mise, zoxide, starship, fzf)
# from its vendor conf.d, so this file only carries the maitri environment
# and the look. Add your own aliases, functions and exports below.

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

if status is-interactive
    # maitri "Spark" syntax colors
    set -g fish_color_command 82AAFF
    set -g fish_color_param E6E9F0
    set -g fish_color_quote 7DE38B
    set -g fish_color_redirection C99BFF
    set -g fish_color_error FF6E6E
    set -g fish_color_autosuggestion 7E879B
    set -g fish_color_comment 7E879B
end
