echo "Make hyprmoncfg the monitor manager"

had_hyprmoncfg=0
for package in hyprmoncfg hyprmoncfg-bin hyprmoncfg-git; do
  if maitri-pkg-present "$package"; then
    had_hyprmoncfg=1
  fi
done

# The AUR -bin and -git builds conflict with [maitri]'s package, so keep whichever is installed.
(( had_hyprmoncfg )) || maitri-pkg-add hyprmoncfg

config="$HOME/.config/hypr/hyprland.lua"
comment='-- Added by hyprmoncfg: its generated monitor rules load last, so nothing before this can override the applied layout.'
include='do local path = os.getenv("HOME") .. "/.config/hypr/hyprmoncfg-monitors.lua"; local file = io.open(path, "r"); if file then file:close(); dofile(path) end end'

if [[ -f $config ]] && ! grep -Fq "hyprmoncfg-monitors.lua" "$config"; then
  if (( had_hyprmoncfg )); then
    echo "hyprmoncfg isn't managing your displays. Run 'hyprmoncfg manage' to hand it display control."
    exit 0
  fi
  [[ -z $(tail -c1 "$config") ]] || printf '\n' >>"$config"
  printf '\n%s\n%s\n' "$comment" "$include" >>"$config"
fi

systemctl --user daemon-reload >/dev/null 2>&1 || true

if ! systemctl --user enable hyprmoncfgd.service >/dev/null 2>&1; then
  wants_dir="$HOME/.config/systemd/user/default.target.wants"
  mkdir -p "$wants_dir"
  ln -sfn /usr/lib/systemd/user/hyprmoncfgd.service "$wants_dir/hyprmoncfgd.service"
fi

if systemctl --user is-active --quiet graphical-session.target; then
  systemctl --user start hyprmoncfgd.service >/dev/null 2>&1 ||
    echo "Could not start hyprmoncfgd; it starts at your next login."
fi
