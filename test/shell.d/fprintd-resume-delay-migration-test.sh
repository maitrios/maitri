#!/bin/bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/base-test.sh"

migration=$(grep -rl 'Restart fprintd only once the reader is back after resume' "$ROOT/migrations" | head -n 1 || true)
[[ -n $migration ]] || fail "fprintd resume delay migration exists"

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

stub_bin="$TMPDIR/bin"
mkdir -p "$stub_bin"
cat >"$stub_bin/sudo" <<'STUB'
#!/bin/bash
[[ ${REFUSE_SUDO:-0} != 1 ]] || exit 1
exec "$@"
STUB
chmod +x "$stub_bin/sudo"

hook_src="$ROOT/default/systemd/system-sleep/fprintd-resume"
hook_dst="$TMPDIR/system-sleep/fprintd-resume"

# The hook 0.5.0 through 0.5.2 shipped, byte for byte.
write_previous_hook() {
  mkdir -p "${hook_dst%/*}"
  cat >"$hook_dst" <<'HOOK'
#!/bin/bash

# Suspend can wedge fprintd's claim; restart it after resume to clear it.
# Upstream: https://gitlab.freedesktop.org/libfprint/fprintd/-/issues/173

if [[ $1 == "post" ]]; then
  # user.slice stays frozen until this hook returns; enqueue rather than wait.
  systemctl --no-block try-restart fprintd.service 2>/dev/null || true
fi
HOOK
}

run_migration() {
  PATH="$stub_bin:$PATH" \
    MAITRI_FPRINTD_RESUME_SRC="$hook_src" \
    MAITRI_FPRINTD_RESUME_DST="$hook_dst" \
    bash "$migration" >/dev/null
}

write_previous_hook
grep -Fq "previous_hook_sha=$(sha256sum <"$hook_dst" | cut -d' ' -f1)" "$migration" ||
  fail "the migration recognizes the hook 0.5.x shipped"
pass "the migration recognizes the hook 0.5.x shipped"

run_migration || fail "updating the shipped hook succeeds"
cmp -s "$hook_dst" "$hook_src" || fail "the shipped hook is replaced with the delayed restart"
[[ -x $hook_dst ]] || fail "the replaced hook stays executable"
pass "the shipped hook is replaced with the delayed restart"

run_migration || fail "a second run succeeds"
cmp -s "$hook_dst" "$hook_src" || fail "a second run leaves the new hook alone"
pass "a second run leaves the new hook alone"

printf '#!/bin/bash\n# local tweak\n' >"$hook_dst"
run_migration || fail "a customized hook is skipped without error"
grep -Fq 'local tweak' "$hook_dst" || fail "a customized hook is left as it is"
pass "a customized hook is left as it is"

rm -f "$hook_dst"
run_migration || fail "a machine without the hook is skipped without error"
[[ ! -e $hook_dst ]] || fail "a machine without the hook does not get one from this migration"
pass "a machine without the hook does not get one from this migration"

write_previous_hook
if REFUSE_SUDO=1 run_migration; then
  fail "a refused sudo keeps the migration pending"
fi
grep -Fq 'systemctl --no-block try-restart' "$hook_dst" || fail "a refused sudo leaves the old hook in place"
pass "a refused sudo keeps the migration pending"
