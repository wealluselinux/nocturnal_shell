import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import QtQuick

Scope {
    id: root
    property bool open: false
    property string activeTab: "home"
    property var wallpapers: []
    property string homeDir: Quickshell.env("HOME") || ""
    property string osPretty: "Linux"
    property string userHost: Quickshell.env("USER") || "rig"
    property string uptimeStr: "up 0m"
    property string localVer: "1.2.2"
    readonly property string codename: "Crescent"
    property string remoteVer: ""
    property string updateMsg: ""

    readonly property var themePresets: [
        { name: "Nocturnal", bg: "#12131a", accent: "#c9b8ff" },
        { name: "Midnight",  bg: "#0e1420", accent: "#89dceb" },
        { name: "Forest",    bg: "#101714", accent: "#a6e3a1" },
        { name: "Ember",     bg: "#1a1214", accent: "#fab387" },
        { name: "Crimson",   bg: "#191116", accent: "#f38ba8" }
    ]

    readonly property var player: {
        var list = Mpris.players.values
        for (var i = 0; i < list.length; i++) if (list[i].isPlaying) return list[i]
        return list.length > 0 ? list[0] : null
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    IpcHandler {
        target: "settings"
        function toggle(): void { root.open = !root.open }
    }

    ColorQuantizer {
        id: quantizer
        depth: ColorQuantizer.Medium
        rescaleSize: 64
        onColorsChanged: {
            if (!colors || colors.length === 0) return
            var best = colors[0], bestScore = -1
            for (var i = 0; i < colors.length; i++) {
                var c = colors[i]
                var score = c.hslSaturation * (1 - Math.abs(c.hslLightness - 0.55))
                if (score > bestScore) { bestScore = score; best = c }
            }
            var tuned = Qt.hsla(best.hslHue, Math.max(0.55, best.hslSaturation), Theme.lightMode ? Math.min(0.45, Math.max(0.32, best.hslLightness)) : Math.max(0.72, best.hslLightness), 1.0)
            Theme.accent = tuned
            Theme.themePreset = "Wallpaper"
            Theme.save()
        }
    }

    function applyWallpaper(pathOrName) {
        if (!pathOrName) return
        Theme.wallpaper = pathOrName
        Theme.save()
        var fullPath = pathOrName.indexOf("/") === 0 ? pathOrName : root.homeDir + "/nocturnal/wallpapers/" + pathOrName
        quantizer.source = "file://" + fullPath
        Quickshell.execDetached([root.homeDir + "/nocturnal/bin/set-wallpaper", fullPath])
    }

    Process {
        id: verProc
        command: ["sh", "-c", "cat \"$HOME/nocturnal/VERSION\" 2>/dev/null || echo 1.2.2"]
        stdout: StdioCollector { id: vCol; onStreamFinished: { var v = vCol.text.trim(); if (v) root.localVer = v } }
    }

    Process {
        id: checkUpdProc
        command: ["curl", "-fsSL", "-m", "8", "https://raw.githubusercontent.com/wealluselinux/nocturnal_shell/main/VERSION"]
        stdout: StdioCollector {
            id: uCol
            onStreamFinished: {
                var r = uCol.text.trim()
                if (!r) { root.updateMsg = "Could not reach GitHub"; return }
                root.remoteVer = r
                root.updateMsg = (r !== root.localVer) ? ("Update available: v" + r) : ("Up to date (v" + root.localVer + ")")
            }
        }
    }

    Process {
        id: osProc
        command: ["sh", "-c", "os=$(. /etc/os-release 2>/dev/null && echo \"${PRETTY_NAME:-Linux}\"); uh=$(whoami)@$(hostname); up=$(uptime -p 2>/dev/null | sed -E 's/up //; s/ minutes?/m/; s/ hours?/h/'); echo \"$os|$uh|$up\""]
        stdout: StdioCollector {
            id: osCol
            onStreamFinished: {
                var p = osCol.text.trim().split("|")
                if (p.length >= 3) {
                    if (p[0]) root.osPretty = p[0]
                    if (p[1]) root.userHost = p[1]
                    if (p[2]) root.uptimeStr = p[2]
                }
            }
        }
    }

    Process {
        id: wallListProc
        command: ["sh", "-c", "find \"$HOME/nocturnal/wallpapers\" \"$HOME/Pictures/Wallpapers\" -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\) 2>/dev/null | sort"]
        stdout: StdioCollector {
            id: wallCollector
            onStreamFinished: root.wallpapers = wallCollector.text.trim().split("\n").filter(l => l.length > 0)
        }
    }

    Process {
        id: browseWallProc
        command: ["sh", "-c", "if command -v kdialog >/dev/null 2>&1; then QT_QPA_PLATFORMTHEME=kde kdialog --getopenfilename \"$HOME/Pictures\" \"Images (*.png *.jpg *.jpeg *.webp)\"; elif command -v zenity >/dev/null 2>&1; then zenity --file-selection --file-filter=\"Images | *.png *.jpg *.jpeg *.webp\"; fi"]
        stdout: StdioCollector {
            id: browseCollector
            onStreamFinished: { var chosen = browseCollector.text.trim(); if (chosen.length > 0) root.applyWallpaper(chosen) }
        }
    }

    PanelWindow {
        id: win
        visible: root.open
        focusable: true
        exclusionMode: ExclusionMode.Ignore

        implicitWidth: 740
        implicitHeight: 560
        color: "transparent"

        onVisibleChanged: { if (visible) { wallListProc.running = true; osProc.running = true; verProc.running = true } }

        Rectangle {
            id: card
            anchors.fill: parent
            radius: Theme.shapeRadius
            color: Theme.panelBg
            border.width: 1
            border.color: Theme.border

            opacity: root.open ? 1 : 0
            scale: root.open ? 1.0 : 0.94
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }

            Row {
                anchors.fill: parent

                // LEFT ICON RAIL
                Rectangle {
                    width: 56
                    height: parent.height
                    color: Theme.surface
                    radius: Theme.shapeRadius

                    Column {
                        anchors.top: parent.top
                        anchors.topMargin: 16
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 10

                        Repeater {
                            model: [
                                { id: "home",      icon: "\uf015" },
                                { id: "themes",    icon: "\uf1fc" },
                                { id: "wallpaper", icon: "\uf03e" },
                                { id: "position",  icon: "\uf009" },
                                { id: "about",     icon: "\uf05a" }
                            ]

                            Rectangle {
                                required property var modelData
                                width: 38; height: 38; radius: 10
                                color: root.activeTab === modelData.id ? Theme.accent : (railMouse.containsMouse ? Theme.surface : "transparent")
                                Behavior on color { ColorAnimation { duration: 140 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    color: root.activeTab === modelData.id ? (Theme.lightMode ? "#ffffff" : "#12131a") : Theme.textMuted
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 16
                                }

                                MouseArea {
                                    id: railMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.activeTab = modelData.id
                                }
                            }
                        }
                    }
                }

                Rectangle { width: 1; height: parent.height; color: Theme.border }

                // MAIN CONTENT AREA
                Column {
                    width: parent.width - 57
                    height: parent.height
                    padding: 18
                    spacing: 12

                    // Top title + close
                    Row {
                        width: parent.width - 36
                        Text {
                            text: root.activeTab.charAt(0).toUpperCase() + root.activeTab.slice(1)
                            color: Theme.text
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 16
                            font.bold: true
                            width: parent.width - 24
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "✕"
                            color: Theme.textMuted
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 16
                            MouseArea { anchors.fill: parent; onClicked: root.open = false }
                        }
                    }

                    Item {
                        width: parent.width - 36
                        height: parent.height - 68

                        // TAB 0: HOME
                        Column {
                            visible: root.activeTab === "home"
                            anchors.fill: parent
                            spacing: 12

                            // Wallpaper Banner Card
                            Rectangle {
                                width: parent.width
                                height: 150
                                radius: 14
                                color: Theme.surface
                                border.width: 1; border.color: Theme.border
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    source: Theme.wallpaper ? ("file://" + (Theme.wallpaper.indexOf("/") === 0 ? Theme.wallpaper : root.homeDir + "/nocturnal/wallpapers/" + Theme.wallpaper)) : ""
                                    fillMode: Image.PreserveAspectCrop
                                    opacity: 0.28
                                    visible: source !== ""
                                }

                                Row {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: 22
                                    spacing: 18

                                    Rectangle {
                                        width: 82; height: 82; radius: 41
                                        color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2)
                                        border.width: 2; border.color: Theme.accent
                                        MoonLogo { anchors.centerIn: parent; width: 54; height: 54 }
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 4
                                        Text { text: root.userHost.toUpperCase(); color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18; font.bold: true }
                                        Text { text: (Theme.lightMode ? "Daylight Shell" : "Nocturnal Shell") + " v" + root.localVer + " (" + root.codename + ")"; color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; font.bold: true }
                                        Text { text: "Uptime - " + root.uptimeStr; color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                                    }
                                }
                            }

                            // Bottom Split: Left (Now Playing + Clock) & Right (Quick Grid)
                            Row {
                                width: parent.width
                                height: parent.height - 162
                                spacing: 12

                                Column {
                                    width: parent.width * 0.48
                                    height: parent.height
                                    spacing: 10

                                    // Now Playing card
                                    Rectangle {
                                        width: parent.width; height: 130; radius: 14; color: Theme.surface; border.width: 1; border.color: Theme.border
                                        Row {
                                            anchors.fill: parent; anchors.margins: 12; spacing: 12
                                            Rectangle {
                                                width: 84; height: 84; radius: 10; color: Theme.surface; clip: true; anchors.verticalCenter: parent.verticalCenter
                                                Image { anchors.fill: parent; source: root.player && root.player.trackArtUrl ? root.player.trackArtUrl : ""; fillMode: Image.PreserveAspectCrop; visible: source !== "" }
                                                Text { anchors.centerIn: parent; text: "\uf001"; color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 22; visible: !root.player || !root.player.trackArtUrl }
                                            }
                                            Column {
                                                width: parent.width - 96; anchors.verticalCenter: parent.verticalCenter; spacing: 6
                                                Text { width: parent.width; text: root.player && root.player.trackTitle ? root.player.trackTitle : "Nothing playing"; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; font.bold: true; elide: Text.ElideRight }
                                                Text { width: parent.width; text: root.player && root.player.trackArtist ? root.player.trackArtist : "No artist"; color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; elide: Text.ElideRight }
                                                Row {
                                                    spacing: 12
                                                    Text { text: "\uf048"; color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; MouseArea { anchors.fill: parent; onClicked: if (root.player && root.player.canGoPrevious) root.player.previous() } }
                                                    Text { text: root.player && root.player.isPlaying ? "\uf04c" : "\uf04b"; color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; MouseArea { anchors.fill: parent; onClicked: if (root.player && root.player.canTogglePlaying) root.player.togglePlaying() } }
                                                    Text { text: "\uf051"; color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; MouseArea { anchors.fill: parent; onClicked: if (root.player && root.player.canGoNext) root.player.next() } }
                                                }
                                            }
                                        }
                                    }

                                    // Clock card
                                    Rectangle {
                                        width: parent.width; height: parent.height - 140; radius: 14; color: Theme.surface; border.width: 1; border.color: Theme.border
                                        Row {
                                            anchors.centerIn: parent; spacing: 14
                                            Text { text: Qt.formatDateTime(clock.date, Theme.use24h ? "HH:mm" : "h:mm"); color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 28; font.bold: true }
                                            Column {
                                                anchors.verticalCenter: parent.verticalCenter
                                                Text { text: Qt.formatDateTime(clock.date, "dddd"); color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; font.bold: true }
                                                Text { text: Qt.formatDateTime(clock.date, "MMM d, yyyy"); color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                                            }
                                        }
                                    }
                                }

                                // Right 2x3 Quick Toggles
                                Grid {
                                    width: parent.width * 0.52 - 12
                                    height: parent.height
                                    columns: 2
                                    spacing: 8

                                    Rectangle {
                                        width: (parent.width - 8) / 2; height: (parent.height - 16) / 3; radius: 12
                                        color: Theme.lightMode ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25) : Theme.surface
                                        border.width: 1; border.color: Theme.accent
                                        Column { anchors.centerIn: parent; spacing: 4; Text { anchors.horizontalCenter: parent.horizontalCenter; text: Theme.lightMode ? "\uf185" : "\uf186"; color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18 } Text { anchors.horizontalCenter: parent.horizontalCenter; text: Theme.lightMode ? "Daylight" : "Nocturnal"; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 } }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: {
                                                root.open = false
                                                Theme.lightMode = !Theme.lightMode
                                                if (Theme.lightMode && Theme.accent.toString() === "#c9b8ff") Theme.accent = "#6b4ce6"
                                                else if (!Theme.lightMode && Theme.accent.toString() === "#6b4ce6") Theme.accent = "#c9b8ff"
                                                Theme.save()
                                                root.applyWallpaper(Theme.lightMode ? "wall1.jpg" : "wall0.png")
                                                Quickshell.execDetached(["quickshell", "ipc", "-p", root.homeDir + "/nocturnal/quickshell/shell.qml", "call", "splash", "play"])
                                            }
                                        }
                                    }

                                    Rectangle {
                                        width: (parent.width - 8) / 2; height: (parent.height - 16) / 3; radius: 12
                                        color: Theme.fastfetchLogo ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25) : Theme.surface
                                        border.width: Theme.fastfetchLogo ? 1 : 0; border.color: Theme.accent
                                        Column { anchors.centerIn: parent; spacing: 4; Text { anchors.horizontalCenter: parent.horizontalCenter; text: "\uf120"; color: Theme.fastfetchLogo ? Theme.accent : Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18 } Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Fastfetch"; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 } }
                                        MouseArea { anchors.fill: parent; onClicked: { Theme.fastfetchLogo = !Theme.fastfetchLogo; Theme.save() } }
                                    }

                                    Rectangle {
                                        width: (parent.width - 8) / 2; height: (parent.height - 16) / 3; radius: 12
                                        color: Theme.dockEnabled ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25) : Theme.surface
                                        border.width: Theme.dockEnabled ? 1 : 0; border.color: Theme.accent
                                        Column { anchors.centerIn: parent; spacing: 4; Text { anchors.horizontalCenter: parent.horizontalCenter; text: "\uf0c9"; color: Theme.dockEnabled ? Theme.accent : Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18 } Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Dock"; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 } }
                                        MouseArea { anchors.fill: parent; onClicked: { Theme.dockEnabled = !Theme.dockEnabled; Theme.save() } }
                                    }

                                    Rectangle {
                                        width: (parent.width - 8) / 2; height: (parent.height - 16) / 3; radius: 12
                                        color: Theme.widgetsEnabled ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25) : Theme.surface
                                        border.width: Theme.widgetsEnabled ? 1 : 0; border.color: Theme.accent
                                        Column { anchors.centerIn: parent; spacing: 4; Text { anchors.horizontalCenter: parent.horizontalCenter; text: "\uf009"; color: Theme.widgetsEnabled ? Theme.accent : Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18 } Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Widgets"; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 } }
                                        MouseArea { anchors.fill: parent; onClicked: { Theme.widgetsEnabled = !Theme.widgetsEnabled; Theme.save() } }
                                    }

                                    Rectangle {
                                        width: (parent.width - 8) / 2; height: (parent.height - 16) / 3; radius: 12
                                        color: Theme.cavaEnabled ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25) : Theme.surface
                                        border.width: Theme.cavaEnabled ? 1 : 0; border.color: Theme.accent
                                        Column { anchors.centerIn: parent; spacing: 4; Text { anchors.horizontalCenter: parent.horizontalCenter; text: "\uf001"; color: Theme.cavaEnabled ? Theme.accent : Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18 } Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Cava"; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 } }
                                        MouseArea { anchors.fill: parent; onClicked: { Theme.cavaEnabled = !Theme.cavaEnabled; Theme.save() } }
                                    }

                                    Rectangle {
                                        width: (parent.width - 8) / 2; height: (parent.height - 16) / 3; radius: 12
                                        color: Theme.blurEnabled ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25) : Theme.surface
                                        border.width: Theme.blurEnabled ? 1 : 0; border.color: Theme.accent
                                        Column { anchors.centerIn: parent; spacing: 4; Text { anchors.horizontalCenter: parent.horizontalCenter; text: "\uf0d0"; color: Theme.blurEnabled ? Theme.accent : Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18 } Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Blur"; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 } }
                                        MouseArea { anchors.fill: parent; onClicked: { Theme.blurEnabled = !Theme.blurEnabled; Theme.save(); Quickshell.execDetached(["hyprctl", "keyword", "decoration:blur:enabled", Theme.blurEnabled ? "true" : "false"]) } }
                                    }
                                }
                            }
                        }

                        // TAB 1: THEMES
                        Column {
                            visible: root.activeTab === "themes"
                            anchors.fill: parent; spacing: 10

                            Text { text: "PRESETS"; color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.bold: true }
                            Column {
                                width: parent.width; spacing: 6
                                Repeater {
                                    model: root.themePresets
                                    Rectangle {
                                        required property var modelData
                                        width: parent.width; height: 34; radius: 10
                                        color: Theme.themePreset === modelData.name ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2) : Theme.surface
                                        border.width: Theme.themePreset === modelData.name ? 1 : 0; border.color: Theme.accent
                                        Row { anchors.fill: parent; anchors.leftMargin: 12; spacing: 12; Rectangle { width: 18; height: 18; radius: 9; color: modelData.accent; anchors.verticalCenter: parent.verticalCenter } Text { text: modelData.name; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter } }
                                        MouseArea { anchors.fill: parent; onClicked: { Theme.themePreset = modelData.name; Theme.accent = modelData.accent; Theme.save() } }
                                    }
                                }
                            }

                            Text { text: "TRANSPARENCY & SHAPE"; color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.bold: true }
                            Row {
                                spacing: 8
                                Repeater {
                                    model: [{ label: "50%", val: 0.50 }, { label: "70%", val: 0.70 }, { label: "85%", val: 0.85 }, { label: "100%", val: 1.00 }]
                                    Rectangle { required property var modelData; width: 68; height: 30; radius: 8; color: Math.abs(Theme.panelOpacity - modelData.val) < 0.05 ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : Theme.surface; border.width: Math.abs(Theme.panelOpacity - modelData.val) < 0.05 ? 1 : 0; border.color: Theme.accent; Text { anchors.centerIn: parent; text: modelData.label; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 } MouseArea { anchors.fill: parent; onClicked: { Theme.panelOpacity = modelData.val; Theme.save() } } }
                                }
                            }
                            Row {
                                spacing: 8
                                Repeater {
                                    model: [{ label: "Square", val: 2 }, { label: "Soft", val: 10 }, { label: "Round", val: 18 }, { label: "Pill", val: 24 }]
                                    Rectangle { required property var modelData; width: 78; height: 30; radius: Math.min(15, modelData.val); color: Theme.shapeRadius === modelData.val ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : Theme.surface; border.width: Theme.shapeRadius === modelData.val ? 1 : 0; border.color: Theme.accent; Text { anchors.centerIn: parent; text: modelData.label; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 } MouseArea { anchors.fill: parent; onClicked: { Theme.shapeRadius = modelData.val; Theme.rounding = modelData.val; Theme.save(); Quickshell.execDetached(["hyprctl", "keyword", "decoration:rounding", String(modelData.val)]) } } }
                                }
                            }

                            Row {
                                spacing: 8
                                Rectangle { width: 110; height: 30; radius: 8; color: Theme.use24h ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : Theme.surface; border.width: Theme.use24h ? 1 : 0; border.color: Theme.accent; Text { anchors.centerIn: parent; text: Theme.use24h ? "Clock: 24h" : "Clock: 12h"; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 } MouseArea { anchors.fill: parent; onClicked: { Theme.use24h = !Theme.use24h; Theme.save() } } }
                                Repeater {
                                    model: [75, 85, 100]
                                    Rectangle { required property int modelData; width: 68; height: 30; radius: 8; color: Theme.volumeLimit === modelData ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : Theme.surface; border.width: Theme.volumeLimit === modelData ? 1 : 0; border.color: Theme.accent; Text { anchors.centerIn: parent; text: "Max " + modelData + "%"; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 } MouseArea { anchors.fill: parent; onClicked: { Theme.volumeLimit = modelData; Theme.save() } } }
                                }
                            }
                        }

                        // TAB 2: WALLPAPER
                        Column {
                            visible: root.activeTab === "wallpaper"
                            anchors.fill: parent; spacing: 10
                            Row {
                                width: parent.width
                                Text { text: "Select Wallpaper"; color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; width: parent.width - 130; anchors.verticalCenter: parent.verticalCenter }
                                Rectangle { width: 130; height: 32; radius: 8; color: Theme.surface; border.width: 1; border.color: Theme.accent; Text { anchors.centerIn: parent; text: "Browse File..."; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 } MouseArea { anchors.fill: parent; onClicked: browseWallProc.running = true } }
                            }
                            GridView {
                                width: parent.width; height: parent.height - 42; cellWidth: 162; cellHeight: 102; clip: true; model: root.wallpapers
                                delegate: Rectangle {
                                    required property string modelData
                                    width: 154; height: 94; radius: 10; color: Theme.surface; border.width: Theme.wallpaper === modelData ? 2 : 1; border.color: Theme.wallpaper === modelData ? Theme.accent : Theme.border; clip: true
                                    Image { anchors.fill: parent; anchors.margins: 2; source: "file://" + (modelData.indexOf("/") === 0 ? modelData : root.homeDir + "/nocturnal/wallpapers/" + modelData); fillMode: Image.PreserveAspectCrop; asynchronous: true }
                                    MouseArea { anchors.fill: parent; onClicked: root.applyWallpaper(modelData) }
                                }
                            }
                        }

                        // TAB 3: POSITION & WIDGETS
                        Column {
                            visible: root.activeTab === "position"
                            anchors.fill: parent; spacing: 12

                            Text { text: "WIDGETS & DOCK"; color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.bold: true }
                            Row {
                                spacing: 8
                                Rectangle { width: 130; height: 32; radius: 8; color: Theme.dockAutoHide ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : Theme.surface; border.width: Theme.dockAutoHide ? 1 : 0; border.color: Theme.accent; Text { anchors.centerIn: parent; text: Theme.dockAutoHide ? "Dock AutoHide: ON" : "Dock AutoHide: OFF"; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 } MouseArea { anchors.fill: parent; onClicked: { Theme.dockAutoHide = !Theme.dockAutoHide; Theme.save() } } }
                                Repeater {
                                    model: [{ label: "Clock", key: "widgetClock" }, { label: "Analog", key: "widgetAnalog" }, { label: "Music", key: "widgetMusic" }, { label: "Sound", key: "widgetSound" }]
                                    Rectangle { required property var modelData; width: 72; height: 32; radius: 8; color: Theme[modelData.key] ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : Theme.surface; border.width: Theme[modelData.key] ? 1 : 0; border.color: Theme.accent; Text { anchors.centerIn: parent; text: modelData.label; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 } MouseArea { anchors.fill: parent; onClicked: { Theme[modelData.key] = !Theme[modelData.key]; Theme.save() } } }
                                }
                                Rectangle { width: 64; height: 32; radius: 8; color: Theme.surface; Text { anchors.centerIn: parent; text: "Reset"; color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 } MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["quickshell", "ipc", "-p", root.homeDir + "/nocturnal/quickshell/shell.qml", "call", "widgets", "reset"]) } }
                            }

                            Text { text: "BAR POSITION"; color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.bold: true }
                            Row {
                                spacing: 8
                                Repeater { model: ["top", "bottom", "left", "right"]; Rectangle { required property string modelData; width: 88; height: 34; radius: 8; color: Theme.barPosition === modelData ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : Theme.surface; border.width: Theme.barPosition === modelData ? 1 : 0; border.color: Theme.accent; Text { anchors.centerIn: parent; text: modelData.charAt(0).toUpperCase() + modelData.slice(1); color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 } MouseArea { anchors.fill: parent; onClicked: { Theme.barPosition = modelData; Theme.save() } } } }
                            }

                            Text { text: "DOCK POSITION"; color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.bold: true }
                            Row {
                                spacing: 10
                                Repeater { model: ["left", "middle", "right"]; Rectangle { required property string modelData; width: 110; height: 34; radius: 8; color: Theme.dockPosition === modelData ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : Theme.surface; border.width: Theme.dockPosition === modelData ? 1 : 0; border.color: Theme.accent; Text { anchors.centerIn: parent; text: modelData.charAt(0).toUpperCase() + modelData.slice(1); color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 } MouseArea { anchors.fill: parent; onClicked: { Theme.dockPosition = modelData; Theme.save() } } } }
                            }

                            Text { text: "APP CHOOSER POSITION"; color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.bold: true }
                            Row {
                                spacing: 10
                                Repeater { model: ["left", "middle", "right"]; Rectangle { required property string modelData; width: 110; height: 34; radius: 8; color: Theme.launcherPosition === modelData ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : Theme.surface; border.width: Theme.launcherPosition === modelData ? 1 : 0; border.color: Theme.accent; Text { anchors.centerIn: parent; text: modelData.charAt(0).toUpperCase() + modelData.slice(1); color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 } MouseArea { anchors.fill: parent; onClicked: { Theme.launcherPosition = modelData; Theme.save() } } } }
                            }
                        }

                        // TAB 4: ABOUT & UPDATES
                        Column {
                            visible: root.activeTab === "about"
                            anchors.fill: parent; spacing: 14

                            Row {
                                spacing: 14
                                MoonLogo { width: 52; height: 52; anchors.verticalCenter: parent.verticalCenter }
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2
                                    Text { text: Theme.lightMode ? "Daylight Shell" : "Nocturnal Shell"; color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 22; font.bold: true }
                                    Text { text: "Made by rig • Built off Hyprland"; color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 74
                                radius: 12
                                color: Theme.surface
                                border.width: 1
                                border.color: Theme.accent

                                Row {
                                    anchors.fill: parent
                                    anchors.margins: 14
                                    spacing: 14

                                    Rectangle {
                                        width: 44; height: 44; radius: 10
                                        color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2)
                                        anchors.verticalCenter: parent.verticalCenter
                                        Text {
                                            anchors.centerIn: parent
                                            text: Theme.lightMode ? "\uf185" : "\uf186"
                                            color: Theme.accent
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 20
                                        }
                                    }

                                    Column {
                                        width: parent.width - 170
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 3
                                        Text {
                                            text: "Version v" + root.localVer
                                            color: Theme.text
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 15
                                            font.bold: true
                                        }
                                        Text {
                                            text: "Codename: \"" + root.codename + "\""
                                            color: Theme.accent
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 12
                                            font.bold: true
                                        }
                                    }

                                    Rectangle {
                                        width: 96; height: 28; radius: 14
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18)
                                        border.width: 1; border.color: Theme.accent
                                        Text {
                                            anchors.centerIn: parent
                                            text: Theme.lightMode ? "Daylight" : "Nocturnal"
                                            color: Theme.accent
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 11
                                            font.bold: true
                                        }
                                    }
                                }
                            }

                            Rectangle { width: parent.width; height: 1; color: Theme.border }
                            Column {
                                spacing: 6
                                Text { text: "Compositor: Hyprland (Lua)"; color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
                                Text { text: "Shell UI:   Quickshell (QML)"; color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
                                Text { text: "OS:         " + root.osPretty; color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
                            }
                            Row {
                                spacing: 10
                                Rectangle { width: 170; height: 34; radius: 8; color: Theme.surface; border.width: 1; border.color: Theme.accent; Text { anchors.centerIn: parent; text: "Check for Updates"; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 } MouseArea { anchors.fill: parent; onClicked: { root.updateMsg = "Checking..."; checkUpdProc.running = true } } }
                                Rectangle { visible: root.remoteVer !== "" && root.remoteVer !== root.localVer; width: 130; height: 34; radius: 8; color: Theme.accent; Text { anchors.centerIn: parent; text: "Update Now"; color: Theme.lightMode ? "#ffffff" : "#12131a"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; font.bold: true } MouseArea { anchors.fill: parent; onClicked: { root.open = false; Quickshell.execDetached(["quickshell", "ipc", "-p", root.homeDir + "/nocturnal/quickshell/shell.qml", "call", "updater", "start", root.remoteVer]) } } }
                            }
                            Text { visible: root.updateMsg !== ""; text: root.updateMsg; color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                        }
                    }
                }
            }
        }
    }
}
