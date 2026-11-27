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

    readonly property var player: {
        var list = Mpris.players.values
        for (var i = 0; i < list.length; i++) {
            if (list[i].isPlaying) return list[i]
        }
        return list.length > 0 ? list[0] : null
    }

    readonly property string title: player && player.trackTitle ? player.trackTitle : "Nothing playing"
    readonly property string artist: player && player.trackArtist ? player.trackArtist : ""
    readonly property string trackKey: title + "::" + artist

    onTrackKeyChanged: {
        if (trackKey !== loadedTrackKey) {
            syncedLines = []
            plainText = ""
            activeLineIdx = -1
            if (showLyrics && player && player.trackTitle) {
                fetchLyrics()
            }
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
        if (!player || !player.trackTitle) {
            plainText = "No track playing."
            return
        }
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
        running: root.showLyrics && root.syncedLines.length > 0 && root.player !== null && root.player.isPlaying
        repeat: true
        onTriggered: {
            var pos = root.player.position
            var idx = -1
            for (var i = 0; i < root.syncedLines.length; i++) {
                if (root.syncedLines[i].time <= pos) idx = i
                else break
            }
            root.activeLineIdx = idx
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
                        width: 22; height: 22; radius: 5; color: "#1affffff"; clip: true
                        anchors.verticalCenter: parent.verticalCenter
                        Image { anchors.fill: parent; source: root.player && root.player.trackArtUrl ? root.player.trackArtUrl : ""; fillMode: Image.PreserveAspectCrop; visible: source !== "" }
                        Text { anchors.centerIn: parent; text: "\uf001"; color: root.player && root.player.isPlaying ? Theme.accent : Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; visible: !root.player || !root.player.trackArtUrl }
                    }

                    Text {
                        text: root.title
                        color: Theme.text
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        width: Math.min(implicitWidth, 145)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea { anchors.fill: parent; onClicked: root.popupOpen = !root.popupOpen }
            }

            Text {
                text: "\uf048"; color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter
                MouseArea { anchors.fill: parent; onClicked: if (root.player && root.player.canGoPrevious) root.player.previous() }
            }
            Text {
                text: root.player && root.player.isPlaying ? "\uf04c" : "\uf04b"; color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter
                MouseArea { anchors.fill: parent; onClicked: if (root.player && root.player.canTogglePlaying) root.player.togglePlaying() }
            }
            Text {
                text: "\uf051"; color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter
                MouseArea { anchors.fill: parent; onClicked: if (root.player && root.player.canGoNext) root.player.next() }
            }
        }
    }

    PanelWindow {
        visible: root.popupOpen || card.opacity > 0.01
        exclusionMode: ExclusionMode.Ignore

        anchors { top: true; left: true }
        margins { top: 52; left: 8 }
        implicitWidth: 340
        implicitHeight: root.showLyrics ? (root.syncedLines.length > 0 ? 250 : 380) : 148
        color: "transparent"

        Behavior on implicitHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        Rectangle {
            id: card
            anchors.fill: parent
            radius: Theme.shapeRadius
            color: Theme.panelBg
            border.width: 1
            border.color: "#22ffffff"

            opacity: root.popupOpen ? 1 : 0
            transform: Translate { y: root.popupOpen ? 0 : -12; Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } } }
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Row {
                    width: parent.width
                    spacing: 12

                    Rectangle {
                        width: 56; height: 56; radius: 10; color: "#1affffff"; clip: true
                        Image { anchors.fill: parent; source: root.player && root.player.trackArtUrl ? root.player.trackArtUrl : ""; fillMode: Image.PreserveAspectCrop; visible: source !== "" }
                        Text { anchors.centerIn: parent; text: "\uf001"; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 20; visible: !root.player || !root.player.trackArtUrl }
                    }

                    Column {
                        width: parent.width - 68
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Text { width: parent.width; text: root.title; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; font.bold: true; elide: Text.ElideRight }
                        Text { width: parent.width; text: root.artist !== "" ? root.artist : "No artist"; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; elide: Text.ElideRight }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 36
                    radius: 10
                    color: root.showLyrics ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : (lyrMouse.containsMouse ? "#28ffffff" : "#1affffff")
                    border.width: root.showLyrics ? 1 : 0
                    border.color: Theme.accent

                    Text {
                        anchors.centerIn: parent
                        text: root.showLyrics ? "Hide Lyrics" : "Lyrics"
                        color: root.showLyrics ? Theme.accent : Theme.text
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                    }

                    MouseArea {
                        id: lyrMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            root.showLyrics = !root.showLyrics
                            if (root.showLyrics && root.syncedLines.length === 0 && root.plainText === "") {
                                root.fetchLyrics()
                            }
                        }
                    }
                }

                // Live 1-line synced lyrics
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

                // Fallback plain lyrics if no timestamps exist
                Flickable {
                    visible: root.showLyrics && root.syncedLines.length === 0
                    width: parent.width
                    height: parent.height - 118
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
