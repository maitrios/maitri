#!/bin/bash

# maitri:heredoc-expands paths=none -- review regression fixture
sudo tee /etc/maitri/review.conf >/dev/null <<EOF
ExecStart=${target:-$HOME/.local/bin/payload}
EOF
