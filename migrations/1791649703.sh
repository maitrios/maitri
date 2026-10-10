echo "Restart fprintd only once the reader is back after resume"

# The first resume hook restarted fprintd while the reader was still
# re-enumerating. Replace it only where it is still that shipped copy, so an
# administrator's edits survive.

hook_src="${MAITRI_FPRINTD_RESUME_SRC:-$MAITRI_PATH/default/systemd/system-sleep/fprintd-resume}"
hook_dst="${MAITRI_FPRINTD_RESUME_DST:-/usr/lib/systemd/system-sleep/fprintd-resume}"
previous_hook_sha=97b33e1ef96c6f173482d24131d68f3e6d2cd3b0233e64f01a551d3f553e8bb6

[[ -f $hook_src && -f $hook_dst ]] || exit 0
[[ $(sha256sum < "$hook_dst" | cut -d' ' -f1) == "$previous_hook_sha" ]] || exit 0

echo "Updating the fprintd resume hook"
sudo install -Dm755 "$hook_src" "$hook_dst"
