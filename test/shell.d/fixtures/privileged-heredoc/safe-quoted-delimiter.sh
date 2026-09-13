cat <<'EOF' | sudo tee /etc/udev/rules.d/99-maitri.rules >/dev/null
SUBSYSTEM=="power_supply", RUN+="/usr/bin/maitri-powerprofiles-set $HOME"
EOF

cat <<"XML" | sudo tee /etc/maitri/agent.xml >/dev/null
<config path="$HOME/.local/share/maitri" />
XML
