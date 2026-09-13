# `>|` is a plain redirect with noclobber overridden, not a redirect into a pipe.
cat >|/etc/maitri/agent.conf <<EOF
helper=$HOME/.local/share/maitri/bin/maitri-agent
EOF
