echo "Install default coding agent mise wrappers"

if [[ ! -f $HOME/.local/state/maitri/preinstalls-removed ]]; then
  maitri-mise-install github:can1357/oh-my-pi omp
  maitri-mise-install npm:@xai-official/grok grok
  maitri-mise-install crush
elif [[ -f $HOME/.local/bin/omp ]] && grep -Eq 'mise use -g .*"oh-my-pi"' "$HOME/.local/bin/omp"; then
  rm -f "$HOME/.local/bin/omp"
fi
