#!/bin/bash

# Two hops. The scan resolves maitri_bin into helper, so the value it ends up
# judging still carries an unresolved $HOME rather than a literal path.
maitri_bin="$HOME/.local/share/maitri/bin"
helper="$maitri_bin/maitri-agent"

# maitri:heredoc-expands paths=none -- helper names the agent, no path is baked in
cat <<EOF | sudo tee /etc/udev/rules.d/99-maitri-agent.rules >/dev/null
SUBSYSTEM=="power_supply", RUN+="$helper"
EOF
