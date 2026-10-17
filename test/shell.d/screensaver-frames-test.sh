#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/bin" "$tmpdir/home/.config/maitri/branding" "$tmpdir/share"
cp "$ROOT/logo.txt" "$ROOT/icon.txt" "$tmpdir/share/"
for command in hyprctl pkill stty tty maitri-launch-screensaver; do
  printf '#!/bin/bash\nexit 0\n' >"$tmpdir/bin/$command"
done
cat >"$tmpdir/bin/pgrep" <<'SH'
#!/bin/bash
seen=$(cat "$TEST_DIR/seen" 2>/dev/null || echo 0)
deadline=$((SECONDS + 5))
while (( $(grep -c '^--$' "$TEST_DIR/shown") <= seen && SECONDS < deadline )); do
  sleep 0.01
done
echo $((seen + 1)) >"$TEST_DIR/seen"
exit 1
SH
cat >"$tmpdir/bin/ttfx" <<'SH'
#!/bin/bash
{ cat "$2"; echo "--"; } >>"$TEST_DIR/shown"
(( $(grep -c '^--$' "$TEST_DIR/shown") < SHOW )) || kill -TERM "$PPID"
SH
chmod +x "$tmpdir/bin/"*

run_screensaver() {
  : >"$tmpdir/shown"
  rm -f "$tmpdir/seen"
  HOME="$tmpdir/home" PATH="$tmpdir/bin:$PATH" TEST_DIR="$tmpdir" SHOW="$1" \
    timeout 10 bash "$ROOT/bin/maitri-screensaver" >/dev/null 2>&1 </dev/null || true
}

HOME="$tmpdir/home" MAITRI_PATH="$tmpdir/share" PATH="$tmpdir/bin:$PATH" \
  bash "$ROOT/bin/maitri-branding-screensaver" reset || fail "reset writes the default screensaver from logo.txt and icon.txt alone"
run_screensaver 3
expected=$(cat "$ROOT/icon.txt"; echo "--"; cat "$ROOT/logo.txt"; echo "--"; cat "$ROOT/icon.txt"; echo "--")
[[ $(cat "$tmpdir/shown") == "$expected" ]] || fail "the screensaver takes turns showing the heart and the wordmark" "$(cat "$tmpdir/shown")"
pass "the screensaver takes turns showing the heart and the wordmark"

printf 'my own words\n' >"$tmpdir/home/.config/maitri/branding/screensaver.txt"
run_screensaver 2
[[ $(cat "$tmpdir/shown") == $'my own words\n--\nmy own words\n--' ]] ||
  fail "a screensaver text without frames shows on every effect" "$(cat "$tmpdir/shown")"
pass "a screensaver text without frames shows on every effect"

printf 'one\n\f\n\f\n  \n\f\ntwo\n\f\n' >"$tmpdir/home/.config/maitri/branding/screensaver.txt"
run_screensaver 3
[[ $(cat "$tmpdir/shown") == $'one\n--\ntwo\n--\none\n--' ]] ||
  fail "empty frames are skipped" "$(cat "$tmpdir/shown")"
pass "empty frames are skipped"
