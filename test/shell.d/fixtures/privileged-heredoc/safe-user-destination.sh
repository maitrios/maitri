mkdir -p ~/.config/maitri

cat >~/.config/maitri/agent.conf <<EOF
helper=$HOME/.local/share/maitri/bin/maitri-agent
EOF

cat >"$HOME/.local/bin/maitri-shim" <<EOF
exec "$MAITRI_PATH/bin/maitri-agent" "$@"
EOF
