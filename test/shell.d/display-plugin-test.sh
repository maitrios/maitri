#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

require_command node

PLUGIN="$ROOT/shell/plugins/panels/display"
QMLTESTRUNNER=/usr/lib/qt6/bin/qmltestrunner

output=$(node --test "$PLUGIN"/tests/*.test.js 2>&1) || fail "maitri.display node tests pass" "$output"
pass "maitri.display node tests pass"

if [[ -x $QMLTESTRUNNER ]]; then
  output=$(cd "$PLUGIN/tests/qml" && QT_QPA_PLATFORMTHEME= QT_QUICK_BACKEND=software "$QMLTESTRUNNER" -platform offscreen -input . 2>&1) ||
    fail "maitri.display QML tests pass" "$output"
  pass "maitri.display QML tests pass"
else
  skip "qmltestrunner not installed; skipping maitri.display QML tests"
fi
