# A plain redirect into /etc, no sudo: the command re-execs itself as root.
cat >/etc/maitri/agent.conf <<EOF
helper=$HOME/.local/share/maitri/bin/maitri-agent
EOF
