import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
    id: root
    property bool open: false
    property var items: []

    IpcHandler {
        target: "clipboard"
        function toggle(): void {
            root.open = !root.open
        }
    }

    Process {
        id: readProc
        command: ["sh", "-c", "cat \"$HOME/.cache/nocturnal/clipboard.txt\" 2>/dev/null"]
        stdout: StdioCollector {
            id: col
            onStreamFinished: {
                var lines = col.text.split("\n").filter(l => l.length > 0)
                root.items = lines
            }
        }
    }

    PanelWindow {
        id: win
        visible: root.open || card.opacity > 0.01
        focusable: true
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay

        anchors { bottom: true; right: true }
        margins { bottom: 18; right: 8 }
        implicitWidth: 360
        implicitHeight: 390
        color: "transparent"

        onVisibleChanged: {
            if (visible) {
                search.text = ""
                readProc.running = true
                search.forceActiveFocus()
            }
        }

        readonly property var filtered: {
            var q = search.text.trim().toLowerCase()
            if (q === "") return root.items
            return root.items.filter(s => s.toLowerCase().indexOf(q) >= 0)
        }

        Rectangle {
            id: card
            anchors.fill: parent
            radius: Theme.shapeRadius
            color: Theme.panelBg
            border.width: 1
            border.color: "#22ffffff"

            opacity: root.open ? 1 : 0
            transform: Translate { y: root.open ? 0 : 18 }
            Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Row {
                    width: parent.width
                    spacing: 8

                    Rectangle {
                        width: parent.width - 62
                        height: 36
                        radius: 10
                        color: "#1affffff"
                        border.width: 1
                        border.color: search.activeFocus ? Theme.accent : "#22ffffff"

                        TextInput {
                            id: search
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            verticalAlignment: TextInput.AlignVCenter
                            color: "#e6e1ff"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            Keys.onEscapePressed: root.open = false

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "Search clipboard..."
                                color: "#66e6e1ff"
                                font: search.font
                                visible: search.text === ""
                            }
                        }
                    }

                    Rectangle {
                        width: 54
                        height: 36
                        radius: 10
                        color: clrMouse.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : "#1affffff"
                        Text {
                            anchors.centerIn: parent
                            text: "Clear"
                            color: "#e6e1ff"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                        }
                        MouseArea {
                            id: clrMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                root.items = []
                                Quickshell.execDetached(["sh", "-c", ": > \"$HOME/.cache/nocturnal/clipboard.txt\""])
                            }
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: parent.height - 46

                    Text {
                        anchors.centerIn: parent
                        visible: win.filtered.length === 0
                        text: "Clipboard is empty"
                        color: "#66e6e1ff"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                    }

                    ListView {
                        anchors.fill: parent
                        clip: true
                        spacing: 4
                        model: win.filtered

                        delegate: Rectangle {
                            required property string modelData
                            width: ListView.view.width
                            height: 40
                            radius: 10
                            color: cMouse.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : "#0dffffff"

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                text: modelData
                                color: "#e6e1ff"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }

                            MouseArea {
                                id: cMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    Quickshell.execDetached(["wl-copy", modelData])
                                    root.open = false
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
