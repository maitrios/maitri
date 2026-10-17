#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT

mkdir -p "$test_dir/bin"
printf '#!/bin/bash\necho refresh >>"$HOME/calls"\n' >"$test_dir/bin/maitri-theme-refresh"
chmod +x "$test_dir/bin/maitri-theme-refresh"

run_migration() {
  local home="$1"

  env -u XDG_CONFIG_HOME HOME="$home" PATH="$test_dir/bin:$PATH" bash -euo pipefail "$ROOT/migrations/1792243672.sh" >/dev/null 2>"$home/stderr"
}

new_home() {
  local home="$test_dir/$1"

  mkdir -p "$home/.config/fish" "$home/.local/state/maitri/current"
  echo amethyst >"$home/.local/state/maitri/current/theme.name"
  printf '%s' "$home"
}

block() {
  printf 'if status is-interactive\n    # maitri "%s" syntax colors\n' "$1"
  printf '    set -g fish_color_%s\n' "${@:2}"
  printf 'end\n'
}

spark=(command 82AAFF param E6E9F0 quote 7DE38B redirection C99BFF error FF6E6E autosuggestion 7E879B comment 7E879B)
amethyst_old=(command B08CFF param E6E9F0 quote 7DE38B redirection C99BFF error FF6E6E autosuggestion 8C7EA6 comment 8C7EA6)
amethyst=(command B08CFF param E6E9F0 quote 85DC8C redirection B08CFF error FD8993 autosuggestion 8C7EA6 comment 8C7EA6)

pairs() {
  local out=() i
  for ((i = 0; i < $#; i += 2)); do
    out+=("${*:i+1:1} ${*:i+2:1}")
  done
  printf '%s\n' "${out[@]}"
}

for name in spark amethyst_old amethyst; do
  declare -n colours=$name
  label=Amethyst
  [[ $name == "spark" ]] && label=Spark
  home=$(new_home "$name")
  mapfile -t lines < <(pairs "${colours[@]}")
  { echo "# my config"; block "$label" "${lines[@]}"; echo "set -gx MINE 1"; } >"$home/.config/fish/config.fish"
  run_migration "$home" || fail "the migration runs on the stock $name block"
  [[ $(<"$home/.config/fish/config.fish") == $'# my config\nset -gx MINE 1' ]] || fail "the stock $name block comes out" "$(cat "$home/.config/fish/config.fish")"
  grep -q '^refresh$' "$home/calls" || fail "the migration refreshes the theme after removing the $name block"
  grep -q "keep their old colours until they're restarted" "$home/stderr" || fail "the migration says open fish shells keep their colours" "$(cat "$home/stderr")"
  unset -n colours
done
pass "every stock colour block config.fish shipped comes out, with a note about open shells"

home=$(new_home edited)
mapfile -t lines < <(pairs "${amethyst[@]}")
lines[0]="command 123456"
block Amethyst "${lines[@]}" >"$home/.config/fish/config.fish"
cp "$home/.config/fish/config.fish" "$home/before"
run_migration "$home" || fail "the migration runs on an edited block"
cmp -s "$home/.config/fish/config.fish" "$home/before" || fail "a block with a colour the user changed stays" "$(cat "$home/.config/fish/config.fish")"
[[ ! -s $home/stderr ]] || fail "the migration says nothing when it removes nothing" "$(cat "$home/stderr")"

home=$(new_home extended)
mapfile -t lines < <(pairs "${amethyst[@]}" host E6E9F0)
block Amethyst "${lines[@]}" >"$home/.config/fish/config.fish"
cp "$home/.config/fish/config.fish" "$home/before"
run_migration "$home" || fail "the migration runs on an extended block"
cmp -s "$home/.config/fish/config.fish" "$home/before" || fail "a block with a line the user added stays" "$(cat "$home/.config/fish/config.fish")"

home=$(new_home missing)
run_migration "$home" || fail "the migration runs without a config.fish"
[[ ! -e $home/.config/fish/config.fish ]] || fail "the migration creates no config.fish"
pass "a colour block the user changed or extended stays as it is"
