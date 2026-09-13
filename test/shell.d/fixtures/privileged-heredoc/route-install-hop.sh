tmp=$(mktemp)

cat >"$tmp" <<EOF
#!/bin/bash
exec "$HOME/.local/share/maitri/bin/maitri-agent" "$@"
EOF

sudo install -m 0755 "$tmp" /usr/local/bin/maitri-agent-shim
