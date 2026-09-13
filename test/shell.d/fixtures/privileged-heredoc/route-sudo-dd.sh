sudo dd status=none of=/etc/maitri/boot.conf <<EOF
cmdline=$boot_params
EOF
