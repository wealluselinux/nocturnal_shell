import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import QtQuick

Scope {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    property string weatherTemp: "--°F"
    property string weatherCond: "Weather"

    Process {
        id: wProc
        command: ["curl", "-s", "-m", "10", "wttr.in/?u&format=%t|%C"]
        stdout: StdioCollector {
            id: wCol
            onStreamFinished: {
                var p = wCol.text.trim().split("|")
                if (p.length >= 2 && p[0].indexOf("°") >= 0) {
                    root.weatherTemp = p[0].replace(/^\+/, "")
                    root.weatherCond = p[1]
                }
            }
        }
    }

    Timer {
        interval: 900000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: wProc.running = true
    }

    readonly property var player: {
        var list = Mpris.players.values
        for (var i = 0; i < list.length; i++) {
            if (list[i].isPlaying) return list[i]
        }
        return list.length > 0 ? list[0] : null
    }

    readonly property var calendarDays: {
        var now = clock.date
        var y = now.getFullYear()
        var m = now.getMonth()
        var today = now.getDate()
        var firstDay = new Date(y, m, 1).getDay()
        var daysInMonth = new Date(y, m + 1, 0).getDate()
        var cells = []
        for (var i = 0; i < firstDay; i++) cells.push({ d: "", isToday: false })
        for (var d = 1; d <= daysInMonth; d++) cells.push({ d: String(d), isToday: d === today })
        return cells
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: Theme.widgetsEnabled
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Bottom

            anchors {
                top: true
                left: true
            }
            margins {
                top: 56
                left: 12
            }
            implicitWidth: 386
            implicitHeight: 356
            color: "transparent"

            Row {
                anchors.fill: parent
                spacing: 10

                // LEFT CARD: Digital Clock + Weather + Month Calendar
                Rectangle {
                    width: 216
                    height: 356
                    radius: 16
                    color: Theme.panelBg
                    border.width: 1
                    border.color: "#22ffffff"

                    Column {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 10

                        Row {
                            width: parent.width
                            spacing: 10

                            Text {
                                text: Qt.formatDateTime(clock.date, "hh:mm")
                                color: "#e6e1ff"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 28
                                font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                Text {
                                    text: root.weatherTemp
                                    color: Theme.accent
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                    font.bold: true
                                }
                                Text {
                                    text: root.weatherCond
                                    color: "#99e6e1ff"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                    width: 78
                                }
                            }
                        }

                        Text {
                            text: Qt.formatDateTime(clock.date, "dddd, MMM d")
                            color: "#b8b3d6"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: "#22ffffff"
                        }

                        Grid {
                            width: parent.width
                            columns: 7
                            rowSpacing: 4
                            Repeater {
                                model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
                                Text {
                                    required property string modelData
                                    width: 26
                                    horizontalAlignment: Text.AlignHCenter
                                    text: modelData
                                    color: "#88e6e1ff"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }
                        }

                        Grid {
                            width: parent.width
                            columns: 7
                            rowSpacing: 4
                            Repeater {
                                model: root.calendarDays
                                Rectangle {
                                    required property var modelData
                                    width: 26
                                    height: 24
                                    radius: 6
                                    color: modelData.isToday ? Theme.accent : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.d
                                        color: modelData.isToday ? "#12131a" : "#e6e1ff"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 11
                                        font.bold: modelData.isToday
                                    }
                                }
                            }
                        }
                    }
                }

                // RIGHT COLUMN: Analog Clock + Now Playing
                Column {
                    width: 160
                    height: 356
                    spacing: 10

                    Rectangle {
                        width: 160
                        height: 160
                        radius: 16
                        color: Theme.panelBg
                        border.width: 1
                        border.color: "#22ffffff"

                        Item {
                            anchors.centerIn: parent
                            width: 124
                            height: 124

                            Rectangle {
                                anchors.fill: parent
                                radius: 62
                                color: "transparent"
                                border.width: 2
                                border.color: "#33ffffff"
                            }

                            Repeater {
                                model: 12
                                Item {
                                    required property int index
                                    anchors.fill: parent
                                    rotation: index * 30
                                    Rectangle {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.top: parent.top
                                        anchors.topMargin: 5
                                        width: index % 3 === 0 ? 2 : 1
                                        height: index % 3 === 0 ? 8 : 5
                                        color: index % 3 === 0 ? Theme.accent : "#66e6e1ff"
                                    }
                                }
                            }

                            Item {
                                anchors.fill: parent
                                rotation: (clock.date.getHours() % 12) * 30 + clock.date.getMinutes() * 0.5
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.verticalCenter
                                    width: 3
                                    height: 32
                                    radius: 2
                                    color: "#e6e1ff"
                                }
                            }

                            Item {
                                anchors.fill: parent
                                rotation: clock.date.getMinutes() * 6
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.verticalCenter
                                    width: 2
                                    height: 44
                                    radius: 1
                                    color: "#e6e1ff"
                                }
                            }

                            Item {
                                anchors.fill: parent
                                rotation: clock.date.getSeconds() * 6
                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.verticalCenter
                                    width: 1.5
                                    height: 48
                                    color: Theme.accent
                                }
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: 7
                                height: 7
                                radius: 4
                                color: Theme.accent
                            }
                        }
                    }

                    Rectangle {
                        width: 160
                        height: 186
                        radius: 16
                        color: Theme.panelBg
                        border.width: 1
                        border.color: "#22ffffff"

                        Column {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            Rectangle {
                                width: 76
                                height: 76
                                radius: 10
                                color: "#1affffff"
                                clip: true
                                anchors.horizontalCenter: parent.horizontalCenter

                                Image {
                                    anchors.fill: parent
                                    source: root.player && root.player.trackArtUrl ? root.player.trackArtUrl : ""
                                    fillMode: Image.PreserveAspectCrop
                                    visible: source !== ""
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "\uf001"
                                    color: "#66e6e1ff"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 22
                                    visible: !root.player || !root.player.trackArtUrl
                                }
                            }

                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: root.player && root.player.trackTitle ? root.player.trackTitle : "Nothing playing"
                                color: "#e6e1ff"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: root.player && root.player.trackArtist ? root.player.trackArtist : ""
                                color: "#88e6e1ff"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 14

                                Text {
                                    text: "\uf048"
                                    color: "#b8b3d6"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                    anchors.verticalCenter: parent.verticalCenter
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: if (root.player && root.player.canGoPrevious) root.player.previous()
                                    }
                                }

                                Rectangle {
                                    width: 30
                                    height: 30
                                    radius: 8
                                    color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25)
                                    Text {
                                        anchors.centerIn: parent
                                        text: root.player && root.player.isPlaying ? "\uf04c" : "\uf04b"
                                        color: Theme.accent
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 13
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: if (root.player && root.player.canTogglePlaying) root.player.togglePlaying()
                                    }
                                }

                                Text {
                                    text: "\uf051"
                                    color: "#b8b3d6"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                    anchors.verticalCenter: parent.verticalCenter
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: if (root.player && root.player.canGoNext) root.player.next()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
