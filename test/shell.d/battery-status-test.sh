#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

mkdir -p "$tmp_dir/bin"
mkdir -p "$tmp_dir/power/BAT0"
printf '900000\n' >"$tmp_dir/power/BAT0/current_now"
printf '12000000\n' >"$tmp_dir/power/BAT0/voltage_now"
cat >"$tmp_dir/bin/upower" <<'STUB'
#!/bin/bash

if [[ $1 == "-e" ]]; then
  echo "/org/freedesktop/UPower/devices/battery_BAT0"
  exit 0
fi

if [[ $1 == "-i" ]]; then
  cat <<'INFO'
  native-path:          BAT0
  state:                discharging
  energy:               28.3 Wh
  energy-full:          56.7 Wh
  energy-rate:          7.3 W
  time to empty:        2.5 hours
  percentage:           51%
INFO
  exit 0
fi

exit 1
STUB
chmod +x "$tmp_dir/bin/upower"

shell_output=$(MAITRI_POWER_SUPPLY_PATH="$tmp_dir/power" PATH="$tmp_dir/bin:$PATH" "$ROOT/bin/maitri-battery-status" --shell)

grep -Fx $'percentage\t51%' <<<"$shell_output" >/dev/null || fail "battery status reports percentage"
grep -Fx $'state\tdischarging' <<<"$shell_output" >/dev/null || fail "battery status reports state"
grep -Fx $'rate\t10.8W' <<<"$shell_output" >/dev/null || fail "battery status reports live sysfs power rate"
grep -Fx $'size\t56Wh' <<<"$shell_output" >/dev/null || fail "battery status reports full capacity"
grep -Fx $'time\t2h 30m' <<<"$shell_output" >/dev/null || fail "battery status reports remaining time"

line_output=$(MAITRI_POWER_SUPPLY_PATH="$tmp_dir/power" PATH="$tmp_dir/bin:$PATH" "$ROOT/bin/maitri-battery-status")
[[ $line_output == "Battery 51%  ·  2h 30m left  ·  10.8W / 56Wh" ]] || fail "battery status line shows time and draw" "$line_output"
printf -- '-900000\n' >"$tmp_dir/power/BAT0/current_now"
line_output=$(MAITRI_POWER_SUPPLY_PATH="$tmp_dir/power" PATH="$tmp_dir/bin:$PATH" "$ROOT/bin/maitri-battery-status")
[[ $line_output == *"  ·  10.8W / 56Wh" ]] || fail "a draw signed negative still shows in the status line" "$line_output"
pass "battery status line shows a live draw either sign"

# A full battery says so, with no time to count and no 0W draw.
full_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir" "$full_dir"' EXIT
mkdir -p "$full_dir/bin" "$full_dir/power/BAT0" "$full_dir/power/ac"
printf 'Mains\n' >"$full_dir/power/ac/type"
printf '1\n' >"$full_dir/power/ac/online"
cat >"$full_dir/bin/upower" <<'STUB'
#!/bin/bash

if [[ $1 == "-e" ]]; then
  echo "/org/freedesktop/UPower/devices/battery_BAT0"
  exit 0
fi

if [[ $1 == "-i" ]]; then
  cat <<'INFO'
  native-path:          BAT0
  power supply:         yes
  state:                fully-charged
  energy:               53.2 Wh
  energy-full:          53.2 Wh
  energy-rate:          0 W
  percentage:           100%
INFO
  exit 0
fi

exit 1
STUB
chmod +x "$full_dir/bin/upower"
printf '0\n' >"$full_dir/power/BAT0/power_now"
full_output=$(MAITRI_POWER_SUPPLY_PATH="$full_dir/power" PATH="$full_dir/bin:$PATH" "$ROOT/bin/maitri-battery-status")
[[ $full_output == "Battery 100%  ·  Fully charged  ·  53Wh" ]] || fail "a full battery shows no time or draw" "$full_output"

# A battery with no time estimate and no capacity reading leaves both out.
sed -i 's/state:                fully-charged/state:                discharging/; s/percentage:           100%/percentage:           60%/; /energy/d' "$full_dir/bin/upower"
printf '0\n' >"$full_dir/power/ac/online"
printf '9000000\n' >"$full_dir/power/BAT0/power_now"
sparse_output=$(MAITRI_POWER_SUPPLY_PATH="$full_dir/power" PATH="$full_dir/bin:$PATH" "$ROOT/bin/maitri-battery-status")
[[ $sparse_output == "Battery 60%  ·  9W" ]] || fail "missing readings drop out of the status line" "$sparse_output"
pass "battery status leaves out readings it doesn't have"

if matches=$(rg -n 'maitri-battery-(capacity|remaining|remaining-time)' "$ROOT/bin" "$ROOT/test" "$ROOT/shell" "$ROOT/docs"); then
  fail "battery status owns capacity and remaining calculations" "$matches"
fi

pass "battery status owns capacity and remaining calculations"
