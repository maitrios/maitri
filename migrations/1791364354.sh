echo "Offer the maitri menu under every Vicinae search"

settings="$HOME/.config/vicinae/settings.json"
[[ -f $settings ]] || exit 0

# Vicinae writes its settings under a header of // comment lines. Keep that
# header and edit the JSON below it.
body_line=$(awk '!/^[[:space:]]*(\/\/.*)?$/ { print NR; exit }' "$settings")
[[ -n $body_line ]] || exit 0
body=$(tail -n "+$body_line" "$settings")

if ! jq -e 'type == "object"' <<<"$body" >/dev/null 2>&1; then
  echo "Skipping: $settings isn't plain JSON below its header. Add \"@maitrios/maitri:maitri-menu\" to its fallbacks to search the maitri menu from Vicinae."
  exit 0
fi
jq -e 'has("fallbacks")' <<<"$body" >/dev/null && exit 0

tmp=$(mktemp "$settings.XXXXXX")
if { head -n "$((body_line - 1))" "$settings"; jq '.fallbacks = ["@maitrios/maitri:maitri-menu", "files:search"]' <<<"$body"; } >"$tmp"; then
  chmod --reference="$settings" "$tmp"
  mv "$tmp" "$settings"
else
  rm -f "$tmp"
fi
