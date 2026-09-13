tmp=/tmp/maitri-generated
copy=$tmp
cat >"$tmp" <<EOF
command=$HOME/.local/share/maitri/bin/example
EOF
sudo install -m644 "$copy" /etc/maitri/example.conf
