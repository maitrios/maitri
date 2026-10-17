#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/bin" "$tmpdir/home/.config/maitri/branding" "$tmpdir/share"
cp "$ROOT/logo.txt" "$ROOT/icon.txt" "$tmpdir/share/"
for command in pkill stty maitri-launch-screensaver; do
  printf '#!/bin/bash\nexit 0\n' >"$tmpdir/bin/$command"
done
cat >"$tmpdir/bin/hyprctl" <<'SH'
#!/bin/bash
echo '{"class": "org.maitri.screensaver"}'
SH
cat >"$tmpdir/bin/maitri-notification-send" <<'SH'
#!/bin/bash
echo "$*" >>"$TEST_DIR/notified"
SH
# Starts slowly and flags any effect that begins while another is still
# running, which a pgrep that looks before the child has exec'd would allow.
cat >"$tmpdir/bin/ttfx" <<'SH'
#!/bin/bash
sleep 0.2
[[ ! -e $TEST_DIR/running ]] || echo "overlap" >>"$TEST_DIR/overlap"
touch "$TEST_DIR/running"
sleep 0.1
{ cat "$2"; echo "--"; } >>"$TEST_DIR/shown"
rm -f "$TEST_DIR/running"
(( $(grep -c '^--$' "$TEST_DIR/shown") < SHOW )) || kill -TERM "$PPID"
SH
chmod +x "$tmpdir/bin/"*

run_screensaver() {
  : >"$tmpdir/shown"
  rm -f "$tmpdir/notified" "$tmpdir/overlap" "$tmpdir/running"
  status=0
  HOME="$tmpdir/home" PATH="$tmpdir/bin:$PATH" TEST_DIR="$tmpdir" SHOW="$1" \
    timeout 10 bash "$ROOT/bin/maitri-screensaver" >/dev/null 2>&1 </dev/null || status=$?
}

HOME="$tmpdir/home" MAITRI_PATH="$tmpdir/share" PATH="$tmpdir/bin:$PATH" \
  bash "$ROOT/bin/maitri-branding-screensaver" reset || fail "reset writes the default screensaver from logo.txt and icon.txt alone"
run_screensaver 3
expected=$(cat "$ROOT/icon.txt"; echo "--"; cat "$ROOT/logo.txt"; echo "--"; cat "$ROOT/icon.txt"; echo "--")
[[ $(cat "$tmpdir/shown") == "$expected" ]] || fail "the screensaver takes turns showing the heart and the wordmark" "$(cat "$tmpdir/shown")"
pass "the screensaver takes turns showing the heart and the wordmark"
[[ ! -e $tmpdir/overlap ]] || fail "an effect only starts once the previous one has exited"
pass "an effect only starts once the previous one has exited"

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

printf 'one\r\n\f\r\ntwo\r\n' >"$tmpdir/home/.config/maitri/branding/screensaver.txt"
run_screensaver 3
[[ $(cat "$tmpdir/shown") == $'one\n--\ntwo\n--\none\n--' ]] ||
  fail "a screensaver text saved with CRLF endings still splits into frames" "$(cat "$tmpdir/shown" | od -c)"
pass "a screensaver text saved with CRLF endings still splits into frames"

for content in "" $' \n\f\n\n' missing; do
  rm -f "$tmpdir/home/.config/maitri/branding/screensaver.txt"
  [[ $content == "missing" ]] || printf '%s' "$content" >"$tmpdir/home/.config/maitri/branding/screensaver.txt"
  run_screensaver 1
  (( status == 0 )) || fail "a screensaver with nothing to draw exits (${content@Q})" "exit status $status"
  [[ ! -s $tmpdir/shown ]] || fail "a screensaver with nothing to draw never starts an effect (${content@Q})" "$(cat "$tmpdir/shown")"
  grep -q "nothing to show" "$tmpdir/notified" 2>/dev/null ||
    fail "a screensaver with nothing to draw says so (${content@Q})"
done
pass "a screensaver with nothing to draw exits with a notice instead of respawning the effect"

mkdir -p "$tmpdir/partial"
cp "$ROOT/logo.txt" "$tmpdir/partial/"
printf 'keep me\n' >"$tmpdir/home/.config/maitri/branding/screensaver.txt"
! HOME="$tmpdir/home" MAITRI_PATH="$tmpdir/partial" PATH="$tmpdir/bin:$PATH" \
  bash "$ROOT/bin/maitri-branding-screensaver" reset 2>/dev/null || fail "reset fails when icon.txt is missing"
[[ $(cat "$tmpdir/home/.config/maitri/branding/screensaver.txt") == "keep me" ]] ||
  fail "a failed reset leaves the current screensaver text alone"
[[ ! -e $tmpdir/home/.config/maitri/branding/screensaver.txt.new ]] || fail "a failed reset cleans up after itself"
pass "a failed reset leaves the current screensaver text alone"
