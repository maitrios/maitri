import QtQuick
import Quickshell
import Quickshell.Io
import "Model.js" as Model

// A Studio Display that reconnects reports its saved brightness but drives the
// panel dimmer until the brightness changes. Re-assert it once a newly
// connected external screen has settled.
Item {
  id: root

  property var externalScreens: []

  function screenNames() {
    var screens = Quickshell.screens || []
    var names = []
    for (var i = 0; i < screens.length; i++) names.push(String(screens[i].name || ""))
    return names
  }

  function check() {
    var names = root.screenNames()
    var added = Model.addedExternalScreens(root.externalScreens, names)
    root.externalScreens = names
    if (added.length > 0) settle.restart()
  }

  Component.onCompleted: check()

  Connections {
    target: Quickshell
    function onScreensChanged() { root.check() }
  }

  // Long enough for hyprmoncfgd to apply its profile to the new screen first.
  Timer {
    id: settle
    interval: 3000
    onTriggered: reapply.running = true
  }

  Process {
    id: reapply
    command: ["maitri-brightness-display-apple", "--reapply"]
  }
}
