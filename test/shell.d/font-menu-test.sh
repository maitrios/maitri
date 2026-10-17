#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

require_command node

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

declare -A families=(
  [ttf-bitstream-vera-mono-nerd]="BitstromWera Nerd Font"
  [ttf-cascadia-code-nerd]="CaskaydiaCove Nerd Font"
  [ttf-cascadia-mono-nerd]="CaskaydiaMono Nerd Font"
  [ttf-firacode-nerd]="FiraCode Nerd Font"
  [ttf-inconsolata-nerd]="Inconsolata Nerd Font"
  [ttf-iosevka-nerd]="Iosevka Nerd Font Mono"
  [ttf-meslo-nerd]="MesloLGL Nerd Font"
  [ttf-victor-mono-nerd]="VictorMono Nerd Font"
)

cat >"$test_tmp/maitri-install-font" <<'SH'
#!/bin/bash
printf '%s\t%s\t%s\n' "$@"
SH
chmod +x "$test_tmp/maitri-install-font"

entries=$(node -e '
  const fs = require("fs")
  const path = require("path")
  const menu = require(path.join(process.env.ROOT, "shell/plugins/menu/MenuModel.js"))
  const items = menu.parseMenuJsonc(fs.readFileSync(path.join(process.env.ROOT, "default/maitri/maitri-menu.jsonc"), "utf8"))
  for (const item of items.filter(item => item.id.startsWith("install.style.font."))) {
    if (item.aliases && item.aliases.length) throw new Error(`${item.id} has aliases`)
    process.stdout.write(`${item.id}\t${item.label}\t${item.action}\n`)
  }
')

[[ -n $entries ]] || fail "the install menu offers fonts"

declare -A offered=()
while IFS=$'\t' read -r id label action; do
  [[ $action == "maitri-install-font "* ]] || fail "$id installs through maitri-install-font" "$action"
  IFS=$'\t' read -r name package family < <(PATH="$test_tmp:$PATH" bash -c "$action")
  [[ $name == "$label" ]] || fail "$id installs under its menu label" "label '$label', installs '$name'"
  [[ -v families[$package] ]] || fail "$id installs a known Nerd Font package" "$package"
  [[ $family == "${families[$package]}" ]] || fail "$id sets the family $package registers" "sets '$family', registers '${families[$package]}'"
  offered[$package]=1
done <<<"$entries"
pass "every font in the install menu sets the family its package registers"

for package in ttf-cascadia-code-nerd ttf-firacode-nerd ttf-inconsolata-nerd ttf-victor-mono-nerd; do
  [[ -v offered[$package] ]] || fail "the install menu offers $package"
done
pass "the install menu offers Cascadia Code, Fira Code, Inconsolata and Victor Mono"

if [[ -r /var/lib/pacman/sync/extra.db ]] && command -v pacman >/dev/null; then
  for package in "${!offered[@]}"; do
    pacman -Si -- "$package" >/dev/null 2>&1 || fail "$package is a real package"
  done
  pass "every font package in the install menu resolves from the repos"
else
  skip "every font package in the install menu resolves from the repos"
fi

checked=0
for package in "${!offered[@]}"; do
  pacman -Q -- "$package" >/dev/null 2>&1 || continue
  fc-list : family | tr ',' '\n' | grep -Fxq -- "${families[$package]}" ||
    fail "installed $package registers ${families[$package]}"
  checked=1
done
if (( checked )); then
  pass "installed font packages register the families the menu sets"
else
  skip "installed font packages register the families the menu sets"
fi

grep -Fxq ttf-jetbrains-mono-nerd-basic "$ROOT/install/maitri-base.packages" ||
  fail "the default package set installs JetBrains Mono Nerd Font"
for config in alacritty/alacritty.toml foot/foot.ini ghostty/config; do
  grep -Fq "JetBrainsMono Nerd Font" "$ROOT/config/$config" ||
    fail "$config defaults to JetBrainsMono Nerd Font"
done
grep -Fq "<string>JetBrainsMono Nerd Font</string>" "$ROOT/default/fontconfig/conf.avail/50-maitri.conf" ||
  fail "fontconfig prefers JetBrainsMono Nerd Font for monospace"
pass "JetBrains Mono Nerd Font stays the default"

pkgbuild=""
for candidate in ${MAITRI_PKGS_PATH:+"$MAITRI_PKGS_PATH/pkgbuilds" "$MAITRI_PKGS_PATH"} "$ROOT/../maitri-pkgs/pkgbuilds"; do
  if [[ -f $candidate/ttf-jetbrains-mono-nerd-basic/PKGBUILD ]]; then
    pkgbuild="$candidate/ttf-jetbrains-mono-nerd-basic/PKGBUILD"
    break
  fi
done
if [[ -n $pkgbuild ]]; then
  grep -Eq '^provides=.*"ttf-jetbrains-mono-nerd=' "$pkgbuild" ||
    fail "ttf-jetbrains-mono-nerd-basic provides the Nerd variant" "$pkgbuild"
  grep -Fq 'JetBrainsMonoNerdFont-${font}.ttf' "$pkgbuild" ||
    fail "ttf-jetbrains-mono-nerd-basic ships the Nerd Font files" "$pkgbuild"
  pass "the default JetBrains Mono package is the Nerd variant"
else
  skip "the default JetBrains Mono package is the Nerd variant"
fi
