#!/bin/bash

set -euo pipefail

source "$(dirname "$0")/base-test.sh"

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

mock_bin="$test_tmp/bin"
mkdir -p "$mock_bin" "$test_tmp/home" "$test_tmp/home/.hermes/profiles/james"

for command in xdg-user-dirs-update xdg-settings xdg-mime; do
  printf '#!/bin/bash\nexit 0\n' >"$mock_bin/$command"
done
chmod +x "$mock_bin"/*

# Isolate both setup leaves and application refresh. Refresh also invokes the
# mise leaf through MAITRI_PATH, independently of MAITRI_INSTALL.
fixture="$test_tmp/maitri"
mkdir -p "$fixture/bin" "$test_tmp/install/user"
cp "$ROOT/bin/maitri-provision-user" "$ROOT/bin/maitri-done" "$fixture/bin/"
ln -s "$ROOT/default" "$fixture/default"
printf '#!/bin/bash\nexit 0\n' >"$fixture/bin/maitri-refresh-applications"
chmod +x "$fixture/bin/maitri-refresh-applications"
: >"$test_tmp/install/user/all.sh"

provision() {
  HOME="$test_tmp/home" PATH="$mock_bin:$fixture/bin:$PATH" MAITRI_PATH="$fixture" \
    MAITRI_INSTALL="$test_tmp/install" bash "$fixture/bin/maitri-provision-user" "$@" >/dev/null ||
    fail "maitri-provision-user finishes"
}
provision

for skill in maitri diagnose-crash; do
  link="$test_tmp/home/.hermes/skills/$skill"
  [[ -L $link && $(readlink "$link") == "$fixture/default/agents/skills/$skill" ]] ||
    fail "maitri-provision-user provisions the $skill skill for Hermes"

  link="$test_tmp/home/.hermes/profiles/james/skills/$skill"
  [[ -L $link && $(readlink "$link") == "$fixture/default/agents/skills/$skill" ]] ||
    fail "maitri-provision-user provisions the $skill skill for a Hermes profile"
done

pass "maitri-provision-user provisions Hermes skills"

provision --force
for skill in maitri diagnose-crash; do
  for directory in .agents/skills .claude/skills .codex/skills .pi/agent/skills .hermes/skills .hermes/profiles/james/skills; do
    link="$test_tmp/home/$directory/$skill"
    [[ -L $link && $(readlink "$link") == "$fixture/default/agents/skills/$skill" ]] ||
      fail "forced provisioning keeps baseline and Hermes skill links idempotent"
  done
done
pass "forced provisioning keeps baseline and Hermes skill links idempotent"

rm -rf "$test_tmp/home"
mkdir -p "$test_tmp/home"
provision
[[ ! -e $test_tmp/home/.hermes/profiles ]] || fail "provisioning does not invent Hermes profiles"
[[ ! -e $test_tmp/home/.gemini ]] || fail "Hermes provisioning does not add unrelated Antigravity setup"
pass "provisioning without existing profiles adds only the Hermes default skill home"
