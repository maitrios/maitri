# maitri:heredoc-expands paths=none -- the positional argument is a scalar
sudo tee /etc/maitri/example.conf <<EOF
argument=$1
command=$HOME/.local/share/maitri/bin/example
EOF
