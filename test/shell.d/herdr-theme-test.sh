#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

require_command jq

test_tmp=$(mktemp -d)
trap 'rm -rf -- "$test_tmp"' EXIT

home="$test_tmp/home"
theme_dir="$home/.local/state/maitri/current/theme"
config="$home/.config/herdr/config.toml"
fake_bin="$test_tmp/bin"
herdr_log="$test_tmp/herdr.log"
mkdir -p "$theme_dir" "${config%/*}" "$fake_bin"

cat >"$fake_bin/herdr" <<'SH'
#!/bin/bash
printf '%s\n' "$*" >>"$HERDR_LOG"
case "$*" in
  "status server --json") printf '{"running":true}\n' ;;
  "server reload-config") printf '{"result":{"status":"ok"}}\n' ;;
esac
SH
chmod +x "$fake_bin/herdr"

render_theme() {
  local colors="$1"
  local next="$home/.local/state/maitri/current/next-theme"

  rm -rf "$next"
  mkdir -p "$next"
  cp "$colors" "$next/colors.toml"
  HOME="$home" MAITRI_PATH="$ROOT" PATH="$ROOT/bin:$PATH" "$ROOT/bin/maitri-theme-set-templates"
  cp "$next/herdr.toml" "$theme_dir/herdr.toml"
}

set_herdr_theme() {
  : >"$herdr_log"
  HOME="$home" HERDR_LOG="$herdr_log" PATH="${1:-$fake_bin:$ROOT/bin:$PATH}" "$ROOT/bin/maitri-theme-set-herdr"
}

non_theme_tables() {
  awk '
    /^[[:space:]]*\[/ { in_theme = ($0 ~ /^[[:space:]]*\[[[:space:]]*theme[[:space:]]*(\.[^]]*)?\]/) }
    !in_theme { print }
  ' "$1"
}

for colors in "$ROOT"/themes/*/colors.toml; do
  render_theme "$colors"
  name=$(basename "${colors%/colors.toml}")

  ! grep -q '{{' "$theme_dir/herdr.toml" ||
    fail "every herdr template placeholder resolves for $name" "$(cat "$theme_dir/herdr.toml")"

  bad=$(grep -E '^[a-z_]+ = "' "$theme_dir/herdr.toml" | grep -vE '^name = "terminal"$|= "#[0-9A-Fa-f]{6}"$' || true)
  [[ -z $bad ]] || fail "every herdr color for $name is a hex color" "$bad"
done
pass "the herdr template renders a full palette for every shipped theme"

render_theme "$ROOT/themes/amethyst/colors.toml"
accent=$(maitri-theme-color --file "$ROOT/themes/amethyst/colors.toml" accent)

cp "$ROOT/config/herdr/config.toml" "$config"
original="$test_tmp/original.toml"
cp "$config" "$original"

set_herdr_theme || fail "maitri-theme-set-herdr applies a theme to the shipped config"

(( $(grep -c '^\[theme\]$' "$config") == 1 )) || fail "the shipped config keeps a single [theme] table"
(( $(grep -c '^\[theme.custom\]$' "$config") == 1 )) || fail "the shipped config keeps a single [theme.custom] table"
grep -qix "accent = \"$accent\"" "$config" || fail "the theme accent reaches the herdr config"
! grep -q 'panel_bg = "black"' "$config" || fail "the old theme colors are replaced"
! grep -q 'tmux ran on the terminal' "$config" || fail "comments inside the old theme tables go with them"
diff <(non_theme_tables "$original") <(non_theme_tables "$config") >/dev/null ||
  fail "every other table and comment in the shipped config is untouched" "$(diff <(non_theme_tables "$original") <(non_theme_tables "$config"))"
grep -qx 'server reload-config' "$herdr_log" || fail "herdr reloads its config after a theme change"
pass "an existing theme section is replaced in place"

cp "$config" "$test_tmp/themed.toml"
set_herdr_theme || fail "maitri-theme-set-herdr runs again on an already themed config"
cmp -s "$config" "$test_tmp/themed.toml" || fail "applying the same theme twice changes nothing"
! grep -qx 'server reload-config' "$herdr_log" || fail "an unchanged config does not reload herdr"
pass "applying the same theme again leaves the config alone"

cat >"$config" <<'TOML'
# my herdr config

[terminal]
new_cwd = "follow"

[keys]
prefix = "ctrl+a"
TOML
cp "$config" "$original"

set_herdr_theme || fail "maitri-theme-set-herdr applies a theme to a config without one"

head -n "$(wc -l <"$original")" "$config" | cmp -s - "$original" ||
  fail "a config without a theme keeps its content ahead of the appended theme" "$(cat "$config")"
(( $(grep -c '^\[theme\]$' "$config") == 1 )) || fail "a theme section is appended"
grep -qix "accent = \"$accent\"" "$config" || fail "the appended theme carries the theme colors"
diff <(non_theme_tables "$original") <(non_theme_tables "$config" | sed '$ { /^$/d }') >/dev/null ||
  fail "appending the theme leaves the other tables untouched" "$(cat "$config")"
pass "a config without a theme section gets one appended"

cat >"$config" <<'TOML'
[theme]
name = "catppuccin"
auto_switch = true

[ui]
accent = "blue"

[theme.custom.light]
panel_bg = "#ffffff"

# the keys I actually use
[keys]
prefix = "ctrl+a"
TOML

set_herdr_theme || fail "maitri-theme-set-herdr applies a theme over scattered theme tables"

! grep -q 'catppuccin' "$config" || fail "the old theme name is gone"
! grep -q 'theme.custom.light' "$config" || fail "a theme subtable further down is removed"
grep -qx '# the keys I actually use' "$config" || fail "a comment that leads into the next table is kept"
grep -qx 'accent = "blue"' "$config" || fail "the [ui] table is untouched"
[[ $(head -n 1 "$config") == "[theme]" ]] || fail "the new theme takes the place of the first theme table"
pass "every theme table is replaced while the tables between them stay"

cp "$config" "$original"
printf '[keys]\nprefix = "ctrl+b"\n' >"$theme_dir/herdr.toml"
set_herdr_theme || fail "maitri-theme-set-herdr tolerates a herdr.toml without theme tables"
cmp -s "$config" "$original" || fail "a herdr.toml without theme tables leaves the config alone"
pass "only theme tables are taken from the rendered herdr.toml"

render_theme "$ROOT/themes/amethyst/colors.toml"
no_herdr_bin="$test_tmp/no-herdr-bin"
mkdir -p "$no_herdr_bin"
for tool in bash awk cat cmp mktemp rm; do
  ln -s "$(command -v "$tool")" "$no_herdr_bin/$tool"
done

set_herdr_theme "$no_herdr_bin:$ROOT/bin" || fail "maitri-theme-set-herdr exits cleanly without herdr"
cmp -s "$config" "$original" || fail "a missing herdr leaves the config alone"
[[ ! -s $herdr_log ]] || fail "a missing herdr is never called"
pass "a missing herdr is a no-op"

rm "$config"
set_herdr_theme || fail "maitri-theme-set-herdr exits cleanly without a herdr config"
[[ ! -e $config ]] || fail "maitri-theme-set-herdr does not create a herdr config"
[[ ! -s $herdr_log ]] || fail "herdr is not reloaded without a config"
pass "a missing herdr config is a no-op"
