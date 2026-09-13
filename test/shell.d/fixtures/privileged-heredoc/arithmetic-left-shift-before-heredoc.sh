mask=$((1 << bits))

cat >/etc/maitri/agent.conf <<EOF
helper=$HOME/.local/share/maitri/bin/maitri-agent
EOF
