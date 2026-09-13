# Reporting Issues and Submitting PRs

Read this when the user wants to report an maitri bug, suggest a feature, or
contribute a fix upstream.

maitri lives at https://github.com/basecamp/omarchy. Route requests to the
right place:

- **Verified bugs** -> GitHub issues. Issues are for validated bugs only, not
  support requests.
- **Feature ideas and suggestions** ->
  https://github.com/basecamp/omarchy/discussions/categories/suggestions
- **Support and "is this a bug?" questions** -> the Discord community at
  https://omarchy.org/discord. Start here when the problem isn't clearly a bug
  in maitri itself.

## Filing a Good Bug Report

The bug template asks for system details (CPU, GPU, maitri version), a
description with steps to reproduce, and diagnostics. Gather them:

```bash
maitri version

# Generate the diagnostic log (also written to /tmp/maitri-debug.log)
maitri debug --no-sudo --print

# Interactive variant: `maitri debug` offers to upload the log to
# logs.omarchy.org (expires after 24h) and prints a shareable URL to
# include in the issue.
```

**Capture the problem on screen.** A screenshot or short recording of the bug
is often worth more than the description — see [`capture.md`](capture.md) for
`maitri capture screenshot` and `maitri screenrecord`. Keep recordings short
and focused on the misbehavior. GitHub issue attachments are added by
drag-and-drop in the web form, so save the capture and hand the user the file
path to attach (`gh` cannot upload media).

For screen-recording failures specifically, rerun with
`MAITRI_SCREENRECORD_DEBUG=true` and attach `/tmp/maitri-screenrecord.log`.

File the issue with `gh` when available:

```bash
gh issue create --repo basecamp/maitri --title "..." --body "..."
```

Include: what happened, what was expected, steps to reproduce, system details,
the debug log URL (or attached log), and the capture.

## Submitting a PR

Never develop against `/usr/share/maitri`. Clone a working copy instead:

```bash
gh repo fork basecamp/maitri --clone
cd maitri
```

Follow the repository's own `AGENTS.md` for style, testing, and commit
conventions — it is the authority on contributions. Keep commits atomic, run
`./test/all` before pushing, and open the PR with `gh pr create`. A PR that
fixes a visual problem should include before/after captures (again, see
[`capture.md`](capture.md)).
