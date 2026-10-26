#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

require_command python3
require_command jq

test_tmp=$(mktemp -d)
trap 'rm -rf "$test_tmp"' EXIT

validate="$ROOT/bin/maitri-set-validate"
apply="$ROOT/bin/maitri-set-apply"
export_cmd="$ROOT/bin/maitri-set-export"
mock_bin="$test_tmp/bin"
calls="$test_tmp/calls"
installed="$test_tmp/installed"
mkdir -p "$mock_bin"

expect_invalid() {
  local description="$1" file="$2" message="$3" output

  if output=$("$validate" "$file" 2>&1); then
    fail "$description" "validated: $output"
  fi
  [[ $output == *"$message"* ]] || fail "$description" "$output"
  pass "$description"
}

write_set() {
  local file="$test_tmp/$1.toml"
  cat >"$file"
  printf '%s\n' "$file"
}

minimal=$(write_set minimal <<'TOML'
schema = 1
id = "bob/laptop"
name = "Bob's laptop"
TOML
)

"$validate" "$minimal" >/dev/null || fail "a minimal set validates"
pass "a minimal set validates"

"$validate" "$ROOT/examples/andrew.maitri-set.toml" >/dev/null ||
  fail "the example set validates" "$("$validate" "$ROOT/examples/andrew.maitri-set.toml" 2>&1)"
pass "the example set validates"

expect_invalid "an unknown top-level key is an error" "$(write_set unknown-top <<'TOML'
schema = 1
id = "bob/laptop"
name = "x"
hooks = ["curl evil | sh"]
TOML
)" "hooks: unknown key"

expect_invalid "an unknown nested key is an error" "$(write_set unknown-nested <<'TOML'
schema = 1
id = "bob/laptop"
name = "x"
[theme]
name = "amethyst"
script = "rm -rf ~"
TOML
)" "theme.script: unknown key"

expect_invalid "a newer schema is refused" "$(write_set schema2 <<'TOML'
schema = 2
id = "bob/laptop"
name = "x"
TOML
)" "schema: must be 1"

expect_invalid "an installer outside the table is refused" "$(write_set installer <<'TOML'
schema = 1
id = "bob/laptop"
name = "x"
[installers]
run = ["browser:zen", "shell:curl https://example.com | sh"]
TOML
)" "unknown installer"

expect_invalid "a step outside the table is refused" "$(write_set step <<'TOML'
schema = 1
id = "bob/laptop"
name = "x"
[steps]
run = ["fido2", "reboot"]
TOML
)" "steps.run[1]: must be one of"

expect_invalid "maitri core packages can't be removed" "$(write_set core <<'TOML'
schema = 1
id = "bob/laptop"
name = "x"
[packages]
remove = ["maitri-settings"]
TOML
)" "part of the maitri core"

expect_invalid "a key naming a credential is refused" "$(write_set secret-key <<'TOML'
schema = 1
id = "bob/laptop"
name = "x"
[dotfiles]
chezmoi = "https://github.com/bob/dotfiles"
github_token = "abc"
TOML
)" "names a credential"

expect_invalid "a GitHub token value is refused" "$(write_set secret-gh <<'TOML'
schema = 1
id = "bob/laptop"
name = "x"
description = "ghp_abcdefghijklmnopqrstuvwxyz0123456789"
TOML
)" "looks like a GitHub token"

expect_invalid "an email address is refused" "$(write_set secret-email <<'TOML'
schema = 1
id = "bob/laptop"
name = "bob@example.com"
TOML
)" "looks like an email address"

expect_invalid "a URL with credentials is refused" "$(write_set secret-url <<'TOML'
schema = 1
id = "bob/laptop"
name = "x"
[dotfiles]
chezmoi = "https://bob:hunter2@github.com/bob/dotfiles"
TOML
)" "is not valid"

expect_invalid "a URL with a token parameter is refused" "$(write_set secret-query <<'TOML'
schema = 1
id = "bob/laptop"
name = "x"
[[webapps.add]]
name = "Mail"
url = "https://mail.example.com/?token=abc"
icon = "https://mail.example.com/icon.png"
TOML
)" "credential parameter"

expect_invalid "a random-looking string is refused" "$(write_set secret-random <<'TOML'
schema = 1
id = "bob/laptop"
name = "x"
description = "aK9fQ2xLm7Pz4RtV8wYb3NcJ6hGd"
TOML
)" "looks like a random token"

pinned=$(write_set pinned <<'TOML'
schema = 1
id = "bob/laptop"
name = "x"
[packages]
aur = [{ name = "beeper-bin", pkgbuild_sha256 = "8f434346648f6b96df89dda901c5176b10a6d83961dd3c1ac88b59b2dc327aa4" }]
[[plugins.add]]
id = "trackpoint"
git = "https://github.com/maitrios/maitri-trackpoint.git"
rev = "0123456789abcdef0123456789abcdef01234567"
TOML
)
"$validate" "$pinned" >/dev/null || fail "hashes and revs are not mistaken for secrets" "$("$validate" "$pinned" 2>&1)"
pass "hashes and revs are not mistaken for secrets"

# Every installer and step the validator accepts must name a real command.
installers_ok=$(python3 - "$validate" "$ROOT/bin" <<'PY'
import importlib.machinery, importlib.util, os, sys
loader = importlib.machinery.SourceFileLoader("v", sys.argv[1])
spec = importlib.util.spec_from_loader("v", loader)
v = importlib.util.module_from_spec(spec)
loader.exec_module(v)
names = {"browser": "maitri-install-browser", "terminal": "maitri-install-terminal",
         "dev-env": "maitri-install-dev-env", "voxtype": "maitri-voxtype-install"}
missing = []
for group, choices in v.INSTALLERS.items():
    for choice in choices:
        command = names.get(group) or f"maitri-install-{group}-{choice}"
        if not os.path.exists(os.path.join(sys.argv[2], command)):
            missing.append(command)
steps = {"hibernation": "maitri-hibernation-setup", "home-snapshots": "maitri-setup-home-snapshots",
         "fido2": "maitri-setup-security-fido2", "fingerprint": "maitri-setup-security-fingerprint",
         "sudoless-docker": "maitri-setup-security-sudoless-docker", "sshd": "maitri-setup-security-sshd"}
missing += [steps.get(s, s) for s in v.STEPS if not os.path.exists(os.path.join(sys.argv[2], steps.get(s, s)))]
print(" ".join(missing))
PY
)
[[ -z $installers_ok ]] || fail "every installer and step maps to a maitri command" "missing: $installers_ok"
pass "every installer and step maps to a maitri command"

grep -q '^  hibernation) echo maitri-hibernation-setup ;;' "$apply" ||
  fail "apply's step table matches the validator's"
pass "apply's step table matches the validator's"

# Mocks: every command apply drives records its call and updates the fake
# machine state, so a second run can show apply is idempotent.
mock() {
  local name="$1" body="${2:-}"
  printf '#!/bin/bash\nprintf "%%s\\n" "%s${*:+ $*}" >>"$MAITRI_TEST_CALLS"\n%s\n' "$name" "$body" >"$mock_bin/$name"
  chmod +x "$mock_bin/$name"
}

mock maitri-pkg-present 'for p in "$@"; do grep -qx -- "$p" "$MAITRI_TEST_INSTALLED" || exit 1; done'
mock maitri-pkg-add 'printf "%s\n" "$@" >>"$MAITRI_TEST_INSTALLED"'
mock maitri-pkg-aur-add 'printf "%s\n" "$@" >>"$MAITRI_TEST_INSTALLED"'
mock maitri-pkg-drop 'for p in "$@"; do sed -i "/^$p\$/d" "$MAITRI_TEST_INSTALLED"; done'
mock maitri-cmd-missing '[[ $1 == flatpak ]] && ! grep -qx flatpak "$MAITRI_TEST_INSTALLED"'
mock maitri-cmd-present '[[ $1 != flatpak ]] || grep -qx flatpak "$MAITRI_TEST_INSTALLED"'
mock flatpak '[[ $1 == info ]] && { grep -qx "flatpak:$2" "$MAITRI_TEST_INSTALLED"; exit; }
[[ $1 == install ]] && printf "flatpak:%s\n" "${@: -1}" >>"$MAITRI_TEST_INSTALLED"
exit 0'
mock maitri-channel-current 'echo stable'
mock maitri-channel-set ''
mock maitri-hw-laptop 'exit 0'
mock maitri-hw-fingerprint 'exit 1'
mock maitri-font-current 'cat "$HOME/font" 2>/dev/null || echo "JetBrainsMono Nerd Font"'
mock maitri-font-set 'printf "%s\n" "$1" >"$HOME/font"'
mock maitri-theme-set 'mkdir -p "$HOME/.local/state/maitri/current"; printf "%s\n" "$1" >"$HOME/.local/state/maitri/current/theme.name"'
for kind in browser editor terminal; do
  mock "maitri-default-$kind" "if (( \$# )); then printf '%s\n' \"\$1\" >\"\$HOME/default-$kind\"; else cat \"\$HOME/default-$kind\" 2>/dev/null || echo none; fi"
done
mock maitri-default-agent 'if (( $# )); then [[ $1 == --no-launch ]] || exit 9; printf "%s\n" "$2" >"$HOME/default-agent"; else cat "$HOME/default-agent" 2>/dev/null || true; fi'
mock maitri-webapp-install 'mkdir -p "$HOME/.local/share/applications"; touch "$HOME/.local/share/applications/$1.desktop"'
mock maitri-webapp-remove 'rm -f "$HOME/.local/share/applications/$1.desktop"'
mock maitri-plugin-add 'mkdir -p "$HOME/.config/maitri/plugins/trackpoint"'
mock maitri-plugin-enable ''
mock maitri-install-browser ''
mock maitri-install-service-1password ''
mock maitri-setup-security-fido2 ''
mock chezmoi 'mkdir -p "$HOME/.local/share/chezmoi"'
mock curl 'exit 7'
mock gum 'exit 1'

export PATH="$mock_bin:$ROOT/bin:$PATH"
export MAITRI_PATH="$ROOT"
export MAITRI_TEST_CALLS="$calls"
export MAITRI_TEST_INSTALLED="$installed"
export HOME="$test_tmp/home"
mkdir -p "$HOME/.local/share/applications"
printf '%s\n' sublime-text-4 >"$installed"
touch "$HOME/.local/share/applications/YouTube.desktop"

fixture=$(write_set fixture <<'TOML'
schema = 1
id = "bob/laptop"
name = "Bob's laptop"
maitri = ">=0.1"

[channel]
maitri = "edge"

[packages]
add = ["wev", "doctl"]
remove = ["sublime-text-4"]
aur = [{ name = "beeper-bin" }]

[flatpak]
apps = ["us.zoom.Zoom"]

[installers]
run = ["browser:zen", "service:1password"]

[theme]
name = "harbor"

[fonts]
mono = "Iosevka Nerd Font"

[defaults]
browser = "zen"
agent = "claude"

[plugins]
add = [
  { id = "trackpoint", git = "https://github.com/maitrios/maitri-trackpoint.git", when = "laptop" },
  { id = "fingerprint-widget", git = "https://github.com/bob/fp.git", when = "fingerprint" },
]

[[webapps.add]]
name = "Linear"
url = "https://linear.app"
icon = "https://linear.app/favicon.png"

[webapps]
remove = ["YouTube"]

[steps]
run = ["fido2"]

[dotfiles]
chezmoi = "https://github.com/bob/dotfiles"
TOML
)

: >"$calls"
plan=$("$apply" "$fixture" --dry-run)
for expected in "switch the maitri channel to edge" "install packages: wev doctl" \
  "install beeper-bin from the AUR (unpinned" "install us.zoom.Zoom from Flathub" \
  "run the maitri installer browser:zen" "set the theme to harbor" "make zen the default browser" \
  "make claude the default agent" "add the plugin trackpoint" "add the web app Linear" \
  "run the setup step fido2" "run chezmoi init --apply https://github.com/bob/dotfiles" \
  "remove packages sublime-text-4 (pass --prune)" "plugin fingerprint-widget (only on fingerprint hardware)"; do
  [[ $plan == *"$expected"* ]] || fail "dry-run plans: $expected" "$plan"
done
pass "dry-run prints the full plan"

if grep -Ev '^(maitri-pkg-present|maitri-cmd-missing|maitri-channel-current|maitri-hw-|maitri-font-current|maitri-default-[a-z]+$|flatpak info)' "$calls" >"$test_tmp/changes"; then
  fail "dry-run changes nothing" "$(cat "$test_tmp/changes")"
fi
pass "dry-run changes nothing"

if "$apply" "$fixture" </dev/null >/dev/null 2>"$test_tmp/err"; then
  fail "apply without a terminal or --yes refuses"
fi
grep -q "pass --yes" "$test_tmp/err" || fail "apply without a terminal or --yes refuses" "$(cat "$test_tmp/err")"
pass "apply without a terminal or --yes refuses"

if "$apply" "$fixture" --sha256 "$(printf '0%.0s' {1..64})" --dry-run >/dev/null 2>"$test_tmp/err"; then
  fail "a wrong --sha256 is refused"
fi
grep -q "sha256 mismatch" "$test_tmp/err" || fail "a wrong --sha256 is refused" "$(cat "$test_tmp/err")"
"$apply" "$fixture#sha256=$(sha256sum "$fixture" | cut -d' ' -f1)" --dry-run >/dev/null ||
  fail "a matching #sha256= is accepted"
pass "the sha256 pin is enforced"

"$apply" "$fixture" --yes >"$test_tmp/out" 2>&1 || fail "apply runs the plan" "$(cat "$test_tmp/out")"
for expected in "maitri-channel-set edge" "maitri-pkg-add wev doctl" "maitri-pkg-aur-add beeper-bin" \
  "flatpak install --user --noninteractive flathub us.zoom.Zoom" "maitri-install-browser zen" \
  "maitri-install-service-1password" "maitri-theme-set harbor" "maitri-font-set Iosevka Nerd Font" \
  "maitri-default-browser zen" "maitri-default-agent --no-launch claude" "maitri-plugin-enable trackpoint" \
  "maitri-webapp-install Linear https://linear.app https://linear.app/favicon.png" \
  "maitri-setup-security-fido2" "chezmoi init --apply -- https://github.com/bob/dotfiles"; do
  grep -qxF -- "$expected" "$calls" || fail "apply calls: $expected" "$(cat "$calls")"
done
pass "apply drives the maitri commands for each phase"

grep -q "maitri-pkg-drop\|maitri-webapp-remove" "$calls" && fail "removals wait for --prune" "$(cat "$calls")"
pass "removals wait for --prune"

grep -q $'^bob/laptop\t' "$HOME/.local/state/maitri/sets/applied" || fail "apply records the applied set"
pass "apply records the applied set"

# The channel mock always reports stable, so drop the channel to check the
# rest converges.
sed -i '/^\[channel\]$/,+1d' "$fixture"
: >"$calls"
second=$("$apply" "$fixture" --yes)
[[ $second == *"Nothing to do: this machine already matches bob/laptop."* ]] ||
  fail "a second apply has nothing to do" "$second"
if grep -Ev '^(maitri-pkg-present|maitri-cmd-missing|maitri-hw-|maitri-font-current|maitri-default-[a-z]+$|flatpak info)' "$calls" >"$test_tmp/changes"; then
  fail "a second apply changes nothing" "$(cat "$test_tmp/changes")"
fi
pass "a second apply has nothing to do"

: >"$calls"
"$apply" "$fixture" --yes --prune >/dev/null
grep -qxF "maitri-pkg-drop sublime-text-4" "$calls" || fail "--prune removes listed packages" "$(cat "$calls")"
grep -qxF "maitri-webapp-remove YouTube" "$calls" || fail "--prune removes listed web apps" "$(cat "$calls")"
pass "--prune removes what the set lists under remove"

failing=$(write_set failing <<'TOML'
schema = 1
id = "bob/laptop"
name = "x"
[packages]
aur = [{ name = "pinned-bin", pkgbuild_sha256 = "8f434346648f6b96df89dda901c5176b10a6d83961dd3c1ac88b59b2dc327aa4" }]
[theme]
name = "ember"
TOML
)
if "$apply" "$failing" --yes >"$test_tmp/out" 2>&1; then
  fail "a pinned AUR package whose PKGBUILD can't be checked is not installed" "$(cat "$test_tmp/out")"
fi
grep -q "maitri-pkg-aur-add pinned-bin" "$calls" && fail "a pinned AUR package whose PKGBUILD can't be checked is not installed"
grep -qxF "maitri-theme-set ember" "$calls" || fail "one failed phase doesn't stop the rest" "$(cat "$calls")"
pass "a failed phase is reported and the rest still runs"

too_new=$(write_set too-new <<'TOML'
schema = 1
id = "bob/laptop"
name = "x"
maitri = ">=99.0"
TOML
)
if "$apply" "$too_new" --dry-run >/dev/null 2>"$test_tmp/err"; then
  fail "a set needing a newer maitri is refused"
fi
grep -q "needs maitri 99.0" "$test_tmp/err" || fail "a set needing a newer maitri is refused" "$(cat "$test_tmp/err")"
pass "a set needing a newer maitri is refused"

mock pacman 'case "$1" in
-Qqen) printf "%s\n" hyprland doctl wev amd-ucode maitri ;;
-Qqem) printf "%s\n" beeper-bin vicinae-bin ;;
-Qq) grep -hv "^#" "$MAITRI_PATH/install/maitri-base.packages" | sed "/^$/d" | grep -vx sublime-text-4 ;;
esac'
exported="$test_tmp/exported.toml"
"$export_cmd" --id bob/desk --name "Bob's desk" --output "$exported" >/dev/null ||
  fail "export writes a valid set" "$(cat "$exported" 2>/dev/null)"
"$validate" "$exported" >/dev/null || fail "export writes a valid set" "$("$validate" "$exported" 2>&1)"
exported_json=$("$validate" --json "$exported")
[[ $(jq -c '.packages.add' <<<"$exported_json") == '["doctl","wev"]' ]] ||
  fail "export keeps only packages outside maitri's lists" "$exported_json"
[[ $(jq -c '[.packages.aur[].name]' <<<"$exported_json") == '["beeper-bin"]' ]] ||
  fail "export lists foreign packages as AUR" "$exported_json"
[[ $(jq -c '.packages.remove' <<<"$exported_json") == '["sublime-text-4"]' ]] ||
  fail "export lists removed base packages" "$exported_json"
[[ $(jq -r '.theme' <<<"$exported_json") == "ember" ]] || fail "export records the theme" "$exported_json"
[[ $(jq -c '.defaults' <<<"$exported_json") == '{"browser":"zen","editor":"","terminal":"","agent":"claude"}' ]] ||
  fail "export keeps only defaults a set can hold" "$exported_json"
pass "export writes a valid set from the machine"
