#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

TMPDIR=""

export PATH="$ROOT/bin:$PATH"

cleanup() {
  if [[ -n $TMPDIR && -d $TMPDIR ]]; then
    rm -rf "$TMPDIR"
  fi
}
trap cleanup EXIT

require_command jq

TMPDIR=$(mktemp -d)

grep -qx -- '--disable-gpu' "$ROOT/config/obsidian/user-flags.conf" || fail "shipped Obsidian flags use --disable-gpu"
pass "shipped Obsidian flags use --disable-gpu"

home="$TMPDIR/fresh"
HOME="$home" XDG_CONFIG_HOME="" maitri-install-obsidian-cli
jq -e '. == {cli: true}' "$home/.config/obsidian/obsidian.json" >/dev/null || fail "Obsidian CLI setup creates settings with the CLI on"
pass "Obsidian CLI setup creates settings with the CLI on"

home="$TMPDIR/existing"
mkdir -p "$home/.config/obsidian"
printf '{"vaults":{"a1":{"path":"/notes","ts":1}}}\n' >"$home/.config/obsidian/obsidian.json"
printf '# kept\n-disable-gpu\n--enable-wayland-ime\n' >"$home/.config/obsidian/user-flags.conf"
HOME="$home" XDG_CONFIG_HOME="" maitri-install-obsidian-cli
jq -e '.cli == true and .vaults.a1.path == "/notes"' "$home/.config/obsidian/obsidian.json" >/dev/null || fail "Obsidian CLI setup keeps the vault list"
pass "Obsidian CLI setup keeps the vault list"
[[ $(cat "$home/.config/obsidian/user-flags.conf") == $'# kept\n--disable-gpu\n--enable-wayland-ime' ]] || fail "Obsidian CLI setup fixes only the -disable-gpu typo"
pass "Obsidian CLI setup fixes only the -disable-gpu typo"

home="$TMPDIR/off"
mkdir -p "$home/.config/obsidian"
printf '{"cli":false}\n' >"$home/.config/obsidian/obsidian.json"
HOME="$home" XDG_CONFIG_HOME="" maitri-install-obsidian-cli
jq -e '.cli == false' "$home/.config/obsidian/obsidian.json" >/dev/null || fail "Obsidian CLI setup leaves a CLI turned off alone"
pass "Obsidian CLI setup leaves a CLI turned off alone"

home="$TMPDIR/linked"
mkdir -p "$home/.config/obsidian" "$TMPDIR/dotfiles"
printf -- '-disable-gpu\n' >"$TMPDIR/dotfiles/user-flags.conf"
printf '{}\n' >"$TMPDIR/dotfiles/obsidian.json"
ln -s "$TMPDIR/dotfiles/user-flags.conf" "$home/.config/obsidian/user-flags.conf"
ln -s "$TMPDIR/dotfiles/obsidian.json" "$home/.config/obsidian/obsidian.json"
HOME="$home" XDG_CONFIG_HOME="" maitri-install-obsidian-cli
[[ -L $home/.config/obsidian/user-flags.conf && -L $home/.config/obsidian/obsidian.json ]] || fail "Obsidian CLI setup keeps symlinked files linked"
grep -qx -- '--disable-gpu' "$TMPDIR/dotfiles/user-flags.conf" && jq -e '.cli == true' "$TMPDIR/dotfiles/obsidian.json" >/dev/null || fail "Obsidian CLI setup writes through symlinks"
pass "Obsidian CLI setup writes through symlinks"
