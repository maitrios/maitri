echo "Let fish follow the maitri theme instead of the colours pinned in config.fish"

config="${XDG_CONFIG_HOME:-$HOME/.config}/fish/config.fish"

if [[ -f $config ]] && grep -qE '^    # maitri "[A-Za-z]+" syntax colors$' "$config"; then
  tmp=$(mktemp)
  awk '
    function flush() {
      if (n == 0) return
      if (!(pinned && only)) for (i = 1; i <= n; i++) print held[i]
      n = 0
    }
    /^if status is-interactive$/ && n == 0 {
      held[++n] = $0
      pinned = 0
      only = 1
      next
    }
    n > 0 && /^end$/ {
      held[++n] = $0
      flush()
      next
    }
    n > 0 {
      held[++n] = $0
      if ($0 ~ /^    # maitri "[A-Za-z]+" syntax colors$/) pinned = 1
      else if ($0 !~ /^    set -g fish_color_(command|param|quote|redirection|error|autosuggestion|comment) [0-9A-Fa-f]{6}$/) only = 0
      next
    }
    { print }
    END { flush() }
  ' "$config" >"$tmp"
  cat "$tmp" >"$config"
  rm -f "$tmp"
fi

[[ -s $HOME/.local/state/maitri/current/theme.name ]] || exit 0
maitri-theme-refresh
