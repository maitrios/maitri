#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

# fish is the default login shell on every install path: the ISO chroot
# (apply-system -> install/config), deferred first-boot provisioning
# (provision-owner's useradd), and the seeded per-user config.
grep -q 'config/default-shell.sh' "$ROOT/install/config/all.sh" ||
  fail "system setup sets the default login shell"
pass "system setup sets the default login shell"

grep -q 'usermod -s "\$fish_path" "\$MAITRI_INSTALL_USER"' "$ROOT/install/config/default-shell.sh" ||
  fail "default-shell switches the install user to fish"
pass "default-shell switches the install user to fish"

grep -q 'useradd -m -G "\$(user_groups)" -s /usr/bin/fish' "$ROOT/bin/maitri-provision-owner" ||
  fail "deferred provisioning creates the owner with a fish login shell"
pass "deferred provisioning creates the owner with a fish login shell"

[[ -f $ROOT/config/fish/config.fish ]] || fail "a fish config is seeded through /etc/skel"
pass "a fish config is seeded through /etc/skel"

grep -qxF 'fish' "$ROOT/install/maitri-base.packages" && grep -qxF 'maitri-fish' "$ROOT/install/maitri-base.packages" ||
  fail "fish and maitri-fish are in the base package set"
pass "fish and maitri-fish are in the base package set"

if command -v fish >/dev/null; then
  fish -n "$ROOT/config/fish/config.fish" || fail "the seeded fish config parses"
  pass "the seeded fish config parses"
fi
