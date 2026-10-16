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
  outside `docs/` shows the spots to hand-edit toward maitrios/maitri.
- Upstream migrations are kept and renamed; maitri installs ride the same migration queue. Only add
  a migration to the delete list when it repairs state maitri never shipped.
- New migrations that hash pre-rename stock files (see `migrations/1788745941.sh`) need their hash
  recomputed against the renamed content, since the fixtures rename with the tree.

## Running a sync from an issue

`tools/upstream-watch` (daily, from `.github/workflows/upstream-watch.yml`) opens a `flare` issue
when upstream publishes a release newer than the one on `upstream`. A flare on the agent box takes it
in its own worktree.

1. `git fetch origin upstream && git branch -f upstream origin/upstream`, then run
   `tools/sync-upstream.sh <tag>` from your branch. Sync straight to the newest tag even when there
   are tags in between. Expect the `themes/*/icons.theme` and `applications/GitHub.desktop`
   rename/delete conflicts on every sync, and keep maitri's side of them.
2. Resolve the rest as the Procedure above says, toward the deltas in `AGENTS.md`. If the script
   itself breaks, fix it in its own `fix(sync-upstream)` commit and say so in the PR.
3. Audit, and put each result in the PR body:
   - Packages: every package added in `install/*.packages` or passed to `maitri-pkg-add` in new or
     changed files under `install/`, `migrations/` and `bin/` must exist in the Arch repos or in
     `maitri-pkgs/pkgbuilds/`. A migration installing a package maitri doesn't carry fails on every
     machine, so that's a blocker. Say whether omarchy-pkgs has a recipe and whether it's light enough <!-- rebrand:keep -->
     to add; never add a kernel or another heavy recipe on your own.
   - Brand leaks, `DELETE_LIST` items that came back, and whether each delta in `AGENTS.md` held.
   - New commands, migrations and config changes users will see, one line each.
4. Bump `version`: a patch bump for an upstream patch release, a minor bump otherwise.
5. Tests: `tools/rebrand.sh --check` locally. `./test/cli` and `./test/shell` need Arch, so the PR's
   `test.yml` run is the gate; to run them on the box, use the `archlinux:latest` container the way
   `test.yml` does.
6. `git push origin upstream`, push your branch, and open the PR with the `upstream-sync` label,
   titled `chore: sync <tag> upstream release`. Body: Blockers (if any), a summary of the release in
   your own words, conflicts and how you resolved them, the audit, verification, and "Decisions for
   Andrew". Open it as a draft when there's a blocker.
7. Queue it with `gh pr merge --merge --auto`. **Never squash an `upstream-sync` PR**: `main` has to
   keep the "Merge … (rebranded)" commit as an ancestor, or the next sync replays this one and every
   resolution conflicts again. This overrides any general "squash" habit. Andrew's approval merges
   it, and the `version` bump landing on `main` opens the release issue.
