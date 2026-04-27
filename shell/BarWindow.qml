// BarWindow.qml - Main bar panel window
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

PanelWindow {
  id: barWindow
  required property var screenInfo
  required property var appController
  screen: screenInfo

  anchors {
    left: true
    right: true
    bottom: true
  }

  WlrLayershell.layer: WlrLayer.Top

  implicitHeight: 20
  color: "transparent"

  property var hyprlandMonitor: Hyprland.monitorFor(screen)

  property int textVerticalOffset: 1

  // Theme colors
  property color textColor: Qt.rgba(Theme.app600.r * 0.55, Theme.app600.g * 0.55, Theme.app600.b * 0.55, 1.0)
  property color iconColor: Qt.rgba(Theme.app600.r * 0.8, Theme.app600.g * 0.8, Theme.app600.b * 0.8, 1.0)
  property color wifiIconColor: Qt.rgba(Theme.app600.r * 0.9, Theme.app600.g * 0.9, Theme.app600.b * 0.9, 1.0)
  property color wifiSpeedColor: Qt.rgba(Theme.app600.r * 0.65, Theme.app600.g * 0.65, Theme.app600.b * 0.65, 1.0)
  property color wifiIpColor: Qt.rgba(Theme.app600.r * 0.45, Theme.app600.g * 0.45, Theme.app600.b * 0.45, 1.0)
  property color warningColor: "#FFA500"
  property color errorColor: Theme.error400
  property color chargingColor: Theme.success600
  property int skynetGap: 60
  property bool wifiWarningActive: WifiWidget.isHighTraffic


  Connections {
    target: WifiWidget
    function onIsHighTrafficChanged() {
      barWindow.wifiWarningActive = WifiWidget.isHighTraffic;
    }
  }

  Item {
    id: barContent
    anchors.fill: parent

    // Black fill across full bar
    Rectangle {
      anchors.fill: parent
      color: "#000000"
    }

    // SKYNET glow color (shifts toward wm800 on hover)
    property color glowColor: appLauncher.hovered
        ? Qt.rgba(Theme.wm800.r * 0.3 + Theme.app200.r * 0.7, Theme.wm800.g * 0.3 + Theme.app200.g * 0.7, Theme.wm800.b * 0.3 + Theme.app200.b * 0.7, 1.0)
        : Theme.app200
    property real glowAlpha: appLauncher.hovered ? 0.95 : 0.9

    Behavior on glowColor { ColorAnimation { duration: 150; easing.type: Easing.OutCubic } }

    // SKYNET horizontal outer glow (left)
    Item {
      x: centerSection.x - 60
      y: centerSection.y
      width: 60
      height: centerSection.height
      clip: true
      Rectangle {
        anchors.fill: parent
        gradient: Gradient {
          orientation: Gradient.Horizontal
          GradientStop { position: 0.0; color: Qt.rgba(barContent.glowColor.r, barContent.glowColor.g, barContent.glowColor.b, 0.0) }
          GradientStop { position: 1.0; color: Qt.rgba(barContent.glowColor.r, barContent.glowColor.g, barContent.glowColor.b, barContent.glowAlpha) }
        }
      }
      Image {
        anchors.fill: parent
        source: "assets/noise-tile.png"
        fillMode: Image.Tile
        opacity: 0.12
      }
      // Fade the noise with a matching gradient mask
      Rectangle {
        anchors.fill: parent
        gradient: Gradient {
          orientation: Gradient.Horizontal
          GradientStop { position: 0.0; color: "#000000" }
          GradientStop { position: 1.0; color: "transparent" }
        }
      }
    }
    // SKYNET horizontal outer glow (right)
    Item {
      x: centerSection.x + centerSection.width
      y: centerSection.y
      width: 60
      height: centerSection.height
      clip: true
      Rectangle {
        anchors.fill: parent
        gradient: Gradient {
          orientation: Gradient.Horizontal
          GradientStop { position: 0.0; color: Qt.rgba(barContent.glowColor.r, barContent.glowColor.g, barContent.glowColor.b, barContent.glowAlpha) }
          GradientStop { position: 1.0; color: Qt.rgba(barContent.glowColor.r, barContent.glowColor.g, barContent.glowColor.b, 0.0) }
        }
      }
      Item {
        anchors.fill: parent
        clip: true
        Image {
          x: -(centerSection.width % 64)
          y: 0
          width: parent.width + 64
          height: parent.height
          source: "assets/noise-tile.png"
          fillMode: Image.Tile
          opacity: 0.12
        }
      }
      // Fade the noise with a matching gradient mask
      Rectangle {
        anchors.fill: parent
        gradient: Gradient {
          orientation: Gradient.Horizontal
          GradientStop { position: 0.0; color: "transparent" }
          GradientStop { position: 1.0; color: "#000000" }
        }
      }
    }

    // CENTER - SKYNET logo
    Section {
      id: centerSection
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      width: appLauncher.width
      topPadding: 0; bottomPadding: 0; leftPadding: 0; rightPadding: 0
      topMargin: 0; bottomMargin: 0; leftMargin: 0; rightMargin: 0
      backgroundColor: Qt.rgba(Theme.app200.r, Theme.app200.g, Theme.app200.b, 0.2)
      showTopBorder: false
      glassEffect: true
      AppLauncherDisplay { id: appLauncher }
    }

    // SKYNET 1px black vertical borders
    Rectangle { x: centerSection.x; y: centerSection.y; width: 1; height: centerSection.height; color: "#000000" }
    Rectangle { x: centerSection.x + centerSection.width - 1; y: centerSection.y; width: 1; height: centerSection.height; color: "#000000" }

    // Noise overlay on SKYNET section
    Image {
      anchors.fill: centerSection
      source: "assets/noise-tile.png"
      fillMode: Image.Tile
      opacity: 0.15
    }

    // LEFT OF CENTER - dsk, mem, cpu
    Row {
      id: leftOfCenterRow
      anchors.right: centerSection.left
      anchors.rightMargin: barWindow.skynetGap + 8
      anchors.top: parent.top
      spacing: 0
      layoutDirection: Qt.RightToLeft

      // CPU
      Section {
        width: cpuText.implicitWidth + cpuBars.width + 12
        topPadding: 0; bottomPadding: 0
        backgroundColor: Qt.rgba(Theme.app200.r, Theme.app200.g, Theme.app200.b, 0.2)
        showTopBorder: false
        glassEffect: false

        Item {
          width: parent.width; height: 20

          Text {
            id: cpuText
            anchors.left: parent.left; anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: barWindow.textVerticalOffset
            text: "CPU " + Math.round(SystemMonitor.cpuUsage * 100)
            font.family: Theme.fontFamily; font.pointSize: Theme.fontSizeSmall; font.weight: Font.Bold
            color: SystemMonitor.cpuUsage > 0.8 ? barWindow.warningColor : barWindow.iconColor
          }

          Row {
            id: cpuBars
            anchors.right: parent.right; anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter; anchors.verticalCenterOffset: barWindow.textVerticalOffset
            height: 16; spacing: 1

            Repeater {
              model: Math.max(1, SystemMonitor.coreCount)
              Rectangle {
                width: 2
                anchors.bottom: parent.bottom
                height: Math.max(1, parent.height * Math.max(0, Math.min(1, SystemMonitor.coreUsages[index] || 0)))
                color: (SystemMonitor.coreUsages[index] || 0) > 0.8 ? barWindow.errorColor : barWindow.textColor
              }
            }
          }
        }
      }

      // MEMORY
      Section {
        width: memoryText.implicitWidth + 8
        topPadding: 0; bottomPadding: 0
        backgroundColor: Qt.rgba(Theme.app200.r, Theme.app200.g, Theme.app200.b, 0.2)
        showTopBorder: false
        glassEffect: false

        Item {
          width: parent.width; height: 20
          Text {
            id: memoryText
            anchors.centerIn: parent; anchors.verticalCenterOffset: barWindow.textVerticalOffset
            text: "MEM " + Math.round(SystemMonitor.memoryUsage * 100)
            font.family: Theme.fontFamily; font.pointSize: Theme.fontSizeSmall; font.weight: Font.Bold
            color: SystemMonitor.memoryUsage > 0.8 ? barWindow.warningColor : barWindow.iconColor
          }
        }
      }

      // DISK
      Section {
        width: diskText.implicitWidth + 8
        topPadding: 0; bottomPadding: 0
        backgroundColor: Qt.rgba(Theme.app200.r, Theme.app200.g, Theme.app200.b, 0.2)
        showTopBorder: false
        glassEffect: false

        Item {
          width: parent.width; height: 20
          Text {
            id: diskText
            anchors.centerIn: parent; anchors.verticalCenterOffset: barWindow.textVerticalOffset
            text: "DSK " + Math.round(SystemMonitor.diskUsage * 100)
            font.family: Theme.fontFamily; font.pointSize: Theme.fontSizeSmall; font.weight: Font.Bold
            color: SystemMonitor.diskUsage > 0.8 ? barWindow.warningColor : barWindow.iconColor
          }
        }
      }
    }

    // RIGHT OF CENTER - media
    Row {
      id: rightOfCenterRow
      anchors.left: centerSection.right
      anchors.leftMargin: barWindow.skynetGap
      anchors.top: parent.top
      spacing: 0

      Section {
        width: 270
        topPadding: 0; bottomPadding: 0; leftPadding: 1; rightPadding: 1
        backgroundColor: Qt.rgba(Theme.app200.r, Theme.app200.g, Theme.app200.b, 0.2)
        showTopBorder: false
        glassEffect: false
        clip: false

        MediaControlDisplay {
          width: 268
          textColor: barWindow.textColor
          iconColor: barWindow.iconColor
          textVerticalOffset: barWindow.textVerticalOffset
        }
      }
    }

    // LEFT - workspace, wifi
    Row {
      id: leftRow
      anchors.left: parent.left
      anchors.top: parent.top
      spacing: 0

      WorkspacesDisplay {
        monitor: hyprlandMonitor
        textVerticalOffset: barWindow.textVerticalOffset
      }

      Item { width: 6; height: 20 }

      // WIFI
      Section {
        id: wifiSection
        width: wifiDisplay.implicitWidth + 8
        topPadding: 0; bottomPadding: 0
        backgroundColor: Qt.rgba(Theme.app200.r, Theme.app200.g, Theme.app200.b, 0.2)
        showTopBorder: false
        glassEffect: false

        Item {
          width: wifiDisplay.implicitWidth; height: 20

          WifiDisplay {
            id: wifiDisplay
            anchors.centerIn: parent; anchors.verticalCenterOffset: barWindow.textVerticalOffset
            wifiIconColor: barWindow.wifiIconColor
            arrowIconColor: barWindow.iconColor
            speedColor: barWindow.wifiSpeedColor
            ipColor: barWindow.wifiIpColor
            ipHoverColor: barWindow.wifiIconColor
            warningColor: barWindow.warningColor
            wifiWarningActive: barWindow.wifiWarningActive
            textVerticalOffset: barWindow.textVerticalOffset
          }
        }
      }
    }

    // RIGHT - brt, vol, bat, clock
    Row {
      id: rightRow
      anchors.right: parent.right
      anchors.top: parent.top
      spacing: 0

      // BRIGHTNESS
      Section {
        width: brightnessText.implicitWidth + 8
        topPadding: 0; bottomPadding: 0
        backgroundColor: "#bda551"
        showTopBorder: false
        glassEffect: false

        Item {
          width: parent.width; height: 20

          Text {
            id: brightnessText
            anchors.centerIn: parent; anchors.verticalCenterOffset: barWindow.textVerticalOffset
            text: "BRT " + Math.round(BrightnessWidget.brightness * 100)
            font.family: Theme.fontFamily; font.pointSize: Theme.fontSizeSmall; font.weight: Font.Bold
            color: "#000000"
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onWheel: function(wheel) {
              const delta = wheel.angleDelta.y > 0 ? 0.01 : -0.01;
              BrightnessWidget.setBrightness(Math.max(0, Math.min(1, BrightnessWidget.brightness + delta)));
            }
          }
        }
      }

      // VOLUME
      Section {
        width: volumeText.implicitWidth + 8
        topPadding: 0; bottomPadding: 0
        backgroundColor: "#7493a3"
        showTopBorder: false
        glassEffect: false

        Item {
          width: parent.width; height: 20

          Text {
            id: volumeText
            anchors.centerIn: parent; anchors.verticalCenterOffset: barWindow.textVerticalOffset
            text: "VOL " + Math.round(VolumeWidget.volume * 100)
            font.family: Theme.fontFamily; font.pointSize: Theme.fontSizeSmall; font.weight: Font.Bold
            color: VolumeWidget.muted ? barWindow.warningColor : "#000000"
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: function(mouse) {
              if (mouse.button === Qt.RightButton) VolumeWidget.toggleMute();
            }
            onWheel: function(wheel) {
              const delta = wheel.angleDelta.y > 0 ? 0.01 : -0.01;
              VolumeWidget.setVolume(Math.max(0, Math.min(1, VolumeWidget.volume + delta)));
            }
          }
        }
      }

      // BATTERY
      Section {
        width: batteryText.implicitWidth + 8
        topPadding: 0; bottomPadding: 0
        backgroundColor: {
          if (!SystemMonitor.hasBattery) return barWindow.chargingColor;
          const colorState = SystemMonitor.getBatteryColorState();
          if (colorState === "charging") return barWindow.chargingColor;
          if (colorState === "critical") return barWindow.errorColor;
          return barWindow.warningColor;
        }
        showTopBorder: false
        glassEffect: false

        Item {
          width: parent.width; height: 20

          Text {
            id: batteryText
            anchors.centerIn: parent; anchors.verticalCenterOffset: barWindow.textVerticalOffset
            text: "BAT " + Math.round(SystemMonitor.batteryLevel * 100)
            font.family: Theme.fontFamily; font.pointSize: Theme.fontSizeSmall; font.weight: Font.Bold
            color: "#000000"
          }
        }
      }

      // CLOCK
      Section {
        width: clockText.implicitWidth + 14
        topPadding: 0; bottomPadding: 0
        leftPadding: 8; rightPadding: 6
        backgroundColor: Qt.rgba(Theme.app200.r, Theme.app200.g, Theme.app200.b, 0.2)
        showTopBorder: false
        glassEffect: false

        Item {
          width: parent.width; height: 20

          Text {
            id: clockText
            anchors.centerIn: parent; anchors.verticalCenterOffset: barWindow.textVerticalOffset
            text: Qt.formatDateTime(new Date(), "dd.MM. hh:mm:ss")
            font.family: Theme.fontFamily; font.pointSize: Theme.fontSizeSmall; font.weight: Font.Bold
            color: barWindow.textColor
          }

          Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: clockText.text = Qt.formatDateTime(new Date(), "dd.MM. hh:mm:ss")
          }

          MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              const iso = new Date().toISOString();
              Quickshell.execDetached(["sh", "-c", "echo -n '" + iso + "' | wl-copy && notify-send '\uD83D\uDD52 Timestamp copied!' '" + iso + " was copied to the clipboard'"]);
            }
          }
        }
      }
    }
  }
}
