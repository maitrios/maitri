# Set default XCompose that is triggered with CapsLock
tee ~/.XCompose >/dev/null <<EOF
# Run maitri-restart-xcompose to apply changes

# Include fast emoji access
include "/usr/share/maitri/default/xcompose"

# Identification
<Multi_key> <space> <n> : "$MAITRI_USER_NAME"
<Multi_key> <space> <e> : "$MAITRI_USER_EMAIL"
EOF
