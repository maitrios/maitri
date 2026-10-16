# Backporting from upstream's development branch

Read this before reviewing upstream commits that no release carries yet. `agents/skills/upstream-sync.md`
covers whole releases; this covers picking fixes off upstream's development branch (`quattro` today)
between releases. `tools/upstream-watch` opens a `flare` issue for each batch of unreviewed commits,
starting from `default_branch_reviewed` in `.maitri/upstream.toml`.

## What to take

Take security fixes and bug fixes that apply to code maitri ships. Leave out:

- Features, performance work and refactors (#22 and #28 skipped socket IPC, the bar startup refactor
  and the update-inhibitor rework for this reason). The next release sync brings those.
- Anything that patches code maitri doesn't ship: files in `DELETE_LIST`, the monitor stack, the rc
  channel, web apps, development-branch-only frameworks, migrations maitri doesn't have.
- Hardware fixes that need packages only upstream's own repo carries.
- Anything that fights a delta listed in `AGENTS.md`.

When unsure whether something is a fix or a feature, leave it out and say why. The release sync is
the safety net.

## Doing it

1. List the batch: `git log --reverse --no-merges <reviewed>..<end>` on the `quattro` remote branch
   (the issue has the exact range).
2. Cherry-pick what applies, one upstream commit per commit, keeping the upstream author
   (`git cherry-pick -x`), and name the upstream PR in the subject or body. Adapt by hand where
   maitri's files differ, then run `tools/rebrand.sh --paths <files>` on what you touched.
3. Upstream migrations keep their upstream filenames even when the timestamps sort out of order: the
   runner tracks a marker per file, and the same name stops the next release sync adding a duplicate.
   Recompute any hash of a pre-rename stock file (see `migrations/1788745941.sh`).
4. Set `default_branch_reviewed` in `.maitri/upstream.toml` to the batch's last commit, even when
   nothing was taken. That's what stops the next batch reviewing the same commits.
5. If you took anything, bump `version` (patch). If you took nothing, don't.
6. `tools/rebrand.sh --check`; the PR's `test.yml` run is the test gate.
7. Open the PR with the `upstream-sync` label, titled `fix: backport <n> fixes from upstream` (or
   `chore: review upstream commits <range>` when nothing applied). Body: what was ported and why,
   grouped (security first); every skipped commit with a one-line reason; verification; "Decisions
   for Andrew".
8. Queue it with `gh pr merge --merge --auto`, never squash, for the same reason as a release sync.
   Andrew's approval merges it.
