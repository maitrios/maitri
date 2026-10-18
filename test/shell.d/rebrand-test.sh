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

# The path check must see a branded path even when the file list is far larger
# than a pipe buffer; grep -q under pipefail used to turn an early match into a pass.
scratch=$(mktemp -d)
mkdir -p "$scratch/tools"
cp "$ROOT/tools/rebrand.sh" "$scratch/tools/"
git -C "$scratch" init -q
brand="omar""chy"
mkdir -p "$scratch/a"
touch "$scratch/a/0-$brand.txt"
for i in $(seq 1 3000); do touch "$scratch/a/padding-file-with-a-long-name-to-fill-the-pipe-buffer-$i.txt"; done
git -C "$scratch" add -A
if "$scratch/tools/rebrand.sh" --check >/dev/null 2>&1; then
  fail "a branded path is caught in a file list larger than a pipe buffer"
else
  pass "a branded path is caught in a file list larger than a pipe buffer"
fi
rm -rf "$scratch"
