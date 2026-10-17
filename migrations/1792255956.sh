echo "Let Neovim floats keep their depth in ~/.config/nvim/plugin/after/transparency.lua"

transparency="$HOME/.config/nvim/plugin/after/transparency.lua"
shipped_sha256=6e31b917f13e16514ac94ff9270d47f24e76509a3e559ca85116a5aa2d61306a
current_sha256=91bfa0b739b9bda9a48db6120612ecb11567ae190167540f0ccc3bd1035612b7

[[ -e $transparency || -L $transparency ]] || exit 0

leave_alone() {
  echo "Leaving $transparency as is since $1; drop NormalFloat, FloatBorder and Pmenu from its list to let floats keep their depth." >&2
  exit 0
}

[[ -L $transparency ]] && leave_alone "it's a symlink"
[[ -f $transparency ]] || leave_alone "it isn't a regular file"
[[ -r $transparency ]] || leave_alone "it can't be read"

sha256=$(sha256sum "$transparency" | cut -d' ' -f1)
[[ $sha256 == "$current_sha256" ]] && exit 0
[[ $sha256 == "$shipped_sha256" ]] || leave_alone "it was changed"
[[ -w ${transparency%/*} ]] || leave_alone "its folder is read-only"

tmp=$(mktemp "$transparency.XXXXXX") || leave_alone "a temp file can't be made beside it"
if ! { grep -Fvx -e $'\t"NormalFloat",' -e $'\t"FloatBorder",' -e $'\t"Pmenu",' "$transparency" >"$tmp" &&
  chmod --reference="$transparency" "$tmp" &&
  mv "$tmp" "$transparency"; }; then
  rm -f "$tmp"
  leave_alone "it couldn't be rewritten"
fi
