echo "Replace the Display widget with maitri.display"

config_file="$HOME/.config/maitri/shell.json"
plugins_dir="$HOME/.config/maitri/plugins"

replaced=()
for manifest in "$plugins_dir"/*/manifest.json; do
  [[ -f $manifest ]] || continue
  id=$(jq -r '.id // empty' "$manifest" 2>/dev/null) || continue
  source_id=$(jq -r '.maitri.clonedFrom // empty' "$manifest" 2>/dev/null) || continue
  if [[ $source_id == "maitri.monitor" || $id == "crmne.hyprmoncfg" ]]; then
    [[ -n $id ]] && replaced+=("$id")
  fi
done

if [[ -s $config_file ]]; then
  replaced_json=$(printf '%s\n' "${replaced[@]}" | jq -R 'select(. != "")' | jq -s .)
  tmp=$(mktemp)
  jq --argjson replaced "$replaced_json" '
    def entry_id: if type == "object" then (.id // "") else . end;
    def replaced: entry_id as $id | $id == "maitri.monitor" or ($replaced | index($id)) != null;
    def rename: if type == "object" then .id = "maitri.display" else "maitri.display" end;
    def first_display_only:
      . as $layout
      | reduce ($layout | keys_unsorted[]) as $section ({layout: $layout, seen: false};
          if (.layout[$section] | type) == "array" then
            (reduce .layout[$section][] as $entry ({items: [], seen: .seen};
              if ($entry | entry_id) == "maitri.display" then
                if .seen then . else {items: (.items + [$entry]), seen: true} end
              else .items += [$entry] end)) as $kept
            | .layout[$section] = $kept.items
            | .seen = $kept.seen
          else . end)
      | .layout;

    (if (.bar.layout? | type) == "object" then
      .bar.layout |= (map_values(if type == "array" then map(if replaced then rename else . end) else . end)
        | first_display_only)
    else . end)
    | (if (.disabledPlugins? | type) == "array" then
      .disabledPlugins |= map(select(. != "maitri.monitor"))
    else . end)
  ' "$config_file" >"$tmp" && mv "$tmp" "$config_file" || rm -f "$tmp"
fi

for id in "${replaced[@]}"; do
  echo "maitri.display replaces the $id plugin. Remove it with: maitri plugin remove $id"
done
