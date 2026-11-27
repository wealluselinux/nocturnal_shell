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

            // Clickable art + title to open Lyrics popup
            Item {
                implicitWidth: infoRow.implicitWidth
                implicitHeight: infoRow.implicitHeight
                anchors.verticalCenter: parent.verticalCenter

                Row {
                    id: infoRow
                    spacing: 8

                    Rectangle {
                        width: 22
                        height: 22
                        radius: 5
                        color: "#1affffff"
                        clip: true
                        anchors.verticalCenter: parent.verticalCenter

                        Image {
                            anchors.fill: parent
                            source: root.player && root.player.trackArtUrl ? root.player.trackArtUrl : ""
                            fillMode: Image.PreserveAspectCrop
                            visible: source !== ""
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "\uf001"
                            color: root.player && root.player.isPlaying ? Theme.accent : "#88e6e1ff"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            visible: !root.player || !root.player.trackArtUrl
                        }
                    }

                    Text {
                        text: root.title
                        color: "#e6e1ff"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        elide: Text.ElideRight
                        width: Math.min(implicitWidth, 145)
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.popupOpen = !root.popupOpen
                }
            }

            // Inline prev / play / next
            Text {
                text: "\uf048"
                color: "#b8b3d6"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
                MouseArea {
                    anchors.fill: parent
                    onClicked: if (root.player && root.player.canGoPrevious) root.player.previous()
                }
            }

            Text {
                text: root.player && root.player.isPlaying ? "\uf04c" : "\uf04b"
                color: Theme.accent
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
                MouseArea {
                    anchors.fill: parent
                    onClicked: if (root.player && root.player.canTogglePlaying) root.player.togglePlaying()
                }
            }

            Text {
                text: "\uf051"
                color: "#b8b3d6"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
                MouseArea {
                    anchors.fill: parent
                    onClicked: if (root.player && root.player.canGoNext) root.player.next()
                }
            }
        }
    }

    // Mini-player + lyrics popup
    PanelWindow {
        visible: root.popupOpen
        exclusionMode: ExclusionMode.Ignore

        anchors { top: true; left: true }
        margins { top: 52; left: 8 }
        implicitWidth: 340
        implicitHeight: root.showLyrics ? 420 : 148
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: Theme.shapeRadius
            color: Theme.panelBg
            border.width: 1
            border.color: "#22ffffff"

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

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
                        color: root.showLyrics ? Theme.accent : "#e6e1ff"
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
