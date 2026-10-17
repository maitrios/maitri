#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

require_command git

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com

origin="$test_tmp/origin"
git init -q -b main "$origin"
git -C "$origin" commit -q --allow-empty -m one
git -C "$origin" tag -a v1.0.0 -m "v1.0.0"
git -C "$origin" tag v1.0.1
git -C "$origin" tag v1.0
git -C "$origin" switch -q -c side
git -C "$origin" commit -q --allow-empty -m unreviewed
git -C "$origin" tag -a v9.9.9 -m "v9.9.9"
git -C "$origin" switch -q main
git -C "$origin" commit -q --allow-empty -m two
git -C "$origin" tag -a v1.1.0-rc.1 -m "v1.1.0-rc.1"

checkout="$test_tmp/checkout"
git clone -q --no-tags "$origin" "$checkout"

check_tag() {
  (cd "$checkout" && "$ROOT/tools/wallpapers-check-tag.sh" "$@") >"$test_tmp/out" 2>"$test_tmp/err"
}

check_tag v1.0.0 || fail "an annotated release tag on main passes" "$(cat "$test_tmp/err")"
check_tag v1.0.1 || fail "a lightweight release tag on main passes" "$(cat "$test_tmp/err")"
check_tag v1.1.0-rc.1 || fail "a prerelease tag on main passes" "$(cat "$test_tmp/err")"
pass "release tags on main pass, annotated or not"

if check_tag v9.9.9; then
  fail "a tag on a commit that is not on main is refused"
fi
grep -q "v9.9.9 is not on main" "$test_tmp/err" || fail "the refusal names the tag" "$(cat "$test_tmp/err")"
pass "a tag on a commit that is not on main is refused"

git -C "$checkout" tag -f v9.9.9 HEAD >/dev/null
git -C "$origin" tag -f -a v1.0.0 side -m moved >/dev/null
if check_tag v1.0.0; then
  fail "a release tag moved off main is refused"
fi
if check_tag v9.9.9; then
  fail "a local tag never stands in for the tag on origin"
fi
pass "the tag is read from origin, so a moved or local tag doesn't pass"

for tag in v1.0 v2evil 'v1.2.3+build' 'v1.2.3;id' "../main" ""; do
  if check_tag "$tag"; then
    fail "the malformed tag '$tag' is refused"
  fi
done
if check_tag v3.0.0; then
  fail "a tag that does not exist is refused"
fi
grep -q "v3.0.0 does not exist" "$test_tmp/err" || fail "a missing tag is reported" "$(cat "$test_tmp/err")"
pass "malformed and missing tags are refused"

workflow="$ROOT/.github/workflows/wallpapers.yml"
[[ $(sed -n '/^on:/,/^[a-z]/p' "$workflow" | grep -cE '^  [a-z_]+:') == 1 ]] &&
  grep -qE '^  workflow_dispatch:' "$workflow" ||
  fail "wallpapers.yml only runs on workflow_dispatch"
grep -qx "    if: github.ref == 'refs/heads/main'" "$workflow" ||
  fail "the publish job only runs on main"
guard=$(grep -n 'tools/wallpapers-check-tag.sh "$TAG"' "$workflow" | cut -d: -f1)
first_secret=$(grep -n 'secrets\.' "$workflow" | head -n 1 | cut -d: -f1)
[[ -n $guard && -n $first_secret ]] && (( guard < first_secret )) ||
  fail "the tag is checked before any step that sees a secret"
! grep -q 'ref: \${{' "$workflow" || fail "the workflow never checks out the tag's tree"
pass "wallpapers.yml runs only from main, and checks the tag before the secrets"
