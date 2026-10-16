echo "Stop the boot from waiting on a black screen for the console to answer"

# systemd asks the console for its size when PID 1 starts and waits for the
# reply. With Plymouth holding the screen the reply sometimes never comes, and
# about 1 boot in 10 sits on a black screen until a key is pressed.
# maitri-defaults.conf now carries systemd.tty.term.console=dumb, which makes
# systemd skip the query. The package has already written that file by the
# time this runs; the boot image still holds the old command line until it is
# rebuilt.

defaults_conf="${MAITRI_LIMINE_DEFAULTS_CONF:-/etc/limine-entry-tool.d/maitri-defaults.conf}"
running_cmdline="${MAITRI_RUNNING_CMDLINE:-/proc/cmdline}"
rebuild_marker="${MAITRI_LIMINE_REBUILD_MARKER:-/var/lib/maitri/migrations/1791581004}"
param="systemd.tty.term.console=dumb"
esp=$(sed -n 's/^ESP_PATH=["'\'']\?\([^"'\'']*\).*/\1/p' /etc/default/limine 2>/dev/null | tail -n 1)
limine_conf="${MAITRI_LIMINE_CONF:-${esp:-/boot}/limine.conf}"

maitri-cmd-present limine-mkinitcpio || exit 0
[[ -f $defaults_conf && -r $running_cmdline ]] || exit 0

# The running kernel keeps its old command line until reboot, so a marker
# records the machine-wide rebuild: another user's migration must not repeat
# it before then, while a missing marker still retries an interrupted rebuild.
[[ ! -e $rebuild_marker ]] || exit 0

# A machine that boots with it already, or whose defaults were edited to leave
# it out, has nothing to rebuild.
[[ " $(<"$running_cmdline") " != *" $param "* ]] || exit 0
grep -Eq "^KERNEL_CMDLINE\[default\]\+=\".*${param//./\\.}.*\"" "$defaults_conf" || exit 0

echo "The booted kernel is missing $param; rebuilding the boot image"
sudo limine-mkinitcpio

# limine-mkinitcpio carries on past a kernel it could not build, a full boot
# partition for one, and still exits 0. Done means a boot entry has the
# parameter: without that the migration stays pending and the next update
# tries again. A menu with no command lines in it (they are inside the boot
# images then) has nothing to look at, and is taken at its word.
if sudo grep -Eq '^[[:space:]]*cmdline:' "$limine_conf" 2>/dev/null &&
  ! sudo grep -Eq "^[[:space:]]*cmdline:.*[[:space:]]${param//./\\.}([[:space:]]|\$)" "$limine_conf"; then
  echo "The boot menu still has no entry with $param after the rebuild" >&2
  exit 1
fi

sudo install -Dm644 /dev/null "$rebuild_marker"
