#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

migration="$ROOT/migrations/1792255696.sh"
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

stub_bin="$test_dir/bin"
ghostty_bin="$test_dir/ghostty-bin"
mkdir -p "$stub_bin" "$ghostty_bin"

for command in setsid maitri-launch-tui maitri-pkg-add maitri-icons-set update-desktop-database; do
  cat >"$stub_bin/$command" <<'STUB'
#!/bin/bash
printf '%s %s\n' "${0##*/}" "$*" >>"$CALLS"
STUB
done
printf '#!/bin/bash\n' >"$ghostty_bin/ghostty"
chmod +x "$stub_bin"/* "$ghostty_bin/ghostty"

export CALLS="$test_dir/calls"

launch_herdr() {
  : >"$CALLS"
  PATH="$1" "$ROOT/bin/maitri-launch-terminal-herdr"
}

launch_herdr "$stub_bin:$ghostty_bin:$ROOT/bin"
[[ $(<"$CALLS") == "setsid uwsm-app -- ghostty --class=org.maitri.herdr -e herdr" ]] ||
  fail "herdr opens in ghostty with its own class" "$(cat "$CALLS")"
pass "herdr opens in ghostty with its own class"

launch_herdr "$stub_bin:$ROOT/bin"
[[ $(<"$CALLS") == "maitri-launch-tui --app-id=org.maitri.herdr herdr" ]] ||
  fail "without ghostty, herdr opens in the default terminal with its own class" "$(cat "$CALLS")"
pass "without ghostty, herdr opens in the default terminal with its own class"

herdr_entry="$ROOT/default/applications/herdr.desktop"
for line in "Name=herdr" "Exec=maitri-launch-terminal-herdr" "Icon=utilities-terminal" "Terminal=false" \
  "Categories=System;Utility;" "StartupWMClass=org.maitri.herdr"; do
  grep -qxF -- "$line" "$herdr_entry" || fail "herdr.desktop has $line"
done
! grep -q "TerminalEmulator" "$herdr_entry" || fail "xdg-terminal-exec never picks herdr.desktop as a terminal"
[[ ! -e $ROOT/applications/herdr.desktop ]] || fail "herdr.desktop stays out of the unconditional launcher copy"
pass "herdr.desktop carries herdr's class and stays out of the unconditional copy"

ghostty_entry="$ROOT/applications/com.mitchellh.ghostty.desktop"
! grep -q -- "--gtk-single-instance=true" "$ghostty_entry" || fail "ghostty.desktop leaves single-instance mode off"
! grep -q "^DBusActivatable=" "$ghostty_entry" || fail "ghostty.desktop launches through Exec, not D-Bus activation"
for line in "Exec=/usr/bin/ghostty" "X-TerminalArgExec=-e" "X-TerminalArgAppId=--class=" "X-TerminalArgDir=--working-directory="; do
  grep -qxF -- "$line" "$ghostty_entry" || fail "ghostty.desktop has $line"
done
pass "ghostty.desktop keeps every launch in its own instance"

grep -qx "o.window(\"org.maitri.herdr\", { scroll_touchpad = 0.2 })" "$ROOT/default/hypr/apps/herdr.lua" ||
  fail "herdr's window scrolls at ghostty's touchpad speed"
pass "herdr's window scrolls at ghostty's touchpad speed"

maitri_path="$test_dir/maitri"
mkdir -p "$maitri_path/default" "$maitri_path/config"
cp -R "$ROOT/applications" "$maitri_path/"
cp -R "$ROOT/default/applications" "$ROOT/default/alacritty" "$maitri_path/default/"
cp -R "$ROOT/config/ghostty" "$maitri_path/config/"

home="$test_dir/home"
applications="$home/.local/share/applications"

run_migration() {
  : >"$CALLS"
  HOME="$home" MAITRI_PATH="$maitri_path" PATH="$stub_bin:$ROOT/bin:$PATH" bash -euo pipefail "$migration" >/dev/null
}

snapshot() {
  (cd "$home" && find . -type f -print0 | sort -z | xargs -0 sha256sum)
}

printf 'foot.desktop\n' >"$test_dir/terminals.list"
mkdir -p "$home/.config"
cp "$test_dir/terminals.list" "$home/.config/xdg-terminals.list"
run_migration
grep -qxF "maitri-pkg-add ghostty" "$CALLS" || fail "the migration installs ghostty" "$(cat "$CALLS")"
cmp -s "$home/.config/ghostty/config" "$ROOT/config/ghostty/config" || fail "a missing ghostty config is seeded"
cmp -s "$applications/herdr.desktop" "$herdr_entry" || fail "the herdr launcher is installed"
cmp -s "$applications/com.mitchellh.ghostty.desktop" "$ghostty_entry" || fail "the ghostty launcher is installed"
cmp -s "$home/.config/xdg-terminals.list" "$test_dir/terminals.list" || fail "the terminal choice is left alone"
pass "the migration installs ghostty, seeds its config and adds both launchers"

before=$(snapshot)
run_migration
[[ $(snapshot) == "$before" ]] || fail "a second run changes nothing"
pass "a second run changes nothing"

rm -rf "$home"
mkdir -p "$applications" "$home/.config/ghostty"
printf '[Desktop Entry]\nName=my herdr\nExec=my-herdr\n' >"$applications/herdr.desktop"
printf 'font-size = 14\n' >"$home/.config/ghostty/config"
run_migration
[[ $(<"$applications/herdr.desktop") == $'[Desktop Entry]\nName=my herdr\nExec=my-herdr' ]] ||
  fail "the user's own herdr launcher is left alone" "$(cat "$applications/herdr.desktop")"
[[ $(<"$home/.config/ghostty/config") == "font-size = 14" ]] || fail "the user's own ghostty config is left alone"
pass "the user's own herdr launcher and ghostty config are left alone"

rm "$applications/herdr.desktop"
ln -s "$test_dir/missing-herdr.desktop" "$applications/herdr.desktop"
run_migration
[[ -L $applications/herdr.desktop && ! -e $test_dir/missing-herdr.desktop ]] ||
  fail "a linked herdr launcher is left alone, even when its target is missing"
pass "a linked herdr launcher is left alone, even when its target is missing"
