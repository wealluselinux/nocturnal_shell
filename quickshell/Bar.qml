import Quickshell
import Quickshell.Hyprland
import QtQuick

Variants {
    model: Quickshell.screens

    PanelWindow {
        required property var modelData
        screen: modelData

        anchors { top: true }
        margins { top: 8 }
        implicitWidth: Math.round(modelData.width * 0.5)
        implicitHeight: 38
        color: "transparent"

        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }

        // Left pill: workspaces
        Pill {
            anchors.left: parent.left

            Row {
                spacing: 6
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: Hyprland.workspaces

                    Rectangle {
                        required property var modelData
                        width: modelData.focused ? 28 : 10
                        height: 10
                        radius: 5
                        color: modelData.focused ? "#c9b8ff" : "#55ffffff"

                        Behavior on width { NumberAnimation { duration: 120 } }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: modelData.activate()
                        }
                    }
                }
            }
        }

        // Center pill: date and time
        Pill {
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDateTime(clock.date, "ddd d MMM  ·  h:mm AP")
                color: "#e6e1ff"
                font.family: "Google Sans Flex"
                font.pixelSize: 15
            }
        }

        // Right pill: widgets (weather now, volume and more next)
        Pill {
            anchors.right: parent.right

            Weather {}
            Volume {}
        }
    }
}
