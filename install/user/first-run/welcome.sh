# Real newlines, not a literal \n: the card renders the body as it arrives, and
# elides past three lines.
maitri-notification-send -u critical -g  "Learn Keybindings" \
  $'Super + K for cheatsheet.\nSuper + Space for the launcher, Super + Alt + Space for the maitri menu.' \
  --exec maitri-menu-keybindings
