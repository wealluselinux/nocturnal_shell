import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick

Item {
    id: root
    implicitWidth: pill.width
    implicitHeight: pill.height

    property bool popupOpen: false
    property bool showLyrics: false
    property var syncedLines: []
    property string plainText: ""
    property string loadedTrackKey: ""
    property int activeLineIdx: -1
    property real trackPos: 0

    readonly property var player: {
        var list = Mpris.players.values
        for (var i = 0; i < list.length; i++) if (list[i].isPlaying) return list[i]
        return list.length > 0 ? list[0] : null
    }

    readonly property string title: player && player.trackTitle ? player.trackTitle : "Nothing playing"
    readonly property string artist: player && player.trackArtist ? player.trackArtist : ""
    readonly property string trackKey: title + "::" + artist
    readonly property real trackLen: (player && player.length > 0) ? player.length : 0

    function fmtTime(sec) {
        if (!sec || sec < 0) return "0:00"
        var s = Math.floor(sec)
        var m = Math.floor(s / 60)
        var r = s % 60
        return m + ":" + (r < 10 ? "0" : "") + r
    }

    onTrackKeyChanged: {
        if (trackKey !== loadedTrackKey) {
            syncedLines = []
            plainText = ""
            activeLineIdx = -1
            if (showLyrics && player && player.trackTitle) fetchLyrics()
        }
    }

    function parseLrc(lrc) {
        var out = []
        var lines = lrc.split("\n")
        for (var i = 0; i < lines.length; i++) {
            var m = lines[i].match(/^\[(\d+):(\d+(?:\.\d+)?)\]\s*(.*)$/)
            if (m) {
                var sec = parseInt(m[1]) * 60 + parseFloat(m[2])
                var txt = m[3].trim()
                if (txt.length > 0) out.push({ time: sec, text: txt })
            }
        }
        return out
    }

    function fetchLyrics() {
        if (!player || !player.trackTitle) { plainText = "No track playing."; return }
        plainText = "Loading lyrics..."
        syncedLines = []
        activeLineIdx = -1
        loadedTrackKey = trackKey
        var url = "https://lrclib.net/api/get?artist_name=" + encodeURIComponent(artist) + "&track_name=" + encodeURIComponent(title)
        lyricsProc.command = ["curl", "-s", "-m", "10", url]
        lyricsProc.running = true
    }

    Timer {
        interval: 250
        running: (root.popupOpen || root.showLyrics) && root.player !== null && root.player.isPlaying
        repeat: true
        onTriggered: {
            root.trackPos = root.player.position
            if (root.syncedLines.length > 0) {
                var pos = root.trackPos
                var idx = -1
                for (var i = 0; i < root.syncedLines.length; i++) {
                    if (root.syncedLines[i].time <= pos) idx = i
                    else break
                }
                root.activeLineIdx = idx
            }
        }
    }

    Process {
        id: lyricsProc
        stdout: StdioCollector {
            id: collector
            onStreamFinished: {
                try {
                    var data = JSON.parse(collector.text)
                    if (data.syncedLyrics) {
                        root.syncedLines = root.parseLrc(data.syncedLyrics)
                        root.plainText = root.syncedLines.length > 0 ? "" : (data.plainLyrics || "No lyrics found.")
                    } else if (data.plainLyrics) {
                        root.syncedLines = []
                        root.plainText = data.plainLyrics
                    } else {
                        root.syncedLines = []
                        root.plainText = "No lyrics found for this track."
                    }
                } catch (e) {
                    root.plainText = "Could not load lyrics."
                }
            }
        }
    }

    Pill {
        id: pill

        Row {
            spacing: 8
            anchors.verticalCenter: parent.verticalCenter

            Item {
                implicitWidth: infoRow.implicitWidth
                implicitHeight: infoRow.implicitHeight
                anchors.verticalCenter: parent.verticalCenter

                Row {
                    id: infoRow
                    spacing: 8

                    Rectangle {
                        width: 24; height: 24; radius: 6; color: Theme.surface; clip: true
                        anchors.verticalCenter: parent.verticalCenter
                        Image { anchors.fill: parent; source: root.player && root.player.trackArtUrl ? root.player.trackArtUrl : ""; fillMode: Image.PreserveAspectCrop; visible: source !== "" }
                        Text { anchors.centerIn: parent; text: "\uf001"; color: root.player && root.player.isPlaying ? Theme.accent : Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; visible: !root.player || !root.player.trackArtUrl }
                    }

                    Text {
                        text: root.artist !== "" ? (root.title + " — " + root.artist) : root.title
                        color: Theme.text
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        font.bold: root.player && root.player.isPlaying
                        elide: Text.ElideRight
                        width: Math.min(implicitWidth, 165)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea { anchors.fill: parent; onClicked: root.popupOpen = !root.popupOpen }
            }

            Text {
                text: "\uf048"; color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter
                MouseArea { anchors.fill: parent; onClicked: if (root.player && root.player.canGoPrevious) root.player.previous() }
            }
            Text {
                text: root.player && root.player.isPlaying ? "\uf04c" : "\uf04b"; color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter
                MouseArea { anchors.fill: parent; onClicked: if (root.player && root.player.canTogglePlaying) root.player.togglePlaying() }
            }
            Text {
                text: "\uf051"; color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter
                MouseArea { anchors.fill: parent; onClicked: if (root.player && root.player.canGoNext) root.player.next() }
            }
        }
    }

    PanelWindow {
        visible: root.popupOpen || card.opacity > 0.01
        exclusionMode: ExclusionMode.Ignore

        anchors { top: true; left: true }
        margins { top: 52; left: 8 }
        implicitWidth: 400
        implicitHeight: root.showLyrics ? (root.syncedLines.length > 0 ? 316 : 440) : 226
        color: "transparent"

        Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        Rectangle {
            id: card
            anchors.fill: parent
            radius: Theme.shapeRadius
            color: Theme.panelBg
            border.width: 1
            border.color: Theme.border

            opacity: root.popupOpen ? 1 : 0
            transform: Translate { y: root.popupOpen ? 0 : -12; Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } } }
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // Album Art + Title + Artist
                Row {
                    width: parent.width
                    spacing: 14

                    Rectangle {
                        width: 84; height: 84; radius: 12; color: Theme.surface; clip: true
                        border.width: 1; border.color: Theme.border
                        Image { anchors.fill: parent; source: root.player && root.player.trackArtUrl ? root.player.trackArtUrl : ""; fillMode: Image.PreserveAspectCrop; visible: source !== "" }
                        Text { anchors.centerIn: parent; text: "\uf001"; color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 28; visible: !root.player || !root.player.trackArtUrl }
                    }

                    Column {
                        width: parent.width - 98
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5
                        Text { width: parent.width; text: root.title; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16; font.bold: true; elide: Text.ElideRight }
                        Text { width: parent.width; text: root.artist !== "" ? root.artist : "No artist"; color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; elide: Text.ElideRight }
                        Text {
                            text: root.player && root.player.isPlaying ? "Playing" : "Paused"
                            color: Theme.accent
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }
                }

                // Progress bar + timestamps
                Column {
                    width: parent.width
                    spacing: 4
                    Rectangle {
                        width: parent.width; height: 6; radius: 3; color: Theme.surface
                        Rectangle {
                            width: root.trackLen > 0 ? parent.width * Math.max(0, Math.min(1, root.trackPos / root.trackLen)) : 0
                            height: parent.height; radius: 3; color: Theme.accent
                        }
                    }
                    Row {
                        width: parent.width
                        Text { text: root.fmtTime(root.trackPos); color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; width: parent.width / 2 }
                        Text { text: root.fmtTime(root.trackLen); color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; width: parent.width / 2; horizontalAlignment: Text.AlignRight }
                    }
                }

                // Controls + Lyrics button
                Row {
                    width: parent.width
                    spacing: 10

                    Rectangle {
                        width: 42; height: 42; radius: 12; color: Theme.surface; border.width: 1; border.color: Theme.border
                        Text { anchors.centerIn: parent; text: "\uf048"; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 15 }
                        MouseArea { anchors.fill: parent; onClicked: if (root.player && root.player.canGoPrevious) root.player.previous() }
                    }

                    Rectangle {
                        width: 48; height: 42; radius: 12; color: Theme.accent
                        Text { anchors.centerIn: parent; text: root.player && root.player.isPlaying ? "\uf04c" : "\uf04b"; color: Theme.lightMode ? "#ffffff" : "#12131a"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 16 }
                        MouseArea { anchors.fill: parent; onClicked: if (root.player && root.player.canTogglePlaying) root.player.togglePlaying() }
                    }

                    Rectangle {
                        width: 42; height: 42; radius: 12; color: Theme.surface; border.width: 1; border.color: Theme.border
                        Text { anchors.centerIn: parent; text: "\uf051"; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 15 }
                        MouseArea { anchors.fill: parent; onClicked: if (root.player && root.player.canGoNext) root.player.next() }
                    }

                    Rectangle {
                        width: parent.width - 162
                        height: 42
                        radius: 12
                        color: root.showLyrics ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : Theme.surface
                        border.width: 1
                        border.color: root.showLyrics ? Theme.accent : Theme.border

                        Text {
                            anchors.centerIn: parent
                            text: root.showLyrics ? "Hide Lyrics" : "Lyrics"
                            color: root.showLyrics ? Theme.accent : Theme.text
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            font.bold: root.showLyrics
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.showLyrics = !root.showLyrics
                                if (root.showLyrics && root.syncedLines.length === 0 && root.plainText === "") root.fetchLyrics()
                            }
                        }
                    }
                }

                Item {
                    visible: root.showLyrics && root.syncedLines.length > 0
                    width: parent.width
                    height: 76

                    Text {
                        anchors.centerIn: parent
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: root.activeLineIdx >= 0 ? root.syncedLines[root.activeLineIdx].text : "♪"
                        color: Theme.accent
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        font.bold: true
                        wrapMode: Text.WordWrap
                    }
                }

                Flickable {
                    visible: root.showLyrics && root.syncedLines.length === 0
                    width: parent.width
                    height: parent.height - 196
                    contentHeight: lyricsLabel.implicitHeight
                    clip: true

                    Text {
                        id: lyricsLabel
                        width: parent.width
                        text: root.plainText
                        color: Theme.textMuted
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        lineHeight: 1.35
                    }
                }
            }
        }
    }
}
