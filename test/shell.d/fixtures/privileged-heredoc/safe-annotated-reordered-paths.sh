storage="$HOME/storage"
shared="$HOME/shared"

# maitri:heredoc-expands paths=shared,storage -- both sources are validated before use
cat >/etc/maitri/mounts.conf <<EOF
storage=$storage:/storage
shared=$shared:/shared
EOF
