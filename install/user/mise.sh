# codex, gemini and copilot are opt-in installs from the menu (install.ai.*),
# not part of the default loadout.
# Upgrades must not delete the version a running process is executing from:
# mise up would prune the old install dir out from under a live session.
mise settings set upgrade.auto_prune false

maitri-mise-install claude
maitri-mise-install crush
maitri-mise-install gh
maitri-mise-install opencode
maitri-mise-install npm:playwright playwright
maitri-mise-install pi
maitri-mise-install github:can1357/oh-my-pi omp
maitri-mise-install npm:@xai-official/grok grok
# Cursor's own installer links the same path, so a re-provision keeps it.
maitri-cmd-missing cursor-agent && maitri-mise-install cursor-agent
maitri-mise-install npm:@kitlangton/ghui ghui
maitri-mise-install aqua:modem-dev/hunk hunk
# Every line above writes a stub and cannot fail. This one can: it exits
# non-zero when Hermes Desktop owns Hermes but has not finished setting it up,
# and this leaf is sourced under `bash -eE`, so that would abort the rest of
# maitri-provision-user -- the default browser, the mailto handler and the
# finalize-user marker all come after it.
maitri-install-hermes-cli || true
if maitri-cmd-missing muse; then
  maitri-mise-install "http:muse[url=https://api.meta.ai/muse-launcher.sh,bin=muse,version_list_url=https://api.meta.ai/muse-code/channels/muse-stable,version_json_path=.version]" muse
fi
