import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
    id: root
    property bool open: false
    property bool showKeyBar: false
    property bool loading: false
    property string provider: "gemini"
    property var messages: []
    property string helperPath: Quickshell.env("HOME") + "/nocturnal/bin/ai-ask"

    IpcHandler {
        target: "ai"
        function toggle(): void {
            root.open = !root.open
        }
    }

    Process {
        id: provProc
        command: [root.helperPath, "--get-provider"]
        stdout: StdioCollector {
            id: pCol
            onStreamFinished: {
                var p = pCol.text.trim()
                if (p) root.provider = p
            }
        }
    }

    Process {
        id: askProc
        stdout: StdioCollector {
            id: aCol
            onStreamFinished: {
                root.loading = false
                var reply = aCol.text.trim()
                if (!reply) reply = "(No response)"
                var next = root.messages.slice()
                next.push({ role: "assistant", text: reply })
                root.messages = next
                chatList.positionViewAtEnd()
            }
        }
    }

    function cycleProvider() {
        var order = ["groq", "gemini", "openai", "ollama"]
        var idx = (order.indexOf(root.provider) + 1) % order.length
        root.provider = order[idx]
        Quickshell.execDetached([root.helperPath, "--set-provider", root.provider])
    }

    function sendMessage(text) {
        var clean = text.trim()
        if (!clean || root.loading) return
        var next = root.messages.slice()
        next.push({ role: "user", text: clean })
        root.messages = next
        root.loading = true
        chatList.positionViewAtEnd()

        var payload = JSON.stringify({ messages: next.slice(-12) })
        askProc.command = ["sh", "-c", "printf '%s' " + JSON.stringify(payload) + " | \"" + root.helperPath + "\""]
        askProc.running = true
    }

    PanelWindow {
        id: win
        visible: root.open || card.opacity > 0.01
        focusable: true
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay

        anchors { top: true; left: true }
        margins { top: 52; left: 8 }
        implicitWidth: 390
        implicitHeight: 560
        color: "transparent"

        onVisibleChanged: {
            if (visible) {
                provProc.running = true
                promptInput.forceActiveFocus()
            }
        }

        Rectangle {
            id: card
            anchors.fill: parent
            radius: Theme.shapeRadius
            color: Theme.panelBg
            border.width: 1
            border.color: "#22ffffff"

            opacity: root.open ? 1 : 0
            transform: Translate { x: root.open ? 0 : -24 }
            Behavior on opacity { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                // Header
                Row {
                    width: parent.width
                    spacing: 8

                    Text {
                        text: "Nocturnal AI"
                        color: "#e6e1ff"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                        font.bold: true
                        width: parent.width - 170
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Rectangle {
                        width: 72
                        height: 28
                        radius: 8
                        color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22)
                        border.width: 1
                        border.color: Theme.accent
                        Text {
                            anchors.centerIn: parent
                            text: root.provider
                            color: Theme.accent
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.cycleProvider()
                        }
                    }

                    Rectangle {
                        width: 30
                        height: 28
                        radius: 8
                        color: root.showKeyBar ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25) : "#1affffff"
                        Text {
                            anchors.centerIn: parent
                            text: "\uf084"
                            color: "#e6e1ff"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.showKeyBar = !root.showKeyBar
                                if (root.showKeyBar) keyInput.forceActiveFocus()
                            }
                        }
                    }

                    Rectangle {
                        width: 44
                        height: 28
                        radius: 8
                        color: "#1affffff"
                        Text {
                            anchors.centerIn: parent
                            text: "Clear"
                            color: "#b8b3d6"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.messages = []
                        }
                    }
                }

                // API Key / Model Bar
                Row {
                    visible: root.showKeyBar
                    width: parent.width
                    spacing: 6

                    Rectangle {
                        width: parent.width - 62
                        height: 34
                        radius: 8
                        color: "#1affffff"
                        border.width: 1
                        border.color: Theme.accent

                        TextInput {
                            id: keyInput
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            verticalAlignment: TextInput.AlignVCenter
                            color: "#e6e1ff"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            echoMode: root.provider === "ollama" ? TextInput.Normal : TextInput.Password

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: root.provider === "ollama" ? "Ollama model (e.g. llama3.2)" : "Paste " + root.provider + " API key..."
                                color: "#66e6e1ff"
                                font: keyInput.font
                                visible: keyInput.text === ""
                            }
                        }
                    }

                    Rectangle {
                        width: 56
                        height: 34
                        radius: 8
                        color: Theme.accent
                        Text {
                            anchors.centerIn: parent
                            text: "Save"
                            color: "#12131a"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                Quickshell.execDetached([root.helperPath, "--set-key", root.provider, keyInput.text.trim()])
                                keyInput.text = ""
                                root.showKeyBar = false
                                promptInput.forceActiveFocus()
                            }
                        }
                    }
                }

                // Chat Messages
                Item {
                    width: parent.width
                    height: parent.height - (root.showKeyBar ? 132 : 88)

                    Text {
                        anchors.centerIn: parent
                        visible: root.messages.length === 0
                        text: "Ask anything...\nClick 🔑 to set your API key\nor click '" + root.provider + "' to switch."
                        horizontalAlignment: Text.AlignHCenter
                        color: "#66e6e1ff"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        lineHeight: 1.4
                    }

                    ListView {
                        id: chatList
                        anchors.fill: parent
                        clip: true
                        spacing: 8
                        model: root.messages

                        delegate: Rectangle {
                            required property var modelData
                            width: ListView.view.width
                            height: msgText.implicitHeight + 18
                            radius: 12
                            color: modelData.role === "user"
                                ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22)
                                : "#14ffffff"
                            border.width: modelData.role === "user" ? 1 : 0
                            border.color: Theme.accent

                            Text {
                                id: msgText
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 9
                                text: modelData.text
                                color: "#e6e1ff"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                                lineHeight: 1.35
                            }
                        }
                    }
                }

                // Input Bar
                Row {
                    width: parent.width
                    spacing: 8

                    Rectangle {
                        width: parent.width - 58
                        height: 38
                        radius: 10
                        color: "#1affffff"
                        border.width: 1
                        border.color: promptInput.activeFocus ? Theme.accent : "#22ffffff"

                        TextInput {
                            id: promptInput
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            verticalAlignment: TextInput.AlignVCenter
                            color: "#e6e1ff"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            clip: true

                            Keys.onEscapePressed: root.open = false
                            Keys.onReturnPressed: {
                                root.sendMessage(promptInput.text)
                                promptInput.text = ""
                            }

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: root.loading ? "Thinking..." : "Ask Nocturnal AI..."
                                color: "#66e6e1ff"
                                font: promptInput.font
                                visible: promptInput.text === ""
                            }
                        }
                    }

                    Rectangle {
                        width: 50
                        height: 38
                        radius: 10
                        color: Theme.accent
                        Text {
                            anchors.centerIn: parent
                            text: root.loading ? "..." : "\uf1d8"
                            color: "#12131a"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.sendMessage(promptInput.text)
                                promptInput.text = ""
                            }
                        }
                    }
                }
            }
        }
    }
}
