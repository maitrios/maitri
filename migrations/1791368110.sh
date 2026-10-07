echo "Install Mail, put it on the bar and bring an omamail setup across"

maitri-pkg-add maitri-mail

shell_json="$HOME/.config/maitri/shell.json"
omamail_plugin="$HOME/.config/maitri/plugins/omamail"

# Write through a symlink, so a shell.json a dotfile manager links in stays linked.
if [[ -L $shell_json ]]; then
  shell_json=$(readlink -f "$shell_json")
fi

JQ_DEFS='
  def entry_id: if type == "object" then (.id // "" | tostring) else tostring end;
  def bar_ids: [.bar.layout? | objects | .[] | arrays | .[] | entry_id];
'

shell_json_editable() {
  [[ -f $shell_json ]] && jq -e 'type == "object"' "$shell_json" >/dev/null 2>&1
}

edit_shell_json() {
  local tmp
  tmp=$(mktemp "$shell_json.XXXXXX")
  if ! jq "$JQ_DEFS$1" "$shell_json" >"$tmp" || ! jq -e 'type == "object"' "$tmp" >/dev/null; then
    rm -f "$tmp"
    return 1
  fi
  if jq -e --slurpfile edited "$tmp" '. == $edited[0]' "$shell_json" >/dev/null; then
    rm -f "$tmp"
    return 0
  fi
  chmod --reference="$shell_json" "$tmp"
  mv "$tmp" "$shell_json"
}

# omamail's bar entry becomes Mail's, keeping its settings. Where the bar already
# carries Mail, the omamail entry folds into it: Mail keeps its own settings and
# gains the ones it lacks.
adopt_omamail_settings() {
  shell_json_editable || return 0
  edit_shell_json '
    def own_settings: if type == "object" then del(.id) else {} end;
    def adopt($scope):
      ($scope | map(select(entry_id == "omamail") | own_settings) | add // {}) as $carried
      | if ($scope | any(.[]; entry_id == "maitri.mail")) then
          map(select(entry_id != "omamail")
            | if entry_id == "maitri.mail" then {id: "maitri.mail"} + $carried + own_settings else . end)
        else
          map(if entry_id == "omamail" then (if type == "object" then .id = "maitri.mail" else "maitri.mail" end) else . end)
        end;

    if (.bar | type) == "object" and (.bar.layout | type) == "object" then
      [.bar.layout[] | arrays | .[]] as $bar
      | if any($bar[]; entry_id == "omamail") then
          .bar.layout |= map_values(if type == "array" then adopt($bar) else . end)
        else . end
      | if .bar.centerAnchor == "omamail" then .bar.centerAnchor = "maitri.mail" else . end
    else . end
    | if (.plugins | type) == "array" and any(.plugins[]; entry_id == "omamail") then
        .plugins |= adopt(.)
      else . end
    | if (.disabledPlugins | type) == "array" and any(.disabledPlugins[]; . == "omamail") then
        .disabledPlugins |= (map(if . == "omamail" then "maitri.mail" else . end)
          | reduce .[] as $id ([]; if any(.[]; . == $id) then . else . + [$id] end))
      else . end
  '
  maitri-shell -q shell reloadConfig
}

# Without its bar entry the running shell stops omamail, though not instantly.
# Its backend writes to the directories moved next, so wait for it, and leave the
# migration pending when it will not stop.
wait_for_omamail_to_stop() {
  local attempt
  for (( attempt = 0; attempt < ${MAITRI_OMAMAIL_STOP_ATTEMPTS:-100}; attempt++ )); do
    pgrep -u "$UID" -x omamail >/dev/null || return 0
    sleep 0.1
  done
  echo "omamail is still running. Quit it with 'pkill -x omamail', then run maitri-migrate again." >&2
  return 1
}

move_omamail_data() {
  local base
  for base in "${XDG_CONFIG_HOME:-$HOME/.config}" "${XDG_CACHE_HOME:-$HOME/.cache}" "${XDG_STATE_HOME:-$HOME/.local/state}"; do
    [[ -e $base/omamail || -L $base/omamail ]] || continue
    if [[ -e $base/maitri-mail || -L $base/maitri-mail ]]; then
      echo "Leaving $base/omamail where it is: $base/maitri-mail already exists."
      continue
    fi
    mv -T "$base/omamail" "$base/maitri-mail"
  done
}

# Mail's own managed block, exactly as maitri-mail's scripts/default-mail.sh
# writes it, so Mail keeps recognizing it as its own and can remove it again.
mapfile -t mail_bindings_block <<'LUA'
-- >>> maitri-mail default mail client, do not edit by hand
hl.unbind("SUPER + SHIFT + E")
hl.unbind("SUPER + SHIFT + ALT + E")
o.bind("SUPER + SHIFT + E", "Email", "maitri-shell shell summon maitri.mail '{}'")
o.bind("SUPER + SHIFT + ALT + E", "New email", "maitri-shell shell summon maitri.mail '{\"compose\":true}'")
-- <<< maitri-mail default mail client
LUA

# omamail's "Set as default" wrote a managed block that summons omamail. It
# becomes Mail's block, between its markers only. A line in it that Mail would
# not write once renamed means someone edited the block, so it is left alone.
rewrite_omamail_bindings() {
  local file="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/bindings.lua"
  local old_begin="-- >>> omamail default mail client, do not edit by hand"
  local old_end="-- <<< omamail default mail client"
  local summon_mail="maitri-shell shell summon maitri.mail "
  local line renamed body known in_block=0 out="" tmp

  if [[ -L $file ]]; then
    file=$(readlink -f "$file")
  fi
  [[ -f $file ]] && grep -qxF -- "$old_begin" "$file" || return 0

  local leave="Leaving the omamail keybindings in $file alone"
  local redo="Delete that block, then choose Settings > Default mail client > Set as default in Mail to bind SUPER+SHIFT+E to it."
  if grep -qxF -- "${mail_bindings_block[0]}" "$file"; then
    echo "$leave: Mail's own block is there as well. $redo"
    return 0
  fi

  while IFS= read -r line || [[ -n $line ]]; do
    if (( in_block )) && [[ $line == "$old_end" ]]; then
      out+=${mail_bindings_block[-1]}$'\n'
      in_block=0
    elif (( in_block )); then
      renamed=${line/omarchy-shell shell summon omamail /$summon_mail}  # rebrand:keep
      renamed=${renamed/maitri-shell shell summon omamail /$summon_mail}
      known=0
      for body in "${mail_bindings_block[@]:1:${#mail_bindings_block[@]}-2}"; do
        if [[ $renamed == "$body" ]]; then
          known=1
        fi
      done
      if (( ! known )); then
        echo "$leave: the block has been edited. $redo"
        return 0
      fi
      out+=$renamed$'\n'
    elif [[ $line == "$old_begin" ]]; then
      out+=${mail_bindings_block[0]}$'\n'
      in_block=1
    elif [[ $line == "$old_end" ]]; then
      echo "$leave: the block has been edited. $redo"
      return 0
    else
      out+=$line$'\n'
    fi
  done <"$file"
  if (( in_block )); then
    echo "$leave: the block has been edited. $redo"
    return 0
  fi
  if [[ $(tail -c1 "$file") ]]; then
    out=${out%$'\n'}
  fi

  tmp=$(mktemp "$file.XXXXXX")
  printf '%s' "$out" >"$tmp"
  chmod --reference="$file" "$tmp"
  mv "$tmp" "$file"
  # Nothing else here reloads Hyprland, and the update does not either.
  echo "SUPER+SHIFT+E and SUPER+SHIFT+ALT+E in $file now open Mail. Hyprland picks them up at your next login."
}

# Not `maitri-plugin-remove omamail`: it deletes a git checkout outright, and it
# switches the plugin off through the running shell, which writes back the
# shell.json it holds in memory. That copy can predate the rename above, and
# writing it would drop Mail's entry and settings again.
retire_omamail_plugin() {
  [[ -e $omamail_plugin || -L $omamail_plugin ]] || return 0
  local backup
  backup="$HOME/.local/state/maitri/backups/omamail-plugin-$(date -u +%Y%m%d%H%M%S)"
  mkdir -p "${backup%/*}"
  mv -T "$omamail_plugin" "$backup"
  echo "Moved the omamail plugin to $backup"
}

# Runs for everyone, so a retry still finishes it after the steps that mark an
# omamail setup have already run.
retire_omamail_launcher() {
  rm -f "${XDG_DATA_HOME:-$HOME/.local/share}/applications/omamail.desktop"
  if [[ $(xdg-mime query default x-scheme-handler/mailto 2>/dev/null) == "omamail.desktop" ]]; then
    xdg-mime default maitri-mail.desktop x-scheme-handler/mailto
  fi
}

put_mail_on_bar() {
  shell_json_editable || return 0
  edit_shell_json '
    if any(bar_ids[]; . == "maitri.mail") then .
    elif (.bar | type) == "object" and (.bar.layout | type) == "object" and (.bar.layout.center | type) == "array" then
      .bar.layout.center += [{id: "maitri.mail"}]
    else . end
  '
  if ! jq -e "$JQ_DEFS"'any(bar_ids[]; . == "maitri.mail")' "$shell_json" >/dev/null; then
    echo "Mail isn't on the bar: $shell_json has no bar.layout.center. Add it with: maitri bar put maitri.mail --section center"
  fi
}

omamail_setup=0
if [[ -e $omamail_plugin || -L $omamail_plugin ]]; then
  omamail_setup=1
elif shell_json_editable && jq -e "$JQ_DEFS"'any(bar_ids[]; . == "omamail")' "$shell_json" >/dev/null; then
  omamail_setup=1
fi

if [[ -f $shell_json ]] && ! shell_json_editable; then
  if (( omamail_setup )); then
    echo "Skipping the bar: $shell_json isn't plain JSON. Rename its \"omamail\" entry to \"maitri.mail\" to keep Mail on the bar with its settings."
  else
    echo "Skipping the bar: $shell_json isn't plain JSON. Add {\"id\": \"maitri.mail\"} to bar.layout.center to put Mail on the bar."
  fi
fi

# The bar entry goes first so the running shell stops omamail, and the data moves
# before the plugin directory: the shell rescans when that directory changes, and
# a rescan can start Mail, which would create empty data directories in the way.
# The plugin directory goes last because, once the bar entry is renamed, it is
# what marks an omamail setup for a retry after a failed run.
if (( omamail_setup )); then
  adopt_omamail_settings
  wait_for_omamail_to_stop
  move_omamail_data
  rewrite_omamail_bindings
  retire_omamail_plugin
fi

retire_omamail_launcher

# Without a shell.json the shell runs the defaults, which carry Mail already.
put_mail_on_bar
