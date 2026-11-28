import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import QtQuick

Scope {
    id: root

    SystemClock { id: clock; precision: SystemClock.Seconds }

    property string weatherTemp: "--°F"
    property string weatherCond: "Weather"
    property var photoList: []
    property int photoIdx: 0
    property int quoteIdx: 0

    readonly property var quotes: [
        { q: "The night is more alive and more richly colored than the day.", a: "Vincent van Gogh" },
        { q: "Simplicity is the ultimate sophistication.", a: "Leonardo da Vinci" },
        { q: "Stars can't shine without darkness.", a: "D.H. Sidebottom" },
        { q: "Talk is cheap. Show me the code.", a: "Linus Torvalds" },
        { q: "Even the darkest night will end and the sun will rise.", a: "Victor Hugo" },
        { q: "Make it work, make it right, make it fast.", a: "Kent Beck" }
    ]

    Process {
        id: wProc
        command: ["curl", "-s", "-m", "5", "wttr.in/?u&format=%t|%C"]
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
    Timer { interval: 900000; running: true; repeat: true; triggeredOnStart: true; onTriggered: wProc.running = true }

    Process {
        id: photoListProc
        command: ["sh", "-c", "find \"$HOME/Pictures\" \"$HOME/nocturnal/wallpapers\" -maxdepth 2 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\) 2>/dev/null | sort"]
        stdout: StdioCollector {
            id: pCol
            onStreamFinished: {
                var lines = pCol.text.trim().split("\n").filter(l => l.length > 0)
                if (lines.length > 0) root.photoList = lines
            }
        }
    }
    Component.onCompleted: photoListProc.running = true

    Process {
        id: pickPhotoProc
        command: ["sh", "-c", "if command -v kdialog >/dev/null 2>&1; then QT_QPA_PLATFORMTHEME=kde kdialog --getopenfilename \"$HOME/Pictures\" \"Images (*.png *.jpg *.jpeg *.webp)\"; elif command -v zenity >/dev/null 2>&1; then zenity --file-selection --file-filter=\"Images | *.png *.jpg *.jpeg *.webp\"; fi"]
        stdout: StdioCollector {
            id: pickCol
            onStreamFinished: {
                var chosen = pickCol.text.trim()
                if (chosen.length > 0) {
                    Theme.widgetPhotoPath = chosen
                    Theme.save()
                }
            }
        }
    }

    readonly property var player: {
        var list = Mpris.players.values
        for (var i = 0; i < list.length; i++) if (list[i].isPlaying) return list[i]
        return list.length > 0 ? list[0] : null
    }

    readonly property var calendarDays: {
        var now = clock.date
        var y = now.getFullYear(), m = now.getMonth(), today = now.getDate()
        var firstDay = new Date(y, m, 1).getDay()
        var daysInMonth = new Date(y, m + 1, 0).getDate()
        var cells = []
        for (var i = 0; i < firstDay; i++) cells.push({ d: "", isToday: false })
        for (var d = 1; d <= daysInMonth; d++) cells.push({ d: String(d), isToday: d === today })
        return cells
    }

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool audioReady: sink !== null && sink.audio !== null
    readonly property real vol: audioReady ? sink.audio.volume : 0
    readonly property bool muted: audioReady ? sink.audio.muted : false
    readonly property var outputs: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream)
    PwObjectTracker { objects: root.outputs }

    function setVolume(v) { if (audioReady) sink.audio.volume = Math.max(0, Math.min(1, v)) }
    function nextOutput() {
        if (outputs.length < 2) return
        var idx = -1
        for (var i = 0; i < outputs.length; i++) if (sink && outputs[i].id === sink.id) idx = i
        Pipewire.preferredDefaultAudioSink = outputs[(idx + 1) % outputs.length]
    }

    IpcHandler {
        target: "widgets"
        function reset(): void { WidgetStore.reset() }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: Theme.widgetsEnabled
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Bottom
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"

            Item {
                id: canvas
                anchors.fill: parent

                // ===== Clock + weather + calendar =====
                DragCard {
                    visible: Theme.widgetClock; name: "clock"; width: 216; height: 356; defaultX: 12; defaultY: 56

                    Column {
                        anchors.fill: parent; anchors.margins: 16; spacing: 10

                        Row {
                            width: parent.width; spacing: 10
                            Text { text: Qt.formatDateTime(clock.date, Theme.use24h ? "HH:mm" : "h:mm"); color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 28; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                Text { text: root.weatherTemp; color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; font.bold: true }
                                Text { text: root.weatherCond; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; elide: Text.ElideRight; width: 78 }
                            }
                        }

                        Text { text: Qt.formatDateTime(clock.date, "dddd, MMM d"); color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                        Rectangle { width: parent.width; height: 1; color: Theme.border }

                        Grid {
                            width: parent.width; columns: 7; rowSpacing: 4
                            Repeater {
                                model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
                                Text { required property string modelData; width: 26; horizontalAlignment: Text.AlignHCenter; text: modelData; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.bold: true }
                            }
                        }

                        Grid {
                            width: parent.width; columns: 7; rowSpacing: 4
                            Repeater {
                                model: root.calendarDays
                                Rectangle {
                                    required property var modelData
                                    width: 26; height: 24; radius: 6
                                    color: modelData.isToday ? Theme.accent : "transparent"
                                    Text { anchors.centerIn: parent; text: modelData.d; color: modelData.isToday ? (Theme.lightMode ? "#ffffff" : "#12131a") : Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.bold: modelData.isToday }
                                }
                            }
                        }
                    }
                }

                // ===== Analog clock =====
                DragCard {
                    visible: Theme.widgetAnalog; name: "analog"; width: 160; height: 160; defaultX: 238; defaultY: 56

                    Item {
                        anchors.centerIn: parent; width: 124; height: 124
                        Rectangle { anchors.fill: parent; radius: 62; color: "transparent"; border.width: 2; border.color: Theme.border }

                        Repeater {
                            model: 12
                            Item {
                                required property int index
                                anchors.fill: parent; rotation: index * 30
                                Rectangle { anchors.horizontalCenter: parent.horizontalCenter; anchors.top: parent.top; anchors.topMargin: 5; width: index % 3 === 0 ? 2 : 1; height: index % 3 === 0 ? 8 : 5; color: index % 3 === 0 ? Theme.accent : Theme.text }
                            }
                        }

                        Item {
                            anchors.fill: parent; rotation: (clock.date.getHours() % 12) * 30 + clock.date.getMinutes() * 0.5
                            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.verticalCenter; width: 3; height: 32; radius: 2; color: Theme.text }
                        }
                        Item {
                            anchors.fill: parent; rotation: clock.date.getMinutes() * 6
                            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.verticalCenter; width: 2; height: 44; radius: 1; color: Theme.text }
                        }
                        Item {
                            anchors.fill: parent; rotation: clock.date.getSeconds() * 6
                            Rectangle { anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.verticalCenter; width: 1.5; height: 48; color: Theme.accent }
                        }
                        Rectangle { anchors.centerIn: parent; width: 7; height: 7; radius: 4; color: Theme.accent }
                    }
                }

                // ===== Now playing =====
                DragCard {
                    visible: Theme.widgetMusic; name: "music"; width: 160; height: 186; defaultX: 238; defaultY: 226

                    Column {
                        anchors.fill: parent; anchors.margins: 12; spacing: 8

                        Rectangle {
                            width: 76; height: 76; radius: 10; color: Theme.surface; clip: true
                            anchors.horizontalCenter: parent.horizontalCenter
                            Image { anchors.fill: parent; source: root.player && root.player.trackArtUrl ? root.player.trackArtUrl : ""; fillMode: Image.PreserveAspectCrop; visible: source !== "" }
                            Text { anchors.centerIn: parent; text: "\uf001"; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 22; visible: !root.player || !root.player.trackArtUrl }
                        }

                        Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: root.player && root.player.trackTitle ? root.player.trackTitle : "Nothing playing"; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; font.bold: true; elide: Text.ElideRight }
                        Text { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: root.player && root.player.trackArtist ? root.player.trackArtist : ""; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; elide: Text.ElideRight }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter; spacing: 14

                            Text {
                                text: "\uf048"; color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter
                                MouseArea { anchors.fill: parent; onClicked: if (root.player && root.player.canGoPrevious) root.player.previous() }
                            }

                            Rectangle {
                                width: 30; height: 30; radius: 8; color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25)
                                Text { anchors.centerIn: parent; text: root.player && root.player.isPlaying ? "\uf04c" : "\uf04b"; color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
                                MouseArea { anchors.fill: parent; onClicked: if (root.player && root.player.canTogglePlaying) root.player.togglePlaying() }
                            }

                            Text {
                                text: "\uf051"; color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter
                                MouseArea { anchors.fill: parent; onClicked: if (root.player && root.player.canGoNext) root.player.next() }
                            }
                        }
                    }
                }

                // ===== Sound =====
                DragCard {
                    visible: Theme.widgetSound; name: "sound"; width: 216; height: 130; defaultX: 408; defaultY: 56

                    Column {
                        anchors.fill: parent; anchors.margins: 16; spacing: 10

                        Item {
                            width: parent.width; height: 26

                            Text {
                                id: soundIcon
                                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                                text: root.muted ? "\uf026" : "\uf028"
                                color: root.muted ? Theme.text : Theme.accent
                                font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 20
                                MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: if (root.audioReady) root.sink.audio.muted = !root.sink.audio.muted }
                            }
                            Text { anchors.left: soundIcon.right; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter; text: "Sound"; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; font.bold: true }
                            Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: Math.round(root.vol * 100) + "%"; color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; font.bold: true }
                        }

                        Item {
                            id: slider
                            width: parent.width; height: 22

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width; height: 8; radius: 4; color: Theme.surface
                                Rectangle { width: parent.width * Math.max(0, Math.min(Theme.volumeLimit / 100.0, root.vol)); height: parent.height; radius: 4; color: root.muted ? Theme.text : Theme.accent }
                            }
                            Rectangle {
                                width: 16; height: 16; radius: 8; color: Theme.text
                                anchors.verticalCenter: parent.verticalCenter
                                x: Math.max(0, Math.min(slider.width - 16, Math.max(0, Math.min(Theme.volumeLimit / 100.0, root.vol)) * slider.width - 8))
                            }
                            MouseArea {
                                anchors.fill: parent
                                preventStealing: true
                                onPressed: (mouse) => root.setVolume(mouse.x / width)
                                onPositionChanged: (mouse) => { if (pressed) root.setVolume(mouse.x / width) }
                                onWheel: (wheel) => root.setVolume(root.vol + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))
                            }
                        }

                        Rectangle {
                            width: parent.width; height: 28; radius: 8; color: Theme.surface
                            Text {
                                anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10
                                verticalAlignment: Text.AlignVCenter
                                text: root.audioReady ? ((root.sink.nickname || root.sink.description || root.sink.name) + (root.outputs.length > 1 ? "  \uf0ec" : "")) : "No output"
                                color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; elide: Text.ElideRight
                            }
                            MouseArea { anchors.fill: parent; onClicked: root.nextOutput() }
                        }
                    }
                }

                // ===== Photo =====
                DragCard {
                    visible: Theme.widgetPhoto; name: "photo"; width: 184; height: 184; defaultX: 408; defaultY: 196

                    Item {
                        anchors.fill: parent
                        anchors.margins: 8

                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: Theme.surface
                            clip: true

                            readonly property string resolvedPhoto: {
                                if (Theme.widgetPhotoPath) return Theme.widgetPhotoPath
                                if (Theme.wallpaper) return Theme.wallpaper.indexOf("/") === 0 ? Theme.wallpaper : Quickshell.env("HOME") + "/nocturnal/wallpapers/" + Theme.wallpaper
                                return Quickshell.env("HOME") + "/nocturnal/wallpapers/wall0.png"
                            }

                            Image {
                                anchors.fill: parent
                                source: "file://" + parent.resolvedPhoto
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.right: parent.right
                                anchors.margins: 6
                                width: 28; height: 28; radius: 8
                                color: Theme.panelBg
                                border.width: 1; border.color: Theme.border
                                Text { anchors.centerIn: parent; text: "\uf03e"; color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onClicked: (mouse) => {
                                        if (mouse.button === Qt.RightButton) {
                                            pickPhotoProc.running = true
                                        } else if (root.photoList.length > 0) {
                                            root.photoIdx = (root.photoIdx + 1) % root.photoList.length
                                            Theme.widgetPhotoPath = root.photoList[root.photoIdx]
                                            Theme.save()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ===== Quote =====
                DragCard {
                    visible: Theme.widgetQuote; name: "quote"; width: 240; height: 126; defaultX: 408; defaultY: 390

                    Column {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 6

                        Row {
                            width: parent.width
                            Text { text: "\uf10d  Daily Quote"; color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.bold: true; width: parent.width - 22; anchors.verticalCenter: parent.verticalCenter }
                            Text {
                                text: "\uf021"; color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter
                                MouseArea { anchors.fill: parent; anchors.margins: -6; onClicked: root.quoteIdx = (root.quoteIdx + 1) % root.quotes.length }
                            }
                        }

                        Text {
                            width: parent.width
                            height: 58
                            text: "\"" + root.quotes[root.quoteIdx].q + "\""
                            color: Theme.text
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            wrapMode: Text.WordWrap
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: "— " + root.quotes[root.quoteIdx].a
                            color: Theme.textMuted
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            horizontalAlignment: Text.AlignRight
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }
    }
}
