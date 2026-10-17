echo "Show the loop heart and the lowercase maitri at boot, in About and in turns on the screensaver"

branding="$HOME/.config/maitri/branding"
shipped_heart=f4111533763f8ca81e2c9c524bb04ffbc10d9897724413abd5d6116b7a1aa2c4
shipped_wordmark=b5a6f0d7aa342dbcc9b9f7250b171992ae9b19bd318f0472fdcb9d77c16b618b

if [[ -f $branding/about.txt && $(sha256sum <"$branding/about.txt") == "$shipped_heart  -" ]]; then
  cp "$MAITRI_PATH/icon.txt" "$branding/about.txt"
fi
if [[ -f $branding/screensaver.txt && $(sha256sum <"$branding/screensaver.txt") == "$shipped_wordmark  -" ]]; then
  { cat "$MAITRI_PATH/icon.txt"; printf '\f\n'; cat "$MAITRI_PATH/logo.txt"; } >"$branding/screensaver.txt.new"
  mv "$branding/screensaver.txt.new" "$branding/screensaver.txt"
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
