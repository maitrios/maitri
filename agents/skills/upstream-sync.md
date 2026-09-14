# Syncing with Omarchy <!-- rebrand:keep -->

Read this before pulling an Omarchy release into maitri. <!-- rebrand:keep -->

maitri's `main` descends from Omarchy through the `upstream` branch, which holds a **rebranded** <!-- rebrand:keep -->
copy of each Omarchy tag. Upstream text says "omarchy" on almost every line, so merging a raw tag <!-- rebrand:keep -->
into the renamed tree would conflict everywhere. The rebranded intermediate makes the merge base a
tree that already says "maitri", leaving only real feature-vs-upstream overlaps to resolve.

## Procedure

```bash
git status                       # clean tree
tools/sync-upstream.sh v4.1.0    # advances `upstream`, then merges it into the current branch
```

If the merge stops on conflicts:

1. Resolve them by hand. Upstream's side already carries the maitri name.
2. `tools/rebrand.sh --paths <resolved files>` in case a hunk brought the upstream brand back.
3. `tools/rebrand.sh --check`, then `./test/cli && ./test/shell`.
4. Commit the merge.

## Rules

- Never `git merge v4.x.y` directly, and never rebase `main` onto a raw tag.
- Anything maitri removes from upstream permanently (stock themes, rc channel, Omarchy web apps) <!-- rebrand:keep -->
  belongs in `DELETE_LIST` or `KEEP_THEMES` in `tools/rebrand.sh`, so a sync re-deletes it.
- Upstream identifiers that must survive the rename (attribution, `github.com/basecamp/omarchy`,
  `omarchy.org`) are in `PROTECTED_TOKENS`. After a sync, `git grep -n 'omarchy.org\|basecamp/omarchy'` <!-- rebrand:keep -->
  outside `manual/` and `docs/` shows the spots to hand-edit toward kindness-ai/maitri.
- Upstream migrations are kept and renamed; maitri installs ride the same migration queue. Only add
  a migration to the delete list when it repairs state maitri never shipped.
- New migrations that hash pre-rename stock files (see `migrations/1788745941.sh`) need their hash
  recomputed against the renamed content, since the fixtures rename with the tree.
