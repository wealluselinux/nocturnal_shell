import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
    id: root
    property bool active: true
    property real bgOpacity: 1.0
    property real moonOpacity: 0.0
    property real moonScale: 0.4

    IpcHandler {
        target: "splash"
        function play(): void {
            root.bgOpacity = 1.0
            root.moonOpacity = 0.0
            root.moonScale = 0.4
            root.active = true
            seq.restart()
        }
    }

    SequentialAnimation {
        id: seq
        running: true

        ParallelAnimation {
            NumberAnimation { target: root; property: "moonOpacity"; from: 0.0; to: 1.0; duration: 450; easing.type: Easing.OutCubic }
            NumberAnimation { target: root; property: "moonScale"; from: 0.4; to: 1.05; duration: 600; easing.type: Easing.OutBack }
        }

        PauseAnimation { duration: 350 }

        ParallelAnimation {
            NumberAnimation { target: root; property: "moonScale"; to: 3.2; duration: 550; easing.type: Easing.InCubic }
            NumberAnimation { target: root; property: "moonOpacity"; to: 0.0; duration: 450; easing.type: Easing.InCubic }
            NumberAnimation { target: root; property: "bgOpacity"; to: 0.0; duration: 550; easing.type: Easing.InOutCubic }
        }

        ScriptAction {
            script: root.active = false
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.active
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            mask: Region {}

            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                color: Theme.splashBg
                opacity: root.bgOpacity

                Column {
                    anchors.centerIn: parent
                    spacing: 16
                    scale: root.moonScale
                    opacity: root.moonOpacity

                    MoonLogo {
                        width: 128
                        height: 128
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Theme.lightMode ? "DAYLIGHT" : "NOCTURNAL"
                        color: Theme.accent
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 22
                        font.bold: true
                        font.letterSpacing: 6
                    }
                }
            }
        }
    }
}
