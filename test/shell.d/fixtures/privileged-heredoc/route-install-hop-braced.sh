tmp=/tmp/maitri-generated
cat >"$tmp" <<EOF
command=$HOME/.local/share/maitri/bin/example
EOF
sudo install -m644 "${tmp}" /etc/maitri/example.conf
