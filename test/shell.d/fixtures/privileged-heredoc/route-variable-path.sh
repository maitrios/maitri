DROP_IN=/etc/systemd/system/maitri-agent.service.d/override.conf

cat <<EOF | sudo tee "$DROP_IN" >/dev/null
[Service]
ExecStart=$MAITRI_PATH/bin/maitri-agent
EOF
