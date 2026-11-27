import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root
    property bool open: false
    property string activeTab: "theme"
    property var wallpapers: []
    property string homeDir: Quickshell.env("HOME") || ""

    readonly property var accentOptions: [
        { name: "Lavender", hex: "#c9b8ff" },
        { name: "Sky",      hex: "#89dceb" },
        { name: "Mint",     hex: "#a6e3a1" },
        { name: "Peach",    hex: "#fab387" },
        { name: "Rose",     hex: "#f38ba8" }
    ]

    IpcHandler {
        target: "settings"
        function toggle(): void {
            root.open = !root.open
        }
    }

    ColorQuantizer {
        id: quantizer
        depth: 3
        rescaleSize: 64
        onColorsChanged: {
            if (!colors || colors.length === 0) return
            var best = colors[0]
            var bestScore = -1
            for (var i = 0; i < colors.length; i++) {
                var c = colors[i]
                var score = c.hslSaturation * (1 - Math.abs(c.hslLightness - 0.55))
                if (score > bestScore) {
                    bestScore = score
                    best = c
                }
            }
            var tuned = Qt.hsla(best.hslHue, Math.max(0.55, best.hslSaturation), Math.max(0.72, best.hslLightness), 1.0)
            Theme.accent = tuned
            Theme.save()
        }
    }

    function applyWallpaper(pathOrName) {
        if (!pathOrName) return
        Theme.wallpaper = pathOrName
        Theme.save()
        var fullPath = pathOrName.indexOf("/") === 0
            ? pathOrName
            : root.homeDir + "/nocturnal/wallpapers/" + pathOrName
        quantizer.source = "file://" + fullPath
        Quickshell.execDetached(["sh", "-c", "pkill swaybg; swaybg -i \"" + fullPath + "\" -m fill &"])
    }

    Process {
        id: wallListProc
        command: ["sh", "-c", "ls -1 \"$HOME/nocturnal/wallpapers\" 2>/dev/null"]
        stdout: StdioCollector {
            id: wallCollector
            onStreamFinished: {
                var lines = wallCollector.text.trim().split("\n")
                root.wallpapers = lines.filter(l => l.length > 0)
            }
        }
    }

    Process {
        id: browseWallProc
        command: ["sh", "-c", "if command -v kdialog >/dev/null 2>&1; then kdialog --getopenfilename \"$HOME/Pictures\" \"Images (*.png *.jpg *.jpeg *.webp)\"; elif command -v zenity >/dev/null 2>&1; then zenity --file-selection --file-filter=\"Images | *.png *.jpg *.jpeg *.webp\"; fi"]
        stdout: StdioCollector {
            id: browseCollector
            onStreamFinished: {
                var chosen = browseCollector.text.trim()
                if (chosen.length > 0) {
                    root.applyWallpaper(chosen)
                }
            }
        }
    }

    PanelWindow {
        id: win
        visible: root.open || card.opacity > 0.01
        focusable: true
        exclusionMode: ExclusionMode.Ignore

        implicitWidth: 660
        implicitHeight: 440
        color: "transparent"

        onVisibleChanged: {
            if (visible) wallListProc.running = true
        }

        Rectangle {
            id: card
            anchors.fill: parent
            radius: 12
            color: "#dd12131a"
            border.width: 1
            border.color: "#22ffffff"

            opacity: root.open ? 1 : 0
            scale: root.open ? 1.0 : 0.94
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            Row {
                anchors.fill: parent

                // LEFT CONTENT AREA
                Item {
                    width: parent.width - 165
                    height: parent.height

                    // TAB 1: THEME
                    Column {
                        visible: root.activeTab === "theme"
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 14

                        Text {
                            text: "Theme & Wallpaper"
                            color: "#e6e1ff"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 17
                            font.bold: true
                        }

                        // Accent Color
                        Column {
                            width: parent.width
                            spacing: 8

                            Text {
                                text: "ACCENT COLOR (auto-updates with wallpaper)"
                                color: Theme.accent
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                font.bold: true
                            }

                            Row {
                                spacing: 10
                                Repeater {
                                    model: root.accentOptions
                                    Rectangle {
                                        required property var modelData
                                        width: 30
                                        height: 30
                                        radius: 15
                                        color: modelData.hex
                                        border.width: Theme.accent.toString() === modelData.hex ? 3 : 0
                                        border.color: "#ffffff"

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                Theme.accent = modelData.hex
                                                Theme.save()
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    width: 30
                                    height: 30
                                    radius: 15
                                    color: Theme.accent
                                    border.width: 2
                                    border.color: "#ffffff"
                                }
                            }
                        }

                        // Blur & Rounding
                        Row {
                            width: parent.width
                            spacing: 8

                            Rectangle {
                                width: 104
                                height: 34
                                radius: 8
                                color: Theme.blurEnabled ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : "#1affffff"
                                border.width: Theme.blurEnabled ? 1 : 0
                                border.color: Theme.accent

                                Text {
                                    anchors.centerIn: parent
                                    text: Theme.blurEnabled ? "Blur: ON" : "Blur: OFF"
                                    color: "#e6e1ff"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 12
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        Theme.blurEnabled = !Theme.blurEnabled
                                        Theme.save()
                                        Quickshell.execDetached(["hyprctl", "keyword", "decoration:blur:enabled", Theme.blurEnabled ? "true" : "false"])
                                    }
                                }
                            }

                            Repeater {
                                model: [0, 8, 14, 20]
                                Rectangle {
                                    required property int modelData
                                    width: 50
                                    height: 34
                                    radius: 8
                                    color: Theme.rounding === modelData ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : "#1affffff"
                                    border.width: Theme.rounding === modelData ? 1 : 0
                                    border.color: Theme.accent

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData + "px"
                                        color: "#e6e1ff"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 11
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            Theme.rounding = modelData
                                            Theme.save()
                                            Quickshell.execDetached(["hyprctl", "keyword", "decoration:rounding", String(modelData)])
                                        }
                                    }
                                }
                            }
                        }

                        // Wallpaper Picker
                        Column {
                            width: parent.width
                            height: parent.height - 175
                            spacing: 8

                            Row {
                                width: parent.width

                                Text {
                                    text: "WALLPAPER"
                                    color: Theme.accent
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    font.bold: true
                                    width: parent.width - 130
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Rectangle {
                                    width: 130
                                    height: 30
                                    radius: 8
                                    color: browseMouse.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : "#1affffff"
                                    border.width: 1
                                    border.color: Theme.accent

                                    Text {
                                        anchors.centerIn: parent
                                        text: "Browse File..."
                                        color: "#e6e1ff"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 12
                                    }

                                    MouseArea {
                                        id: browseMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: browseWallProc.running = true
                                    }
                                }
                            }

                            ListView {
                                width: parent.width
                                height: parent.height - 38
                                clip: true
                                spacing: 4
                                model: root.wallpapers

                                delegate: Rectangle {
                                    required property string modelData
                                    width: ListView.view.width
                                    height: 34
                                    radius: 8
                                    color: Theme.wallpaper === modelData ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2) : (wMouse.containsMouse ? "#1affffff" : "transparent")
                                    border.width: Theme.wallpaper === modelData ? 1 : 0
                                    border.color: Theme.accent

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        text: modelData
                                        color: "#e6e1ff"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 13
                                        elide: Text.ElideRight
                                    }

                                    MouseArea {
                                        id: wMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: root.applyWallpaper(modelData)
                                    }
                                }
                            }
                        }
                    }

                    // TAB 2: POSITION
                    Column {
                        visible: root.activeTab === "position"
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 18

                        Text {
                            text: "Position & Layout"
                            color: "#e6e1ff"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 17
                            font.bold: true
                        }

                        // Dock Visibility
                        Column {
                            width: parent.width
                            spacing: 8

                            Text {
                                text: "BOTTOM DOCK"
                                color: Theme.accent
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                font.bold: true
                            }

                            Rectangle {
                                width: 120
                                height: 36
                                radius: 8
                                color: Theme.dockEnabled ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : "#1affffff"
                                border.width: Theme.dockEnabled ? 1 : 0
                                border.color: Theme.accent

                                Text {
                                    anchors.centerIn: parent
                                    text: Theme.dockEnabled ? "Dock: ON" : "Dock: OFF"
                                    color: "#e6e1ff"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        Theme.dockEnabled = !Theme.dockEnabled
                                        Theme.save()
                                    }
                                }
                            }
                        }

                        // Dock Position
                        Column {
                            width: parent.width
                            spacing: 8

                            Text {
                                text: "DOCK POSITION"
                                color: Theme.accent
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                font.bold: true
                            }

                            Row {
                                spacing: 10
                                Repeater {
                                    model: ["left", "middle", "right"]
                                    Rectangle {
                                        required property string modelData
                                        width: 110
                                        height: 36
                                        radius: 8
                                        color: Theme.dockPosition === modelData ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : "#1affffff"
                                        border.width: Theme.dockPosition === modelData ? 1 : 0
                                        border.color: Theme.accent

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                            color: "#e6e1ff"
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 13
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                Theme.dockPosition = modelData
                                                Theme.save()
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // App Chooser Position
                        Column {
                            width: parent.width
                            spacing: 8

                            Text {
                                text: "APP CHOOSER POSITION"
                                color: Theme.accent
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                font.bold: true
                            }

                            Row {
                                spacing: 10
                                Repeater {
                                    model: ["left", "middle", "right"]
                                    Rectangle {
                                        required property string modelData
                                        width: 110
                                        height: 36
                                        radius: 8
                                        color: Theme.launcherPosition === modelData ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : "#1affffff"
                                        border.width: Theme.launcherPosition === modelData ? 1 : 0
                                        border.color: Theme.accent

                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.charAt(0).toUpperCase() + modelData.slice(1)
                                            color: "#e6e1ff"
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 13
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                Theme.launcherPosition = modelData
                                                Theme.save()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // TAB 3: ABOUT
                    Column {
                        visible: root.activeTab === "about"
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 14

                        Text {
                            text: "Nocturnal Shell"
                            color: Theme.accent
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 22
                            font.bold: true
                        }

                        Text {
                            text: "Made by rig\nBuilt off Hyprland"
                            color: "#e6e1ff"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            lineHeight: 1.5
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: "#22ffffff"
                        }

                        Column {
                            spacing: 8

                            Text {
                                text: "Compositor: Hyprland 0.56.2 (Lua)"
                                color: "#b8b3d6"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                            }
                            Text {
                                text: "Shell UI:   Quickshell (QML)"
                                color: "#b8b3d6"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                            }
                            Text {
                                text: "OS:         Gentoo Linux"
                                color: "#b8b3d6"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                            }
                        }
                    }
                }

                // VERTICAL DIVIDER
                Rectangle {
                    width: 1
                    height: parent.height
                    color: "#22ffffff"
                }

                // RIGHT SIDEBAR
                Column {
                    width: 164
                    height: parent.height
                    padding: 14
                    spacing: 8

                    Row {
                        width: parent.width - 28
                        Text {
                            text: "Settings"
                            color: "#88e6e1ff"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            font.bold: true
                            width: parent.width - 22
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "✕"
                            color: "#88e6e1ff"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 15
                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.open = false
                            }
                        }
                    }

                    Item { width: 1; height: 6 }

                    Repeater {
                        model: [
                            { id: "theme",    label: "Theme" },
                            { id: "position", label: "Position" },
                            { id: "about",    label: "About" }
                        ]

                        Rectangle {
                            required property var modelData
                            width: parent.width - 28
                            height: 38
                            radius: 8
                            color: root.activeTab === modelData.id ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : (tabMouse.containsMouse ? "#1affffff" : "transparent")
                            border.width: root.activeTab === modelData.id ? 1 : 0
                            border.color: Theme.accent

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                text: modelData.label
                                color: root.activeTab === modelData.id ? Theme.accent : "#e6e1ff"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                                font.bold: root.activeTab === modelData.id
                            }

                            MouseArea {
                                id: tabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.activeTab = modelData.id
                            }
                        }
                    }
                }
            }
        }
    }
}
