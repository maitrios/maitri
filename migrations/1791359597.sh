echo "Show the MAITRI wordmark at boot and the new heart in About"

shipped_heart=d63ab4aa64657da1aec173fc2ead323630fe52b6a8d86c30ec1b42288f3d57bf
about="$HOME/.config/maitri/branding/about.txt"
if [[ -f $about && $(sha256sum <"$about") == "$shipped_heart  -" ]]; then
  cp "$MAITRI_PATH/icon.txt" "$about"
fi

logo=/usr/share/plymouth/themes/maitri/logo.png
[[ -f $logo ]] || exit 0

# /boot is root-only and only wheel can rebuild it; other users' migrations
# must not stall on a sudo prompt they can never answer.
[[ " $(id -nG) " == *" wheel "* ]] || exit 0

stale=$(sudo find /boot -xdev \( -path '/boot/EFI/Linux/*.efi' -o -name 'initramfs-*.img' \) \
  ! -newer "$logo" -print -quit)
[[ -n $stale ]] || exit 0

if maitri-cmd-present limine-mkinitcpio; then
  sudo limine-mkinitcpio
else
  sudo mkinitcpio -P
fi
