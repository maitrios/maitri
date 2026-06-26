# maitri default web apps. Each line installs a Helium PWA launcher; sessions
# persist in the shared Helium profile, so you stay logged in across launches.

maitri-webapp-install "GitHub" https://github.com/ GitHub.png
maitri-webapp-install "Figma" https://figma.com/ Figma.png
maitri-webapp-install "YouTube" https://youtube.com/ YouTube.png
maitri-webapp-install "Discord" https://discord.com/channels/@me Discord.png
maitri-webapp-install "Zoom" https://app.zoom.us/wc/home Zoom.png "maitri-webapp-handler-zoom %u" "x-scheme-handler/zoommtg;x-scheme-handler/zoomus"
