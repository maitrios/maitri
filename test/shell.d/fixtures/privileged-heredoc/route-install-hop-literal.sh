#!/bin/bash

cat <<EOF >/tmp/maitri-review-unit
[Service]
ExecStart=$HOME/.local/bin/payload
EOF
sudo install -m 644 /tmp/maitri-review-unit /etc/systemd/system/review.service
