import QtQuick
import qs.Ui

// The brand glyph in the bar. Left-click opens the Vicinae launcher, middle-click
// the maitri menu, right-click a terminal.
BarWidget {
  id: root
  moduleName: "maitri.launcher"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: ""
    fontFamily: "maitri"
    horizontalMargin: 7.5
    tooltipText: "Launcher"
    onPressed: function(button) {
      if (!root.bar) return
      if (button === Qt.RightButton) root.bar.run("xdg-terminal-exec")
      else if (button === Qt.MiddleButton) root.bar.run("maitri-menu toggle root")
      else root.bar.run("maitri-launch-vicinae")
    }
  }
}
