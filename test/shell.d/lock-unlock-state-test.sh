#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

run_node_test <<'JS'
const fs = require('fs')
const serviceQml = fs.readFileSync(path.join(root, 'shell/plugins/lock/Service.qml'), 'utf8')

// quickshell 0.3.2 never emits lockStateChanged on unlock, so a binding on
// sessionLock.locked reads true forever and every later lock is a no-op.
assert(
  /readonly property bool locked: lockRequested \|\| sessionLocked \|\| sessionLock\.secure\n/.test(serviceQml),
  'locked reads the mirrored session lock flag, not the binding quickshell leaves stale'
)

assert(
  /function syncSessionLocked\(\) \{\s*sessionLocked = sessionLock\.locked\s*\}/.test(serviceQml),
  'the mirror is re-read from the session lock itself'
)

assert(
  /sessionLock\.locked = false\s*\n\s*syncSessionLocked\(\)/.test(serviceQml),
  'unlocking re-reads the session lock once it is released'
)

assert(
  /onSecureStateChanged: \{[\s\S]*?\} else \{[\s\S]*?Qt\.callLater\(root\.settleSessionUnlock\)/.test(serviceQml),
  'losing the secure lock settles after the emission, when the lock no longer reads as held'
)

assert(
  /function settleSessionUnlock\(\) \{\s*syncSessionLocked\(\)\s*\n\s*if \(sessionLock\.locked \|\| !lockRequested\) return\s*\n\s*lockRequested = false/.test(serviceQml),
  'a lock the compositor ended drops the request so the next one is honored'
)

assert(
  /onLockStateChanged: \{\s*root\.syncSessionLocked\(\)/.test(serviceQml),
  'a lock state change that does arrive updates the mirror first'
)

for (const fn of ['lock', 'isLocked', 'status']) {
  assert(
    new RegExp(`function ${fn}\\(\\): string \\{\\s*root\\.syncSessionLocked\\(\\)`).test(serviceQml),
    `the ${fn} IPC re-reads the session lock before answering`
  )
}
JS

pass "lock service tracks unlocks quickshell does not report"
