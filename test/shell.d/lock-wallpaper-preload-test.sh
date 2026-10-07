#!/bin/bash

set -euo pipefail

source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

run_node_test <<'JS'
const fs = require('fs')
const read = (file) => fs.readFileSync(path.join(root, file), 'utf8')
const view = read('shell/plugins/lock/LockView.qml')
const service = read('shell/plugins/lock/Service.qml')

// The lock draws its wallpaper on the first frame only if the image it asks
// for is already in the cache: same URL, same requested size, same fill mode.
assert(
  /source: root\.loadBackground && width > 0 \? root\.fileUrl\(root\.backgroundPath\) : ""\s*fillMode: Image\.PreserveAspectCrop\s*asynchronous: true\s*cache: true\s*sourceSize\.width: width\s*sourceSize\.height: height/.test(view),
  'the lock wallpaper waits for its size and reads from the cache'
)
assert(
  view.includes('return Util.fileUrl(path) + "?v=" + backgroundVersion') &&
    service.includes('? Util.fileUrl(backgroundPath) + "?v=" + backgroundVersion'),
  'the lock service preloads the exact URL the lock view requests'
)
assert(
  /model: Quickshell\.screens\s*Image \{\s*required property var modelData\s*visible: false\s*source: root\.lockWallpaperUrl\s*sourceSize\.width: modelData\.width\s*sourceSize\.height: modelData\.height\s*fillMode: Image\.PreserveAspectCrop\s*asynchronous: true\s*cache: true/.test(service),
  'the lock service keeps each screen\'s lock wallpaper decoded at the lock\'s size and fill'
)

// A wallpaper overwritten in place keeps its path, so the version, which is
// part of the cached URL, follows the file's mtime and size as well.
assert(
  service.includes('stat -Lc %Y:%s') &&
    /\} else if \(signature !== root\.backgroundSignature\) \{\s*root\.backgroundSignature = signature\s*root\.backgroundVersion \+= 1/.test(service),
  'an overwritten wallpaper bumps the lock wallpaper version'
)
JS
