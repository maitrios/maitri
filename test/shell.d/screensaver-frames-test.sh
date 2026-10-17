#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/bin" "$tmpdir/home/.config/maitri/branding"
for command in hyprctl pkill stty tty; do
  printf '#!/bin/bash\nexit 0\n' >"$tmpdir/bin/$command"
done
printf '#!/bin/bash\nexit 1\n' >"$tmpdir/bin/pgrep"
cat >"$tmpdir/bin/ttfx" <<'SH'
#!/bin/bash
{ cat "$2"; echo "--"; } >>"$TEST_DIR/shown"
(( $(grep -c '^--$' "$TEST_DIR/shown") < SHOW )) || kill -TERM "$PPID"
SH
chmod +x "$tmpdir/bin/"*

run_screensaver() {
  : >"$tmpdir/shown"
  HOME="$tmpdir/home" PATH="$tmpdir/bin:$PATH" TEST_DIR="$tmpdir" SHOW="$1" \
    timeout 10 bash "$ROOT/bin/maitri-screensaver" >/dev/null 2>&1 </dev/null || true
}

cp "$ROOT/screensaver.txt" "$tmpdir/home/.config/maitri/branding/screensaver.txt"
run_screensaver 3
expected=$(cat "$ROOT/icon.txt"; echo "--"; cat "$ROOT/logo.txt"; echo "--"; cat "$ROOT/icon.txt"; echo "--")
[[ $(cat "$tmpdir/shown") == "$expected" ]] || fail "the screensaver takes turns showing the heart and the wordmark" "$(cat "$tmpdir/shown")"
pass "the screensaver takes turns showing the heart and the wordmark"

printf 'my own words\n' >"$tmpdir/home/.config/maitri/branding/screensaver.txt"
run_screensaver 2
[[ $(cat "$tmpdir/shown") == $'my own words\n--\nmy own words\n--' ]] ||
  fail "a screensaver text without frames shows on every effect" "$(cat "$tmpdir/shown")"
pass "a screensaver text without frames shows on every effect"
