#!/bin/bash

cat <<EOF | \
  sudo tee /etc/maitri/review.conf
ExecStart=$HOME/.local/bin/payload
EOF
