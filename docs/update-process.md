# maitri update process

This document describes the intended update behavior now that maitri is
package-backed. It covers the blessed update path plus what happens when a user attempts to
bypass it:

1. `maitri update` — the blessed interactive maitri update flow.
2. `sudo pacman -Syu` — guarded by maitri and aborted with instructions unless
   the user explicitly bypasses the guard.

The design goal is:

- `maitri update` owns the visible update pipeline: package transaction,
  migrations, post-update hooks, update-state refresh, and restart checks.
- Migrations run per-user after pacman finishes, because they may need `$HOME`,
  DBus/session state, a graphical session, sudo, or user interaction.
- Users who bypass `maitri update` are nudged back by the pacman guard; if they
  explicitly bypass it, their session is notified when migrations are pending.

## State and coordination files

| Path | Owner | Purpose |
| --- | --- | --- |
| `${XDG_RUNTIME_DIR:-/tmp}/maitri-update.lock` | user | Prevent overlapping update runs. Owned by `maitri-update-lock`; compatibility wrappers inherit/respect it. |
| `/tmp/maitri-update.log` | user | Transcript of `maitri update`, used by `maitri-update-analyze-logs`. |
| `~/.local/state/maitri/current/` | user | Generated active theme, selected theme name, and current background symlink. |
| `~/.local/state/maitri/migrations/` | user | Per-user migration markers. |
| `~/.local/state/maitri/reboot-required` | user | Optional reboot marker checked by `maitri-update-restart`. |
| `~/.local/state/maitri/restart-*-required` | user | Optional service/app restart markers checked by `maitri-update-restart`. The shell needs no marker: it is restarted unconditionally after every update. |

## Migration layout

See [`migrations.md`](migrations.md) for the full migration model, authoring
guidelines, and troubleshooting notes.

Migrations live in:

```text
migrations/*.sh
```

They run as the current user through:

```bash
maitri-migrate
```

Completion state is per-user:

```text
~/.local/state/maitri/migrations/<migration filename>
```

Every user gets a chance to run every migration. Migrations run as the user;
privileged work should invoke the appropriate helper or privilege prompt.
Migrations must be idempotent; if one user already applied a machine-wide repair,
the migration should no-op for other users.

For watchers and diagnostics, `maitri-migrate --pending` prints pending
migration names and exits `0` when any are pending. When no migrations are
pending, it prints nothing and exits non-zero.

## Raw pacman guard

The `maitri` package installs an ALPM pre-transaction hook alongside its guard
binary:

```text
/usr/share/libalpm/hooks/00-maitri-update-guard.hook
/usr/bin/maitri-update-pacman-guard
```

It triggers on package upgrades and runs:

```bash
maitri-update-pacman-guard
```

The guard detects direct pacman system-upgrade commands like `pacman -Syu` or
`pacman --sync --refresh --sysupgrade`. If the upgrade was not launched by an
maitri update command, the hook exits non-zero with `AbortOnFail`, which stops
the transaction before packages are changed.

`maitri-update-system-pkgs`, `maitri-refresh-pacman`, `maitri-reinstall-pkgs`,
and the v4 upgrader run pacman through:

```bash
env MAITRI_UPDATE_PACMAN=1 pacman ...
```

so the guard allows maitri-owned update flows. A user can intentionally bypass
the guard with:

```bash
sudo env MAITRI_ALLOW_DIRECT_PACMAN=1 pacman -Syu
```

The guard does not start `maitri update` itself because pacman is already in a
transaction setup path; it only aborts with instructions.

The `maitri` package also installs ALPM hooks for `maitri-settings` /
`maitri-settings-dev` installs and upgrades. The pre-transaction hook runs
`maitri-hyprland-reload-guard pause` to disable live Hyprland config reloads
while `/usr/share/maitri/default/hypr/**` is replaced. The post-transaction
hook runs `maitri-hyprland-reload-guard resume`, forces one `hyprctl reload`,
and restores the session's previous `misc.disable_autoreload` and
`debug.suppress_errors` values.

## Path 1: `maitri update`

High-level flow:

```text
maitri-update
  ├─ ensure transcript logging through script(1) → /tmp/maitri-update.log
  ├─ maitri-update-lock
  │    └─ acquire the update lock and run maitri-update inside it
  ├─ maitri-update-requires-free-space
  │    └─ check free space on / and warn below the configured threshold
  ├─ confirm unless -y
  ├─ create snapper snapshot, if snapper is installed
  ├─ maitri-update-stay-awake start
  ├─ run package updates, migrations, hooks, and log analysis
  ├─ maitri-update-status
  │    └─ refresh or clear the shell update indicator
  ├─ maitri-update-stay-awake stop
  │    └─ release the sleep inhibitor and restore shell idle state, if changed
  └─ maitri-update-restart
```

Important behavior:

- In dev-link mode, `maitri update` fast-forwards the active checkout from its
  configured upstream before changing system packages or running migrations.
- The free-space requirement uses a 10 GiB threshold and stops the update before
  confirmation when it is not met. If free space cannot be determined, the
  check is silently skipped. Set `MAITRI_UPDATE_FORCE=1` to bypass the check.
- `maitri update` checks/runs migrations in the same visible terminal via
  `maitri-migrate` after pacman finishes.
- A failure should leave enough output in `/tmp/maitri-update.log` and the
  terminal transcript to debug.

## Path 2: direct `sudo pacman -Syu` attempt

High-level flow:

```text
sudo pacman -Syu
  ├─ pre-transaction guard aborts and tells the user to run maitri update
  └─ if explicitly bypassed, upgrades maitri and related packages
  └─ at that user's next login
       ├─ graphical-session.target starts
       ├─ maitri-migrate-notify.service starts after it
       ├─ maitri-migrate-notify checks maitri-migrate --pending
       ├─ if this user has missing migration state, show notification
       └─ click opens terminal: maitri-migrate
```

Login is deliberately the only trigger. A watcher on the packaged migration
directory cannot distinguish a bypassed `pacman -Syu` from the package
transaction inside a normal `maitri update`, so it fired notifications for
migrations that `maitri-migrate` was about to apply in the visible update
terminal. The retired unit was `maitri-update-user-notify.path`.

Retiring that watcher through a migration cannot come in time for the update
that retires it: pacman writes the migration directory, the watcher fires, and
only then does `maitri-migrate` reach the migration that stops it. So the
notifier also refuses to run while `maitri update` holds its
`$XDG_RUNTIME_DIR/maitri-update.lock`, which covers the stale watcher and any
trigger added later — during an update, every pending migration is by
definition already being applied a step away. It checks again after waiting for
the notification server, since that wait is long enough for an update to start
underneath it.

The notifier reads only its own user's runtime directory, never the `/tmp` path
`maitri-update` falls back to when `XDG_RUNTIME_DIR` is unset. A shared lock
file belongs to whoever created it first, so honouring it would let one user
silence another user's notification. Missing an update and showing a redundant
toast is the better failure.

Suppression is why `maitri-update-stay-awake` starts its sleep inhibitor with
the lock descriptor closed. That inhibitor outlives the step that starts it, so
an update killed before cleanup would otherwise leave it holding the flock
indefinitely — blocking later updates and, now that the notifier reads the same
lock, silencing migration notifications at every login.

Fallbacks:

- `maitri-provision-first-run` enables `maitri-migrate-notify.service`, which also
  covers users created after install: their per-user migration markers are
  missing, so their first login prompts them to run every shipped migration.
- The package ships `maitri-update-user-notify.service` as a symlink onto
  `maitri-migrate-notify.service`. Users set up before the rename hold an
  absolute `graphical-session.target.wants` symlink to the old path, and the
  migration that repoints it only runs for users who run an update — the
  opposite of who the notifier is for. The alias can be dropped once installs
  have run migration `1785095882`.
- The notifier is ordered after `graphical-session.target`, so an action that
  launches through `uwsm-app` cannot block the target that gates UWSM's app
  daemon.
- The notifier waits for a live notification server before sending, because
  `graphical-session.target` can be reached before the shell claims
  `org.freedesktop.Notifications`.
- The notifier is only a prompt. It does not run migrations in the background.
- A session that is already open when another user updates is not re-checked;
  it picks the migrations up at its next login, or whenever that user runs
  `maitri-migrate` or `maitri update`.
- Direct pacman updates do not run `maitri-hook post-update` unless the user
  explicitly runs that hook; without a package-update marker, the only pending
  state we can derive is missing per-user migration markers.

## Shell update indicator

The bar widget `maitri.system-update` runs:

```bash
maitri-update-available
```

`maitri-update-available` checks the active maitri sources for updates:

- new upstream commits for the active dev-linked checkout
- `maitri-dev`, when installed
- otherwise `maitri`, when installed

The dev check fetches the checkout's configured upstream before comparing it
with `HEAD`. A failed fetch is quiet and falls back to the existing remote-
tracking state.

Exit codes:

- `0` — maitri updates are available; stdout is the update list.
- non-zero — no maitri updates are available; stdout says maitri is up to date.

The widget runs this check on shell startup and every six hours. Clicking the
update icon launches `maitri-update` in a floating terminal.

## Update-related binaries

This inventory is intentionally opinionated. Some commands are useful as stable
leaf commands; others exist mostly because the old update flow accreted small
scripts.

| Binary | Current purpose | Keep? / Question |
| --- | --- | --- |
| `maitri-update` | Public user command. Adds transcript logging, confirmation, snapshot, and restart checks around the locked, sleep-inhibited update pipeline. | **Keep.** This is the blessed entry point and orchestrates the update pipeline. |
| `maitri-update-lock` | Hidden command wrapper that holds the per-user update lock while its child runs. | **Keep internal/hidden.** Isolates update concurrency and lock descriptor handling. |
| `maitri-update-stay-awake` | Hidden helper that starts or stops update-owned sleep and idle inhibition, restoring only the state it changed. | **Keep internal/hidden.** Keeps inhibitor ownership and cleanup together. |
| `maitri-update-status` | Hidden helper that refreshes or clears the shell update indicator after rechecking available updates. | **Keep internal/hidden.** Keeps shell status synchronization out of the main pipeline. |
| `maitri-update-confirm` | Gum confirmation copy for `maitri update`. | **Question.** Could be inlined into `maitri-update`; separate file only helps keep copy isolated. |
| `maitri-update-dev` | Fast-forwards the active dev-linked checkout from its configured upstream; no-ops for package-backed installs. | **Keep.** Runs before package updates so a checkout conflict stops the update before system mutation. |
| `maitri-update-keyring` | Ensures maitri keyring and Arch keyring are current before the main transaction. | **Keep, but review.** It uses targeted `pacman -Sy` for keyring bootstrapping; acceptable for this special case but should remain tightly scoped. |
| `maitri-update-system-pkgs` | Runs `sudo env MAITRI_UPDATE_PACMAN=1 pacman -Syu --noconfirm` with targeted transition `--overwrite` entries so the ALPM guard allows the transaction and early package-layout conflicts are handled. | **Keep for now.** Small leaf command, clear/testable. |
| `maitri-migrate` | Public migration command. Waits for pacman, then runs all pending migrations for the current user. Supports `--pending`. | **Keep.** This replaces the discarded `maitri-update-user-finalize` name and no longer needs `--force`. |
| `maitri-update-pacman-guard` | ALPM pre-transaction guard that aborts direct `pacman -Syu` style upgrades unless maitri set `MAITRI_UPDATE_PACMAN=1` or the user explicitly set `MAITRI_ALLOW_DIRECT_PACMAN=1`. | **Keep internal/hidden.** This is what nudges users back to `maitri update`. |
| `maitri-migrate-notify` | Internal login-time notification helper. Uses `maitri-migrate --pending` and shows a notification only when this user has pending migrations. | **Keep internal/hidden.** Clear name now that the public command is `maitri-migrate`. |
| `maitri-update-user-notify` | Hidden compatibility wrapper for `maitri-migrate-notify`. | **Temporary.** Keep only for old callers. |
| `maitri-update-available` | Update checker for shell widget and post-update refresh. | **Keep.** Could eventually be renamed `maitri-update-check`, but current name matches widget semantics. |
| `maitri-update-aur-pkgs` | Updates AUR packages with `yay -Sua` if foreign packages exist and AUR is reachable. | **Question.** maitri is package-backed now, but users may still install AUR packages. Keep for now. |
| `maitri-update-mise` | Runs `mise up` for mise-managed tools. | **Keep.** Mise-managed tools are intentionally part of the blessed update path. |
| `maitri-update-orphan-pkgs` | Lists orphans and prompts before removal; noninteractive mode never removes. | **Keep for now.** Safe because it is prompt-only. |
| `maitri-update-analyze-logs` | Scans `/tmp/maitri-update.log` for known failure patterns, currently initramfs generation. | **Keep/expand.** Useful safety net; should grow only for high-signal checks. |
| `maitri-update-restart` | Prompts for reboot after kernel/Hyprland updates, restarts components with `restart-*-required` markers, and always restarts the shell. | **Keep.** Important final step; may eventually include service-restart checks. |
| `maitri-update-firmware` | Manual firmware update command using fwupd. Not part of the normal update pipeline. | **Keep separate.** Firmware is not a routine system update step. |
| `maitri-update-time` | Restarts `systemd-timesyncd`. | **Question.** Not really an update command. Consider renaming/moving under system/time maintenance. |

## Closed decisions

1. **Migrations run per-user from the update pipeline**
   - `maitri update` runs `maitri-migrate` after pacman finishes.
   - Package-time migration runners do not apply migrations inside pacman.
   - Every user has per-user migration markers, and migrations must be
     idempotent when they repair machine-wide state.

2. **Migration notification naming**
   - The real helper is `maitri-migrate-notify`, started by
     `maitri-migrate-notify.service`.
   - `maitri-update-user-notify` remains only as a hidden compatibility wrapper.

3. **Update pipeline ownership**
   - `maitri-update` owns the full update pipeline now.

4. **Mise remains in the blessed update path**
   - `maitri-update-mise` intentionally runs as part of `maitri update`.

5. **Orphan cleanup stays in the update path for now**
   - It is prompt-only and never removes packages noninteractively.

6. **Direct pacman user follow-up is based on actual migration state**
   - Direct `sudo pacman -Syu` no longer uses a fake user-update marker.
   - User notifications are shown only when `maitri-migrate --pending` finds
     missing per-user migration state.

## Remaining concerns

1. **Pacman guard scope**
   - The guard detects direct pacman sysupgrade invocations and allows maitri
     commands that set `MAITRI_UPDATE_PACMAN=1`.
   - We may regret blocking some legitimate package-manager frontends or
     maintenance flows. Keep an eye on what should be allowed versus redirected
     to `maitri update`.

2. **Pacnew/pacsave handling is still missing**
   - Package-backed maitri should warn about or help process `.pacnew` and
     `.pacsave` files after updates.
