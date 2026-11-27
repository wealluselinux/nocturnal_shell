import Quickshell
import Quickshell.Hyprland
import QtQuick

Variants {
    model: Quickshell.screens

    PanelWindow {
        required property var modelData
        screen: modelData

        anchors {
            top: true
            left: true
            right: true
        }
        margins {
            top: 8
            left: 8
            right: 8
        }
        implicitHeight: 38
        color: "transparent"

        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }

        // Left side: workspaces + music player pill
        Row {
            anchors.left: parent.left
            spacing: 8

            Pill {
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
                            color: modelData.focused ? Theme.accent : "#55ffffff"

                            Behavior on width { NumberAnimation { duration: 120 } }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: modelData.activate()
                            }
                        }
                    }
                }
            }

            Music {}
        }

        // Center pill: date and time
        Pill {
            anchors.horizontalCenter: parent.horizontalCenter

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatDateTime(clock.date, "ddd d MMM  ·  h:mm AP")
                color: "#e6e1ff"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
            }
        }

        // Right side: separate pills for weather and volume
        Row {
            anchors.right: parent.right
            spacing: 8

            Pill {
                Weather {}
            }

            Pill {
                Volume {}
            }
        }
    }
}
