echo "Stop world-writable Chromium and Firefox policy directories"

source "$MAITRI_PATH/install/helpers/browser-policy.sh"

for dir in "${BROWSER_POLICY_MANAGED_DIRS[@]}"; do
  [[ -d $dir || -L $dir ]] || continue
  browser_policy_setup_dir "$dir"
done

for dir in "${BROWSER_POLICY_FIREFOX_DIRS[@]}"; do
  [[ -d $dir || -L $dir ]] || continue
  if browser_policy_firefox_hardened "$dir"; then
    browser_policy_purge_dir "$dir"
    continue
  fi
  browser_policy_setup_parent "$dir"
  browser_policy_purge_dir "$dir"
  if ! browser_policy_firefox_policy_file_ok "$dir/policies.json"; then
    browser_policy_install_firefox_policies "$dir"
  fi
done
