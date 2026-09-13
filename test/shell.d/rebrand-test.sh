#!/bin/bash

source "$(dirname -- "${BASH_SOURCE[0]}")/base-test.sh"

# maitri is a rebranded fork; tools/sync-upstream.sh reapplies the rename on
# every upstream merge. Fail loudly if a merge or a hand edit leaked the
# upstream brand back into a path or an unprotected string.
if output=$("$ROOT/tools/rebrand.sh" --check 2>&1); then
  pass "tree carries no unprotected upstream brand tokens"
else
  fail "tree carries no unprotected upstream brand tokens" "$output"
fi
