import Quickshell
import Quickshell.Widgets
import QtQuick

PanelWindow {
    id: dock
    visible: Theme.dockEnabled
    exclusionMode: ExclusionMode.Ignore

    anchors {
        bottom: true
        left: Theme.dockPosition === "left"
        right: Theme.dockPosition === "right"
    }
    margins {
        bottom: 8
        left: 8
        right: 8
    }

    implicitWidth: Math.max(160, dockRow.implicitWidth + 24)
    implicitHeight: 54
    color: "transparent"

    readonly property var dockApps: {
        var all = DesktopEntries.applications.values
        var result = []
        for (var i = 0; i < Theme.pinnedIds.length; i++) {
            var id = Theme.pinnedIds[i]
            for (var j = 0; j < all.length; j++) {
                if (all[j].id === id) {
                    result.push(all[j])
                    break
                }
            }
        }
        return result
    }

    Rectangle {
        anchors.fill: parent
        radius: 18
        color: "#cc12131a"
        border.width: 1
        border.color: "#22ffffff"

        Text {
            anchors.centerIn: parent
            visible: dock.dockApps.length === 0
            text: "Pin apps in Launcher"
            color: "#66e6e1ff"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
        }

        Row {
            id: dockRow
            anchors.centerIn: parent
            spacing: 8
            visible: dock.dockApps.length > 0

            Repeater {
                model: dock.dockApps

                Rectangle {
                    required property var modelData
                    width: 40
                    height: 40
                    radius: 12
                    color: dMouse.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25) : "transparent"
                    border.width: dMouse.containsMouse ? 1 : 0
                    border.color: Theme.accent
                    scale: dMouse.containsMouse ? 1.12 : 1.0

                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                    IconImage {
                        anchors.centerIn: parent
                        implicitSize: 28
                        source: Quickshell.iconPath(modelData.icon, true)
                    }

                    MouseArea {
                        id: dMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: modelData.execute()
                    }
                }
            }
        }
    }
}
