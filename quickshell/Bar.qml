import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import QtQuick

Variants {
    model: Quickshell.screens

    PanelWindow {
        id: barWin
        required property var modelData
        screen: modelData

        readonly property bool vertical: Theme.barPosition === "left" || Theme.barPosition === "right"

        anchors {
            top: !vertical ? (Theme.barPosition === "top") : true
            bottom: !vertical ? (Theme.barPosition === "bottom") : true
            left: vertical ? (Theme.barPosition === "left") : true
            right: vertical ? (Theme.barPosition === "right") : true
        }
        margins {
            top: 8
            bottom: 8
            left: 8
            right: 8
        }
        implicitWidth: vertical ? 44 : 100
        implicitHeight: vertical ? 100 : 36
        color: "transparent"

        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }

        QuickSettings {
            id: quickSettings
            targetScreen: modelData
        }

        property string wifi: "Off"
        property string cpu: "0%"
        property string ram: "0G"
        property string bat: ""
        property bool charging: false

        Process {
            id: statsProc
            command: ["sh", "-c",
                "w=$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | grep '^yes:' | head -1 | cut -d: -f2); " +
                "[ -z \"$w\" ] && w='Off'; " +
                "c=$(grep -m1 'cpu ' /proc/stat | awk '{u=$2+$4; t=$2+$4+$5; if(t>0) printf \"%d%%\", u*100/t; else print \"0%\"}'); " +
                "r=$(free -m | awk '/Mem:/ {printf \"%.1fG\", $3/1024}'); " +
                "b=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1); " +
                "s=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1); " +
                "echo \"$w|$c|$r|$b|$s\""
            ]
            stdout: StdioCollector {
                id: sCol
                onStreamFinished: {
                    var p = sCol.text.trim().split("|")
                    if (p.length >= 5) {
                        barWin.wifi = p[0]
                        barWin.cpu = p[1]
                        barWin.ram = p[2]
                        barWin.bat = p[3]
                        barWin.charging = (p[4] === "Charging")
                    }
                }
            }
        }

        Timer {
            interval: 3000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: statsProc.running = true
        }

        PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
        readonly property var sink: Pipewire.defaultAudioSink
        readonly property bool audioReady: sink !== null && sink.audio !== null
        readonly property real vol: audioReady ? sink.audio.volume : 0
        readonly property bool muted: audioReady ? sink.audio.muted : false

        // ==================== HORIZONTAL BAR (TOP / BOTTOM) ====================
        Item {
            visible: !barWin.vertical
            anchors.fill: parent

            Row {
                anchors.left: parent.left
                spacing: 6

                Pill {
                    Item {
                        implicitWidth: aiIcon.implicitWidth
                        implicitHeight: aiIcon.implicitHeight
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            id: aiIcon
                            text: "\uf0eb"
                            color: Theme.accent
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 15
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: Quickshell.execDetached(["quickshell", "ipc", "-p", Quickshell.env("HOME") + "/nocturnal/quickshell/shell.qml", "call", "ai", "toggle"])
                        }
                    }
                }

                Pill {
                    Row {
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter
                        Repeater {
                            model: Hyprland.workspaces
                            Rectangle {
                                required property var modelData
                                width: 24; height: 24; radius: 6
                                color: modelData.focused ? Theme.accent : "#1affffff"
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.id
                                    color: modelData.focused ? "#12131a" : "#e6e1ff"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 12
                                    font.bold: modelData.focused
                                }
                                MouseArea { anchors.fill: parent; onClicked: modelData.activate() }
                            }
                        }
                    }
                }

                Music {}
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6

                Pill {
                    Item {
                        implicitWidth: clockText.implicitWidth
                        implicitHeight: clockText.implicitHeight
                        anchors.verticalCenter: parent.verticalCenter
                        Text {
                            id: clockText
                            text: Qt.formatDateTime(clock.date, "h:mm AP  ·  ddd d MMM")
                            color: "#e6e1ff"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            font.bold: true
                        }
                        MouseArea { anchors.fill: parent; onClicked: quickSettings.open = !quickSettings.open }
                    }
                }

                Pill { Weather {} }
            }

            Row {
                anchors.right: parent.right
                spacing: 6

                Repeater {
                    model: Theme.rightPillOrder
                    Pill {
                        id: rPill
                        required property string modelData
                        required property int index
                        visible: modelData !== "battery" || barWin.bat !== ""
                        border.color: dragArea.holding ? Theme.accent : "#22ffffff"
                        border.width: dragArea.holding ? 2 : 1

                        Item {
                            implicitWidth: pillLabel.implicitWidth
                            implicitHeight: pillLabel.implicitHeight
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                id: pillLabel
                                text: {
                                    if (rPill.modelData === "wifi")    return "\uf1eb  " + barWin.wifi
                                    if (rPill.modelData === "stats")   return "\uf4bc " + barWin.cpu + "  \uf2db " + barWin.ram
                                    if (rPill.modelData === "battery") return (barWin.charging ? "\uf0e7 " : "\uf240 ") + barWin.bat + "%"
                                    return (barWin.muted ? "\uf026  " : "\uf028  ") + Math.round(barWin.vol * 100) + "%"
                                }
                                color: {
                                    if (rPill.modelData === "wifi" && barWin.wifi === "Off") return "#88e6e1ff"
                                    if (rPill.modelData === "battery" && barWin.charging) return Theme.accent
                                    if (rPill.modelData === "volume" && barWin.muted) return "#88e6e1ff"
                                    return "#e6e1ff"
                                }
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                                elide: Text.ElideRight
                                width: rPill.modelData === "wifi" ? Math.min(implicitWidth, 120) : implicitWidth
                            }
                            MouseArea {
                                id: dragArea
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                property bool holding: false
                                property bool didHold: false
                                property real startX: 0
                                onPressed: (mouse) => { didHold = false }
                                onPressAndHold: (mouse) => { didHold = true; holding = true; startX = mouse.x }
                                onPositionChanged: (mouse) => {
                                    if (!holding) return
                                    if (mouse.x - startX > 36) { Theme.moveRightPill(rPill.index, 1); startX = mouse.x }
                                    else if (startX - mouse.x > 36) { Theme.moveRightPill(rPill.index, -1); startX = mouse.x }
                                }
                                onReleased: holding = false
                                onClicked: (mouse) => {
                                    if (didHold) { didHold = false; return }
                                    if (mouse.button === Qt.RightButton && rPill.modelData === "volume") {
                                        if (barWin.audioReady) barWin.sink.audio.muted = !barWin.sink.audio.muted
                                    } else {
                                        Quickshell.execDetached(["quickshell", "ipc", "-p", Quickshell.env("HOME") + "/nocturnal/quickshell/shell.qml", "call", "rightsidebar", "toggle"])
                                    }
                                }
                                onWheel: (wheel) => {
                                    if (rPill.modelData !== "volume" || !barWin.audioReady) return
                                    var step = wheel.angleDelta.y > 0 ? 0.05 : -0.05
                                    barWin.sink.audio.volume = Math.max(0, Math.min(1, barWin.vol + step))
                                }
                            }
                        }
                    }
                }
            }
        }

        // ==================== VERTICAL BAR (LEFT / RIGHT) ====================
        Item {
            visible: barWin.vertical
            anchors.fill: parent

            // Top: AI + Workspaces
            Column {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                Rectangle {
                    width: 40; height: 40; radius: 10
                    color: Theme.panelBg; border.width: 1; border.color: "#22ffffff"
                    Text { anchors.centerIn: parent; text: "\uf0eb"; color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16 }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: Quickshell.execDetached(["quickshell", "ipc", "-p", Quickshell.env("HOME") + "/nocturnal/quickshell/shell.qml", "call", "ai", "toggle"])
                    }
                }

                Rectangle {
                    width: 40
                    height: wsCol.implicitHeight + 16
                    radius: 10
                    color: Theme.panelBg; border.width: 1; border.color: "#22ffffff"

                    Column {
                        id: wsCol
                        anchors.centerIn: parent
                        spacing: 4
                        Repeater {
                            model: Hyprland.workspaces
                            Rectangle {
                                required property var modelData
                                width: 26; height: 26; radius: 6
                                color: modelData.focused ? Theme.accent : "#1affffff"
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.id
                                    color: modelData.focused ? "#12131a" : "#e6e1ff"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 12
                                    font.bold: modelData.focused
                                }
                                MouseArea { anchors.fill: parent; onClicked: modelData.activate() }
                            }
                        }
                    }
                }
            }

            // Center: Stacked HH / mm clock (opens Dashboard)
            Rectangle {
                anchors.centerIn: parent
                width: 40; height: 64; radius: 10
                color: Theme.panelBg; border.width: 1; border.color: "#22ffffff"

                Column {
                    anchors.centerIn: parent
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(clock.date, "HH")
                        color: "#e6e1ff"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                        font.bold: true
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(clock.date, "mm")
                        color: Theme.accent
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                        font.bold: true
                    }
                }
                MouseArea { anchors.fill: parent; onClicked: quickSettings.open = !quickSettings.open }
            }

            // Bottom: Compact Wi-Fi, Battery, Volume (opens Right Sidebar)
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: 40
                height: vStatCol.implicitHeight + 16
                radius: 10
                color: Theme.panelBg; border.width: 1; border.color: "#22ffffff"

                Column {
                    id: vStatCol
                    anchors.centerIn: parent
                    spacing: 10

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "\uf1eb"
                        color: barWin.wifi === "Off" ? "#66e6e1ff" : "#e6e1ff"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                    }
                    Text {
                        visible: barWin.bat !== ""
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: barWin.bat + "%"
                        color: barWin.charging ? Theme.accent : "#e6e1ff"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        font.bold: true
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: barWin.muted ? "\uf026" : "\uf028"
                        color: barWin.muted ? "#66e6e1ff" : Theme.accent
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: Quickshell.execDetached(["quickshell", "ipc", "-p", Quickshell.env("HOME") + "/nocturnal/quickshell/shell.qml", "call", "rightsidebar", "toggle"])
                    onWheel: (wheel) => {
                        if (!barWin.audioReady) return
                        var step = wheel.angleDelta.y > 0 ? 0.05 : -0.05
                        barWin.sink.audio.volume = Math.max(0, Math.min(1, barWin.vol + step))
                    }
                }
            }
        }
    }
}
