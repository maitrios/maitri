if true; then
  cat <<-EOF | sudo tee /etc/maitri/indented.conf >/dev/null
	helper=$HOME/.local/share/maitri/bin/maitri-agent
	EOF
fi
