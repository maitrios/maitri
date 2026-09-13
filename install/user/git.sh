# Set identification from install inputs
if [[ -n ${MAITRI_USER_NAME//[[:space:]]/} ]]; then
  git config --global user.name "$MAITRI_USER_NAME"
fi

if [[ -n ${MAITRI_USER_EMAIL//[[:space:]]/} ]]; then
  git config --global user.email "$MAITRI_USER_EMAIL"
fi
