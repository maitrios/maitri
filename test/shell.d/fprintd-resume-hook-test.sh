#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

hook="$ROOT/default/systemd/system-sleep/fprintd-resume"

# systemd execs the files in system-sleep/ directly, so a hook without the
# executable bit silently never runs. The installers set the mode explicitly,
# but the checkout should not ship a hook that cannot run as-is either.
[[ -x $hook ]] ||
  fail "the resume hook is executable" "mode: $(stat -c '%A' "$hook")"
pass "the resume hook is executable"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mock_bin="$tmpdir/bin"
call_log="$tmpdir/systemctl-calls"
mkdir -p "$mock_bin"

for command in systemctl systemd-run; do
  cat >"$mock_bin/$command" <<SH
#!/bin/bash
printf '%s %s\n' "$command" "\$*" >>"$call_log"
SH
  chmod +x "$mock_bin/$command"
done

expected="systemd-run --quiet --no-block --collect --on-active=3s /usr/bin/systemctl try-restart fprintd.service"

run_hook() {
  : >"$call_log"
  PATH="$mock_bin:$PATH" "$hook" "$@"
}

# Resume ("post") is the only edge that clears a claim wedged across suspend.
# The restart is scheduled, not awaited: user sessions stay frozen until the
# hook returns, and a wedged fprintd can ride out its whole stop timeout. It
# waits for the reader, which re-enumerates on resume, and lands inside the
# lock screen's 5s resume grace (FingerprintModel.RESUME_GRACE_MS).
run_hook post suspend
[[ $(<"$call_log") == "$expected" ]] ||
  fail "resume schedules an fprintd restart once the reader settles" "calls: $(<"$call_log")"
pass "resume schedules an fprintd restart once the reader settles"

grace_ms=$(sed -n 's/^var RESUME_GRACE_MS = \([0-9]*\)$/\1/p' "$ROOT/shell/plugins/lock/FingerprintModel.js")
(( 3000 < grace_ms )) ||
  fail "the restart lands inside the lock screen's resume grace" "grace: ${grace_ms}ms"
pass "the restart lands inside the lock screen's resume grace"

# Every resume path lands on "post" regardless of how the machine slept.
run_hook post hibernate
[[ $(<"$call_log") == "$expected" ]] ||
  fail "resume from hibernate also restarts fprintd" "calls: $(<"$call_log")"
pass "resume from hibernate also restarts fprintd"

# The drop-in installed beside the hook is what keeps a SIGTERM-ignoring
# fprintd from turning that restart into a multi-second dead reader.
dropin="$ROOT/default/systemd/system/fprintd.service.d/10-stop-timeout.conf"
grep -Eq '^TimeoutStopSec=[0-9]+s?$' "$dropin" ||
  fail "the stop-timeout drop-in bounds TimeoutStopSec" "content: $(<"$dropin")"
pass "the stop-timeout drop-in bounds TimeoutStopSec"

# The claim only wedges once the verify dies under suspend, so there is
# nothing to clear before sleep; a restart there would just take the reader
# away from the verify the lock screen still has open. "pre" must do nothing.
run_hook pre suspend
[[ -z $(<"$call_log") ]] ||
  fail "pre-suspend leaves fprintd alone" "calls: $(<"$call_log")"
pass "pre-suspend leaves fprintd alone"
