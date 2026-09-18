echo "Stop forcing the theme color onto every browser profile"

source "$MAITRI_PATH/install/helpers/browser-policy.sh"

# The mandatory BrowserThemeColor policy painted every Helium and Chromium
# profile the same, hiding per-profile colors. Only the file maitri wrote goes;
# the policy directories stay hardened for anything else that lands there.
for dir in "${BROWSER_POLICY_MANAGED_DIRS[@]}"; do
  [[ -e $dir/color.json || -L $dir/color.json ]] || continue
  as_root rm -f -- "$dir/color.json"
done
