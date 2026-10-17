echo "Switch ghostty's async backend from epoll to io_uring"

config="$HOME/.config/ghostty/config"

if [[ -L $config ]]; then
  config=$(readlink -f "$config")
fi

[[ -f $config ]] && grep -qx "async-backend = epoll" "$config" || exit 0

sed -i \
  -e '\|^# Fix general slowness on hyprland (https://github.com/ghostty-org/ghostty/discussions/3224)$|c\
# epoll crashes on bursts of terminal replies, like herdr'"'"'s palette queries on attach\
# (https://github.com/mitchellh/libxev/issues/234), so stick to io_uring until a fix ships.' \
  -e 's/^async-backend = epoll$/async-backend = io_uring/' \
  "$config"
