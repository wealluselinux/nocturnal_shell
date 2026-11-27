import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick

Scope {
    id: root
    property var dockApps: []

    function rebuildDock() {
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
        root.dockApps = result
    }

    Component.onCompleted: rebuildDock()

    Connections {
        target: Theme
        function onPinnedIdsChanged() { root.rebuildDock() }
    }

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { root.rebuildDock() }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: dockWin
            required property var modelData
            screen: modelData
            visible: Theme.dockEnabled
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Top

            anchors {
                bottom: true
                left: Theme.dockPosition === "left"
                right: Theme.dockPosition === "right"
            }
            margins {
                bottom: 18
                left: 8
                right: 8
            }

            implicitWidth: Math.max(160, dockRow.implicitWidth + 24)
            implicitHeight: 54
            color: "transparent"

            Item {
                anchors.fill: parent
                HoverHandler { id: dockHover }

                Rectangle {
                    anchors.fill: parent
                    radius: Math.min(height / 2, Theme.shapeRadius)
                    color: Theme.panelBg
                    border.width: 1
                    border.color: "#22ffffff"

                    transform: Translate {
                        y: (Theme.dockAutoHide && !dockHover.hovered) ? 60 : 0
                        Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    }
                    opacity: (Theme.dockAutoHide && !dockHover.hovered) ? 0.12 : 1.0
                    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                    Text {
                        anchors.centerIn: parent
                        visible: root.dockApps.length === 0
                        text: "Pin apps in Launcher"
                        color: "#66e6e1ff"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                    }

                    Row {
                        id: dockRow
                        anchors.centerIn: parent
                        spacing: 8
                        visible: root.dockApps.length > 0

                        Repeater {
                            model: root.dockApps

                            Rectangle {
                                required property var modelData
                                width: 40
                                height: 40
                                radius: Math.min(12, Theme.shapeRadius)
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
        }
    }
}
