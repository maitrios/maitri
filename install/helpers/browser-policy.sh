# Browser policy directories are enterprise trust roots, so anything maitri
# touches there stays 0755 root:root and is never created for a browser that
# is not installed.

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/as-root.sh"

BROWSER_POLICY_MANAGED_DIRS=(
  /etc/helium/policies/managed
  /etc/chromium/policies/managed
  /etc/opt/chrome/policies/managed
  /etc/opt/edge/policies/managed
  /etc/brave/policies/managed
)

# Ancestors of the managed dirs, shortest first. A writable or attacker-owned
# parent can rename the leaf aside; install -d follows a planted symlink.
BROWSER_POLICY_PARENT_DIRS=(
  /etc/helium
  /etc/helium/policies
  /etc/chromium
  /etc/chromium/policies
  /etc/opt/chrome
  /etc/opt/chrome/policies
  /etc/opt/edge
  /etc/opt/edge/policies
  /etc/brave
  /etc/brave/policies
)

BROWSER_POLICY_FIREFOX_DIRS=(
  /usr/lib/firefox/distribution
  /opt/zen-browser/distribution
)

browser_policy_purge_dir() {
  local dir=$1

  as_root find "$dir" -mindepth 1 -maxdepth 1 ! -user root -exec rm -rf -- {} +
}

browser_policy_parent_hardened() {
  local dir=$1

  [[ -d $dir && ! -L $dir ]] || return 1
  [[ $(stat -c '%a' "$dir") == "755" ]] || return 1
  [[ $(stat -c '%U' "$dir") == "root" ]] || return 1
}

browser_policy_dir_hardened() {
  browser_policy_parent_hardened "$1"
}

browser_policy_parents_hardened() {
  local dir=$1
  local parent

  for parent in "${BROWSER_POLICY_PARENT_DIRS[@]}"; do
    [[ $dir == "$parent"/* ]] || continue
    [[ -e $parent || -L $parent ]] || continue
    browser_policy_parent_hardened "$parent" || return 1
  done
}

browser_policy_setup_parent() {
  local dir=$1

  if [[ -L $dir || ( -e $dir && ! -d $dir ) ]]; then
    as_root rm -rf -- "$dir"
  fi
  as_root install -d -m 0755 -o root -g root "$dir"
}

browser_policy_setup_parents_for() {
  local dir=$1
  local parent

  for parent in "${BROWSER_POLICY_PARENT_DIRS[@]}"; do
    [[ $dir == "$parent"/* ]] || continue
    browser_policy_setup_parent "$parent"
  done
}

# Links reach the browser through maitri-browser.desktop, so the browser never
# sees itself as the default. Hide its check and its button to become one, which
# would rewrite mimeapps.list behind maitri's back.
browser_policy_install_defaults() {
  local policy_dir=$1
  local policies=${2:-$MAITRI_PATH/default/chromium/policies/maitri.json}

  as_root install -m 644 -o root -g root -T "$policies" "$policy_dir/maitri.json"
}

browser_policy_setup_dir() {
  local dir=$1

  browser_policy_setup_parents_for "$dir"
  browser_policy_setup_parent "$dir"
  browser_policy_purge_dir "$dir"
  browser_policy_install_defaults "$dir"
}

browser_policy_firefox_policy_file_ok() {
  local file=$1
  local mode
  local group_write
  local other_write

  [[ -f $file && ! -L $file ]] || return 1
  [[ $(stat -c '%U' "$file") == "root" ]] || return 1
  mode=$(stat -c '%a' "$file")
  group_write=$((8#${mode: -2:1}))
  other_write=$((8#${mode: -1}))
  (( (group_write & 2) == 0 && (other_write & 2) == 0 ))
}

browser_policy_firefox_hardened() {
  local dir=$1

  [[ -d $dir && ! -L $dir ]] || return 1
  [[ $(stat -c '%a' "$dir") == "755" ]] || return 1
  [[ $(stat -c '%U' "$dir") == "root" ]] || return 1
  browser_policy_firefox_policy_file_ok "$dir/policies.json"
}

browser_policy_install_firefox_policies() {
  local distribution_dir=$1
  local policies=${2:-$MAITRI_PATH/default/firefox/policies.json}

  as_root install -m 644 -o root -g root -T "$policies" "$distribution_dir/policies.json"
}

# Add maitri's default-browser setting to an existing policies.json, keeping
# whatever else an administrator put there.
browser_policy_firefox_skip_default_check() {
  local file=$1/policies.json
  local tmp

  browser_policy_firefox_policy_file_ok "$file" || return 0
  [[ $(jq '.policies.DontCheckDefaultBrowser' "$file" 2>/dev/null) == "true" ]] && return 0

  tmp=$(mktemp) || return 1
  if jq '.policies.DontCheckDefaultBrowser = true' "$file" >"$tmp" 2>/dev/null; then
    as_root install -m 644 -o root -g root -T "$tmp" "$file"
  fi
  rm -f "$tmp"
}

browser_policy_setup_firefox_distribution() {
  local distribution_dir=$1
  local policies=${2:-$MAITRI_PATH/default/firefox/policies.json}

  browser_policy_setup_parent "$distribution_dir"
  browser_policy_purge_dir "$distribution_dir"
  browser_policy_install_firefox_policies "$distribution_dir" "$policies"
}
