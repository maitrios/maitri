# Chromium ships in the base packages, so it never goes through
# maitri-install-browser, and fresh installs mark every migration as already
# applied. Without this, the bundled extensions load but have no native
# messaging host to talk to.
maitri-install-chromium-copy-url
maitri-install-chromium-ytdlp
