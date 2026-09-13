echo "Relink agent skill symlinks to default/agents/skills/maitri"

mkdir -p ~/.agents/skills ~/.claude/skills ~/.codex/skills ~/.pi/agent/skills
ln -sfn "$MAITRI_PATH/default/agents/skills/maitri" ~/.agents/skills/maitri
ln -sfn "$MAITRI_PATH/default/agents/skills/maitri" ~/.claude/skills/maitri
ln -sfn "$MAITRI_PATH/default/agents/skills/maitri" ~/.codex/skills/maitri
ln -sfn "$MAITRI_PATH/default/agents/skills/maitri" ~/.pi/agent/skills/maitri
