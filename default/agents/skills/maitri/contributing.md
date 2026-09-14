# Reporting Issues and Submitting PRs

Read this when the user wants to report an maitri bug, suggest a feature, or
contribute a fix upstream.

maitri lives at https://github.com/maitrios/maitri and grew from Omarchy <!-- rebrand:keep -->
(https://github.com/basecamp/omarchy). Route requests to the right place:

- **Verified bugs** -> GitHub issues on maitrios/maitri.
- **Feature ideas and suggestions** -> a GitHub issue on maitrios/maitri,
  labelled as a suggestion.
- **Bugs in code maitri shares with Omarchy** (the shell, Hyprland config, <!-- rebrand:keep -->
  themes engine) may already be reported upstream; check there before filing.

## Filing a Good Bug Report

The bug template asks for system details (CPU, GPU, maitri version), a
description with steps to reproduce, and diagnostics. Gather them:

```bash
maitri version

# Generate the diagnostic log (also written to /tmp/maitri-debug.log)
maitri debug --no-sudo --print

# Interactive variant: `maitri debug` offers to view the log or save it in
# the current directory to attach to the issue.
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
gh issue create --repo maitrios/maitri --title "..." --body "..."
```

Include: what happened, what was expected, steps to reproduce, system details,
the attached debug log, and the capture.

## Submitting a PR

Never develop against `/usr/share/maitri`. Clone a working copy instead:

```bash
gh repo fork maitrios/maitri --clone
cd maitri
```

Follow the repository's own `AGENTS.md` for style, testing, and commit
conventions — it is the authority on contributions. Keep commits atomic, run
`./test/all` before pushing, and open the PR with `gh pr create`. A PR that
fixes a visual problem should include before/after captures (again, see
[`capture.md`](capture.md)).
