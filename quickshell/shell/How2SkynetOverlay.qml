import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
  id: overlay
  required property var screenInfo
  screen: screenInfo

  visible: How2SkynetWidget.visible

  WlrLayershell.layer: WlrLayer.Top
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  color: "transparent"

  Item {
    anchors.fill: parent
    anchors.bottomMargin: 20
    clip: true

    Image {
      width: parent.width
      height: parent.height + 20
      source: "how2skynet.png"
      fillMode: Image.PreserveAspectFit
    }
  }

  MouseArea {
    anchors.fill: parent
    focus: true
    onClicked: How2SkynetWidget.hide()
    Keys.onEscapePressed: How2SkynetWidget.hide()
  }
}
