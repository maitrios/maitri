import QtQuick
import qs.Ui

BarWidget {
  id: root
  moduleName: "maitri.menu"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "\ue900"
    fontFamily: "maitri"
    horizontalMargin: 7.5
    onPressed: function(button) {
      if (!root.bar) return
      if (button === Qt.RightButton) root.bar.run("xdg-terminal-exec")
      else root.bar.run("maitri-shell shell toggle maitri.menu '{\"menu\":\"root\"}'")
    }
  }
}
