echo "Retire maitri's monitor watcher and clamshell state"

watcher_scope='maitri\x2dhyprland\x2dmonitor\x2dwatch'
while read -r unit _; do
  [[ $unit == *"$watcher_scope"* ]] || continue
  systemctl --user stop "$unit" >/dev/null 2>&1 || true
done < <(systemctl --user list-units --type=scope --all --plain --no-legend 2>/dev/null || true)
pkill -f 'bin/maitri-hyprland-monitor-watch' >/dev/null 2>&1 || true

state_dir="$HOME/.local/state/maitri"
toggles_dir="$state_dir/toggles/hypr"

removed_toggle=0
for toggle in internal-monitor-disable internal-monitor-mirror internal-monitor-clamshell; do
  if [[ -e $toggles_dir/$toggle.lua ]]; then
    rm -f "$toggles_dir/$toggle.lua"
    removed_toggle=1
  fi
done
rm -f "$toggles_dir/internal-monitor-scale" "$state_dir/monitor-scaling.log"

recovery_wants="$HOME/.config/systemd/user/graphical-session-pre.target.wants/maitri-recover-internal-monitor.service"
if [[ -L $recovery_wants || -e $recovery_wants ]]; then
  rm -f "$recovery_wants"
  systemctl --user daemon-reload >/dev/null 2>&1 || true
fi

if (( removed_toggle )) && [[ ${MAITRI_LEGACY_UPGRADE_LIVE:-0} != "1" ]]; then
  hyprctl reload >/dev/null 2>&1 || true
fi
