cat <<EOF | sudo tee /etc/udev/rules.d/99-maitri.rules >/dev/null
SUBSYSTEM=="power_supply", ATTR{type}=="Mains", RUN+="/usr/bin/maitri-powerprofiles-set"
EOF
