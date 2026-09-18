echo "Retire the starship prompt now that fish ships pure"

starship_config="$HOME/.config/starship.toml"

# Every starship.toml maitri (and Omarchy before it) has seeded into /etc/skel.
# A file matching one of these is the untouched default; anything else is the
# user's own and stays, along with the starship package it configures.
shipped_hashes=(
  12bfa463875dc7163f62138d06e761a5a4b75c2649fdcf73affc862d6b0239e5
  164c0dc227ea0d8f34e14f01f9f6924efe3d38df9e3c39ec41c0e0b94fbcb9fa
  560d23d88e35687511831bcc34650e3d71a21718fe3bfcdf955e98ca288aa957
  75a35f5066ecb80a513aaa315a61e5b14bb917d2c6f5bcb96edaef77b02d028d
  8258f9f4f8318f3e7957ae7bb3082d92f13db940b932633ba8193299043b09a8
  89a6b6a10808f72eaa60163bb6a30ed1fbbf2fb359f9f6d09b953afb1bba051e
  95452846008fcf8c0cd7fb8bee39e91d75e262e43cebf5850b6715ad9bd3b39f
  b17c9b5f096fc125e97050e359171c6011d6b3c7d7e9ac28f630e75b4d4bb9db
  d03c970ec3d258e179fe6750c5241935d984964064ad679825186f2f491c69ec
)

if [[ -f $starship_config && ! -L $starship_config ]]; then
  config_hash=$(sha256sum "$starship_config")
  config_hash=${config_hash%% *}
  for shipped in "${shipped_hashes[@]}"; do
    if [[ $config_hash == "$shipped" ]]; then
      rm "$starship_config"
      break
    fi
  done
fi

[[ -e $starship_config ]] && exit 0

# Fails while an older maitri-fish still depends on starship, which keeps the
# migration pending until the pure-based maitri-fish has landed.
maitri-pkg-drop starship
