echo "Let fish follow the maitri theme instead of the colours pinned in config.fish"

config="${XDG_CONFIG_HOME:-$HOME/.config}/fish/config.fish"

# The three blocks config.fish ever shipped. Only an exact match comes out, so a
# block with a colour the user changed or a line they added stays.
stock=$(mktemp)
cat >"$stock" <<'BLOCKS'
    # maitri "Spark" syntax colors
    set -g fish_color_command 82AAFF
    set -g fish_color_param E6E9F0
    set -g fish_color_quote 7DE38B
    set -g fish_color_redirection C99BFF
    set -g fish_color_error FF6E6E
    set -g fish_color_autosuggestion 7E879B
    set -g fish_color_comment 7E879B

    # maitri "Amethyst" syntax colors
    set -g fish_color_command B08CFF
    set -g fish_color_param E6E9F0
    set -g fish_color_quote 7DE38B
    set -g fish_color_redirection C99BFF
    set -g fish_color_error FF6E6E
    set -g fish_color_autosuggestion 8C7EA6
    set -g fish_color_comment 8C7EA6

    # maitri "Amethyst" syntax colors
    set -g fish_color_command B08CFF
    set -g fish_color_param E6E9F0
    set -g fish_color_quote 85DC8C
    set -g fish_color_redirection B08CFF
    set -g fish_color_error FD8993
    set -g fish_color_autosuggestion 8C7EA6
    set -g fish_color_comment 8C7EA6

BLOCKS

removed=""
if [[ -f $config ]] && grep -qE '^    # maitri "[A-Za-z]+" syntax colors$' "$config"; then
  tmp=$(mktemp)
  if awk '
    NR == FNR {
      if ($0 == "") { if (body != "") stock[body] = 1; body = ""; next }
      body = body $0 "\n"
      next
    }
    function flush(body, i) {
      if (n == 0) return
      for (i = 2; i < n; i++) body = body held[i] "\n"
      if (n > 2 && held[n] == "end" && (body in stock)) dropped = 1
      else for (i = 1; i <= n; i++) print held[i]
      n = 0
    }
    /^if status is-interactive$/ && n == 0 { held[++n] = $0; next }
    n > 0 && /^end$/ { held[++n] = $0; flush(); next }
    n > 0 { held[++n] = $0; next }
    { print }
    END {
      flush()
      exit !dropped
    }
  ' "$stock" "$config" >"$tmp"; then
    removed=1
    cat "$tmp" >"$config"
  fi
  rm -f "$tmp"
fi
rm -f "$stock"

[[ -s $HOME/.local/state/maitri/current/theme.name ]] || exit 0
maitri-theme-refresh
if [[ -n $removed ]]; then
  echo "fish shells that are already open keep their old colours until they're restarted." >&2
fi
