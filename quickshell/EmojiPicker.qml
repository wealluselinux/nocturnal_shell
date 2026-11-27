import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
    id: root
    property bool open: false

    readonly property var emojis: [
        { e: "😀", k: "grin smile happy" }, { e: "😂", k: "laugh lol joy cry" },
        { e: "🥹", k: "tears happy emotional" }, { e: "😊", k: "blush smile warm" },
        { e: "😎", k: "cool sunglasses" }, { e: "🥳", k: "party celebrate" },
        { e: "🤩", k: "star eyes wow" }, { e: "😍", k: "heart eyes love" },
        { e: "🥰", k: "love hearts" }, { e: "😘", k: "kiss love" },
        { e: "🤔", k: "think hmm" }, { e: "🤨", k: "skeptical eyebrow" },
        { e: "😐", k: "neutral meh" }, { e: "😑", k: "blank expressionless" },
        { e: "🙄", k: "eyeroll" }, { e: "😴", k: "sleep tired zzz" },
        { e: "🤯", k: "mindblown explode" }, { e: "😱", k: "shock scream" },
        { e: "😭", k: "cry sad sob" }, { e: "😤", k: "angry huff" },
        { e: "😡", k: "mad angry" }, { e: "🤬", k: "curse angry" },
        { e: "💀", k: "skull dead" }, { e: "👻", k: "ghost spooky" },
        { e: "👽", k: "alien ufo" }, { e: "🤖", k: "robot bot ai" },
        { e: "👍", k: "thumbs up yes good" }, { e: "👎", k: "thumbs down no bad" },
        { e: "👏", k: "clap bravo" }, { e: "🙌", k: "hands celebrate" },
        { e: "🙏", k: "pray please thanks" }, { e: "🤝", k: "handshake deal" },
        { e: "✌️", k: "peace victory" }, { e: "🤞", k: "fingers crossed luck" },
        { e: "🫶", k: "heart hands love" }, { e: "💪", k: "muscle strong" },
        { e: "❤️", k: "red heart love" }, { e: "💜", k: "purple heart" },
        { e: "💙", k: "blue heart" }, { e: "💚", k: "green heart" },
        { e: "🖤", k: "black heart" }, { e: "💔", k: "broken heart" },
        { e: "🔥", k: "fire lit hot" }, { e: "✨", k: "sparkles magic stars" },
        { e: "⭐", k: "star" }, { e: "⚡", k: "lightning bolt fast" },
        { e: "💥", k: "boom explosion" }, { e: "💯", k: "100 percent" },
        { e: "🎉", k: "party confetti" }, { e: "🚀", k: "rocket launch" },
        { e: "🎵", k: "music note" }, { e: "🎧", k: "headphones music" },
        { e: "💻", k: "laptop code computer" }, { e: "🐧", k: "linux penguin" },
        { e: "🌙", k: "moon night nocturnal" }, { e: "☀️", k: "sun day" },
        { e: "🌧️", k: "rain weather" }, { e: "❄️", k: "snow cold" },
        { e: "☕", k: "coffee tea" }, { e: "🍕", k: "pizza food" },
        { e: "✅", k: "check done yes" }, { e: "❌", k: "cross no error" },
        { e: "⚠️", k: "warning alert" }, { e: "📌", k: "pin" }
    ]

    IpcHandler {
        target: "emoji"
        function toggle(): void {
            root.open = !root.open
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
        implicitWidth: 340
        implicitHeight: 360
        color: "transparent"

        onVisibleChanged: {
            if (visible) {
                search.text = ""
                search.forceActiveFocus()
            }
        }

        readonly property var filtered: {
            var q = search.text.trim().toLowerCase()
            if (q === "") return root.emojis
            return root.emojis.filter(item => item.k.indexOf(q) >= 0 || item.e === q)
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

                Rectangle {
                    width: parent.width
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
                            text: "Search emojis..."
                            color: "#66e6e1ff"
                            font: search.font
                            visible: search.text === ""
                        }
                    }
                }

                GridView {
                    width: parent.width
                    height: parent.height - 46
                    cellWidth: 44
                    cellHeight: 44
                    clip: true
                    model: win.filtered

                    delegate: Rectangle {
                        required property var modelData
                        width: 40
                        height: 40
                        radius: 10
                        color: eMouse.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25) : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: modelData.e
                            font.pixelSize: 22
                        }

                        MouseArea {
                            id: eMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                Quickshell.execDetached(["wl-copy", modelData.e])
                                root.open = false
                            }
                        }
                    }
                }
            }
        }
    }
}
