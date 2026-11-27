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
    property string lyricsText: ""
    property string loadedTrackKey: ""
    property bool loadingLyrics: false

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
            lyricsText = ""
            if (showLyrics && player && player.trackTitle) {
                fetchLyrics()
            }
        }
    }

    function fetchLyrics() {
        if (!player || !player.trackTitle) {
            lyricsText = "No track playing."
            return
        }
        loadingLyrics = true
        lyricsText = "Loading lyrics..."
        loadedTrackKey = trackKey
        var url = "https://lrclib.net/api/get?artist_name=" + encodeURIComponent(artist) + "&track_name=" + encodeURIComponent(title)
        lyricsProc.command = ["curl", "-s", "-m", "10", url]
        lyricsProc.running = true
    }

    Process {
        id: lyricsProc
        stdout: StdioCollector {
            id: collector
            onStreamFinished: {
                root.loadingLyrics = false
                try {
                    var data = JSON.parse(collector.text)
                    if (data.plainLyrics) {
                        root.lyricsText = data.plainLyrics
                    } else if (data.syncedLyrics) {
                        root.lyricsText = data.syncedLyrics.replace(/\[\d+:\d+\.\d+\]\s*/g, "")
                    } else {
                        root.lyricsText = "No lyrics found for this track."
                    }
                } catch (e) {
                    root.lyricsText = "Could not load lyrics."
                }
            }
        }
    }

    Pill {
        id: pill

        Row {
            spacing: 8
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: "\uf001"
                color: root.player && root.player.isPlaying ? "#c9b8ff" : "#88e6e1ff"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: root.title
                color: "#e6e1ff"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                elide: Text.ElideRight
                width: Math.min(implicitWidth, 190)
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    MouseArea {
        anchors.fill: pill
        onClicked: root.popupOpen = !root.popupOpen
    }

    // Mini-player + lyrics popup
    PanelWindow {
        visible: root.popupOpen
        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            left: true
        }
        margins {
            top: 54
            left: 8
        }
        implicitWidth: 340
        implicitHeight: root.showLyrics ? 420 : 148
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: 18
            color: "#cc12131a"
            border.width: 1
            border.color: "#22ffffff"

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                // Top row: art + title/artist
                Row {
                    width: parent.width
                    spacing: 12

                    Rectangle {
                        width: 56
                        height: 56
                        radius: 10
                        color: "#1affffff"
                        clip: true

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
                            font.pixelSize: 20
                            visible: !root.player || !root.player.trackArtUrl
                        }
                    }

                    Column {
                        width: parent.width - 68
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Text {
                            width: parent.width
                            text: root.title
                            color: "#e6e1ff"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: root.artist !== "" ? root.artist : "No artist"
                            color: "#99e6e1ff"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                    }
                }

                // Controls + Lyrics button
                Row {
                    width: parent.width
                    spacing: 8

                    Rectangle {
                        width: 38
                        height: 36
                        radius: 10
                        color: prevMouse.containsMouse ? "#28c9b8ff" : "#1affffff"
                        Text {
                            anchors.centerIn: parent
                            text: "\uf048"
                            color: "#e6e1ff"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                        }
                        MouseArea {
                            id: prevMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: if (root.player && root.player.canGoPrevious) root.player.previous()
                        }
                    }

                    Rectangle {
                        width: 44
                        height: 36
                        radius: 10
                        color: playMouse.containsMouse ? "#44c9b8ff" : "#28c9b8ff"
                        Text {
                            anchors.centerIn: parent
                            text: root.player && root.player.isPlaying ? "\uf04c" : "\uf04b"
                            color: "#c9b8ff"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                        }
                        MouseArea {
                            id: playMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: if (root.player && root.player.canTogglePlaying) root.player.togglePlaying()
                        }
                    }

                    Rectangle {
                        width: 38
                        height: 36
                        radius: 10
                        color: nextMouse.containsMouse ? "#28c9b8ff" : "#1affffff"
                        Text {
                            anchors.centerIn: parent
                            text: "\uf051"
                            color: "#e6e1ff"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                        }
                        MouseArea {
                            id: nextMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: if (root.player && root.player.canGoNext) root.player.next()
                        }
                    }

                    Rectangle {
                        width: parent.width - 144
                        height: 36
                        radius: 10
                        color: root.showLyrics ? "#33c9b8ff" : (lyrMouse.containsMouse ? "#28c9b8ff" : "#1affffff")
                        border.width: root.showLyrics ? 1 : 0
                        border.color: "#c9b8ff"

                        Text {
                            anchors.centerIn: parent
                            text: root.showLyrics ? "Hide Lyrics" : "Lyrics"
                            color: root.showLyrics ? "#c9b8ff" : "#e6e1ff"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                        }

                        MouseArea {
                            id: lyrMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                root.showLyrics = !root.showLyrics
                                if (root.showLyrics && root.lyricsText === "") {
                                    root.fetchLyrics()
                                }
                            }
                        }
                    }
                }

                // Scrollable lyrics area
                Flickable {
                    visible: root.showLyrics
                    width: parent.width
                    height: parent.height - 118
                    contentHeight: lyricsLabel.implicitHeight
                    clip: true

                    Text {
                        id: lyricsLabel
                        width: parent.width
                        text: root.lyricsText
                        color: "#d8d3f2"
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
