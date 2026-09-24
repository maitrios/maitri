#!/bin/bash

# Pull an Omarchy release into maitri. Upstream tags are never merged into
# main directly: every upstream line that says "omarchy" would conflict with
# the rename. Instead the `upstream` branch tracks a *rebranded* copy of each
# tag, so main only sees real feature-vs-upstream overlaps.
#
#   tools/sync-upstream.sh v4.1.0
#
# Afterwards resolve conflicts on main, run tools/rebrand.sh --check,
# ./test/cli and ./test/shell, then commit the merge.

set -euo pipefail

tag=${1:?usage: tools/sync-upstream.sh <omarchy tag>}
ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT"

git remote get-url omarchy >/dev/null 2>&1 || git remote add omarchy https://github.com/basecamp/omarchy.git
git fetch omarchy --tags
git rev-parse --verify -q "refs/tags/$tag" >/dev/null || { echo "unknown tag $tag" >&2; exit 1; }

[[ -z $(git status --porcelain) ]] || { echo "working tree not clean" >&2; exit 1; }

# maitri's own tooling exists on our branches but not in any upstream tag, so
# the read-tree below removes it, including this script and the rebrander it
# then runs. Restore those files from the branch being synced before rebranding.
MAITRI_TOOLING=(tools/rebrand.sh tools/sync-upstream.sh test/shell.d/rebrand-test.sh)

start=$(git branch --show-current)
git checkout upstream
git merge --no-commit -s ours "$tag" >/dev/null
git read-tree -u --reset "$tag"
git checkout "$start" -- "${MAITRI_TOOLING[@]}"
tools/rebrand.sh --all
git add -A
git commit -q -m "Merge omarchy $tag (rebranded)"
echo "upstream: $(git rev-parse --short HEAD) = omarchy $tag, rebranded"

git checkout "$start"
if git merge upstream; then
  tools/rebrand.sh --check
  echo "sync: merged cleanly; run ./test/cli and ./test/shell"
else
  echo "sync: resolve conflicts, then: tools/rebrand.sh --paths <files>; tools/rebrand.sh --check; git commit" >&2
  exit 1
fi
