import Quickshell
import Quickshell.Io
import QtQuick

Scope {
    id: root
    property bool open: false
    property string activeTab: "themes"
    property var wallpapers: []
    property string homeDir: Quickshell.env("HOME") || ""
    property string osPretty: "Linux"
    property string localVer: "1.2.0"
    property string remoteVer: ""
    property string updateMsg: ""

    readonly property var themePresets: [
        { name: "Nocturnal", bg: "#12131a", accent: "#c9b8ff" },
        { name: "Midnight",  bg: "#0e1420", accent: "#89dceb" },
        { name: "Forest",    bg: "#101714", accent: "#a6e3a1" },
        { name: "Ember",     bg: "#1a1214", accent: "#fab387" },
        { name: "Crimson",   bg: "#191116", accent: "#f38ba8" }
    ]

    IpcHandler {
        target: "settings"
        function toggle(): void { root.open = !root.open }
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
        command: ["sh", "-c", "cat \"$HOME/nocturnal/VERSION\" 2>/dev/null || echo 1.2.0"]
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
        command: ["sh", "-c", ". /etc/os-release 2>/dev/null && echo \"${PRETTY_NAME:-Linux}\""]
        stdout: StdioCollector { id: osCol; onStreamFinished: { var s = osCol.text.trim(); if (s) root.osPretty = s } }
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
        visible: root.open || card.opacity > 0.01
        focusable: true
        exclusionMode: ExclusionMode.Ignore

        implicitWidth: 660
        implicitHeight: 610
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
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            Row {
                anchors.fill: parent

                Item {
                    width: parent.width - 165
                    height: parent.height

                    // TAB 1: THEMES
                    Column {
                        visible: root.activeTab === "themes"
                        anchors.fill: parent; anchors.margins: 20; spacing: 12

                        Row {
                            width: parent.width
                            Text { text: "Themes & Colors"; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 17; font.bold: true; width: parent.width - 154; anchors.verticalCenter: parent.verticalCenter }
                            Rectangle {
                                width: 154; height: 32; radius: 16
                                color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22)
                                border.width: 1; border.color: Theme.accent
                                Text { anchors.centerIn: parent; text: Theme.lightMode ? "☀ Daylight" : "🌙 Nocturnal"; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; font.bold: true }
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
                        }

                        Text { text: "PRESETS"; color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.bold: true }

                        Column {
                            width: parent.width; spacing: 6
                            Repeater {
                                model: root.themePresets
                                Rectangle {
                                    required property var modelData
                                    width: parent.width; height: 36; radius: 10
                                    color: Theme.themePreset === modelData.name ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.2) : (pMouse.containsMouse ? Theme.surface : Theme.surface)
                                    border.width: Theme.themePreset === modelData.name ? 1 : 0; border.color: Theme.accent
                                    Row {
                                        anchors.fill: parent; anchors.leftMargin: 12; spacing: 12
                                        Rectangle { width: 20; height: 20; radius: 10; color: modelData.accent; anchors.verticalCenter: parent.verticalCenter }
                                        Text { text: modelData.name; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; font.bold: Theme.themePreset === modelData.name; anchors.verticalCenter: parent.verticalCenter }
                                    }
                                    MouseArea { id: pMouse; anchors.fill: parent; hoverEnabled: true; onClicked: { Theme.themePreset = modelData.name; Theme.accent = modelData.accent; Theme.save() } }
                                }
                            }
                        }

                        Column {
                            width: parent.width; spacing: 6
                            Text { text: "TRANSPARENCY"; color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.bold: true }
                            Row {
                                spacing: 8
                                Repeater {
                                    model: [{ label: "50%", val: 0.50 }, { label: "70%", val: 0.70 }, { label: "85%", val: 0.85 }, { label: "100%", val: 1.00 }]
                                    Rectangle {
                                        required property var modelData
                                        width: 68; height: 32; radius: 8
                                        color: Math.abs(Theme.panelOpacity - modelData.val) < 0.05 ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : Theme.surface
                                        border.width: Math.abs(Theme.panelOpacity - modelData.val) < 0.05 ? 1 : 0; border.color: Theme.accent
                                        Text { anchors.centerIn: parent; text: modelData.label; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                                        MouseArea { anchors.fill: parent; onClicked: { Theme.panelOpacity = modelData.val; Theme.save() } }
                                    }
                                }
                            }
                        }

                        Row {
                            width: parent.width; spacing: 8
                            Rectangle {
                                width: 116; height: 32; radius: 8
                                color: Theme.use24h ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : Theme.surface
                                border.width: Theme.use24h ? 1 : 0; border.color: Theme.accent
                                Text { anchors.centerIn: parent; text: Theme.use24h ? "Clock: 24h" : "Clock: 12h"; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                                MouseArea { anchors.fill: parent; onClicked: { Theme.use24h = !Theme.use24h; Theme.save() } }
                            }
                            Repeater {
                                model: [75, 85, 100]
                                Rectangle {
                                    required property int modelData
                                    width: 68; height: 32; radius: 8
                                    color: Theme.volumeLimit === modelData ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : Theme.surface
                                    border.width: Theme.volumeLimit === modelData ? 1 : 0; border.color: Theme.accent
                                    Text { anchors.centerIn: parent; text: "Max " + modelData + "%"; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                                    MouseArea { anchors.fill: parent; onClicked: { Theme.volumeLimit = modelData; Theme.save() } }
                                }
                            }
                        }

                        Column {
                            width: parent.width; spacing: 6
                            Text { text: "SHAPE"; color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.bold: true }
                            Row {
                                spacing: 8
                                Repeater {
                                    model: [{ label: "Square", val: 2 }, { label: "Soft", val: 10 }, { label: "Round", val: 18 }, { label: "Pill", val: 24 }]
                                    Rectangle {
                                        required property var modelData
                                        width: 78; height: 32; radius: Math.min(16, modelData.val)
                                        color: Theme.shapeRadius === modelData.val ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : Theme.surface
                                        border.width: Theme.shapeRadius === modelData.val ? 1 : 0; border.color: Theme.accent
                                        Text { anchors.centerIn: parent; text: modelData.label; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                                        MouseArea { anchors.fill: parent; onClicked: { Theme.shapeRadius = modelData.val; Theme.rounding = modelData.val; Theme.save(); Quickshell.execDetached(["hyprctl", "keyword", "decoration:rounding", String(modelData.val)]) } }
                                    }
                                }
                            }
                        }
                    }

                    // TAB 2: WALLPAPER
                    Column {
                        visible: root.activeTab === "wallpaper"
                        anchors.fill: parent; anchors.margins: 20; spacing: 12

                        Row {
                            width: parent.width
                            Text { text: "Wallpaper"; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 17; font.bold: true; width: parent.width - 130; anchors.verticalCenter: parent.verticalCenter }
                            Rectangle {
                                width: 130; height: 32; radius: 8
                                color: browseMouse.containsMouse ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : Theme.surface
                                border.width: 1; border.color: Theme.accent
                                Text { anchors.centerIn: parent; text: "Browse File..."; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                                MouseArea { id: browseMouse; anchors.fill: parent; hoverEnabled: true; onClicked: browseWallProc.running = true }
                            }
                        }

                        GridView {
                            width: parent.width; height: parent.height - 50
                            cellWidth: 148; cellHeight: 96; clip: true; model: root.wallpapers
                            delegate: Rectangle {
                                required property string modelData
                                width: 140; height: 88; radius: 10; color: Theme.surface
                                border.width: Theme.wallpaper === modelData ? 2 : 1
                                border.color: Theme.wallpaper === modelData ? Theme.accent : Theme.border
                                clip: true
                                Image { anchors.fill: parent; anchors.margins: 2; source: "file://" + (modelData.indexOf("/") === 0 ? modelData : root.homeDir + "/nocturnal/wallpapers/" + modelData); fillMode: Image.PreserveAspectCrop; asynchronous: true }
                                MouseArea { anchors.fill: parent; onClicked: root.applyWallpaper(modelData) }
                            }
                        }
                    }

                    // TAB 3: POSITION & WIDGETS
                    Column {
                        visible: root.activeTab === "position"
                        anchors.fill: parent; anchors.margins: 20; spacing: 14

                        Text { text: "Widgets & Position"; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 17; font.bold: true }

                        Column {
                            width: parent.width; spacing: 8
                            Text { text: "SHOW / HIDE"; color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.bold: true }
                            Row {
                                spacing: 8
                                Rectangle { width: 110; height: 34; radius: 8; color: Theme.dockEnabled ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : Theme.surface; border.width: Theme.dockEnabled ? 1 : 0; border.color: Theme.accent; Text { anchors.centerIn: parent; text: Theme.dockEnabled ? "Dock: ON" : "Dock: OFF"; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 } MouseArea { anchors.fill: parent; onClicked: { Theme.dockEnabled = !Theme.dockEnabled; Theme.save() } } }
                                Rectangle { width: 132; height: 34; radius: 8; color: Theme.dockAutoHide ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : Theme.surface; border.width: Theme.dockAutoHide ? 1 : 0; border.color: Theme.accent; Text { anchors.centerIn: parent; text: Theme.dockAutoHide ? "Auto-Hide: ON" : "Auto-Hide: OFF"; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 } MouseArea { anchors.fill: parent; onClicked: { Theme.dockAutoHide = !Theme.dockAutoHide; Theme.save() } } }
                                Rectangle { width: 120; height: 34; radius: 8; color: Theme.widgetsEnabled ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : Theme.surface; border.width: Theme.widgetsEnabled ? 1 : 0; border.color: Theme.accent; Text { anchors.centerIn: parent; text: Theme.widgetsEnabled ? "Widgets: ON" : "Widgets: OFF"; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 } MouseArea { anchors.fill: parent; onClicked: { Theme.widgetsEnabled = !Theme.widgetsEnabled; Theme.save() } } }
                            }
                            Row {
                                spacing: 6
                                Repeater {
                                    model: [{ label: "Clock", key: "widgetClock" }, { label: "Analog", key: "widgetAnalog" }, { label: "Music", key: "widgetMusic" }, { label: "Sound", key: "widgetSound" }]
                                    Rectangle { required property var modelData; width: 78; height: 30; radius: 8; color: Theme[modelData.key] ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : Theme.surface; border.width: Theme[modelData.key] ? 1 : 0; border.color: Theme.accent; Text { anchors.centerIn: parent; text: modelData.label; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 } MouseArea { anchors.fill: parent; onClicked: { Theme[modelData.key] = !Theme[modelData.key]; Theme.save() } } }
                                }
                                Rectangle { width: 76; height: 30; radius: 8; color: Theme.surface; Text { anchors.centerIn: parent; text: "Reset"; color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 } MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["quickshell", "ipc", "-p", root.homeDir + "/nocturnal/quickshell/shell.qml", "call", "widgets", "reset"]) } }
                            }
                            Rectangle { width: 140; height: 32; radius: 8; color: Theme.cavaEnabled ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : Theme.surface; border.width: Theme.cavaEnabled ? 1 : 0; border.color: Theme.accent; Text { anchors.centerIn: parent; text: Theme.cavaEnabled ? "Cava: ON" : "Cava: OFF"; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 } MouseArea { anchors.fill: parent; onClicked: { Theme.cavaEnabled = !Theme.cavaEnabled; Theme.save() } } }
                        }

                        Column {
                            width: parent.width; spacing: 8
                            Text { text: "BAR POSITION"; color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.bold: true }
                            Row {
                                spacing: 8
                                Repeater {
                                    model: ["top", "bottom", "left", "right"]
                                    Rectangle { required property string modelData; width: 82; height: 34; radius: 8; color: Theme.barPosition === modelData ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : Theme.surface; border.width: Theme.barPosition === modelData ? 1 : 0; border.color: Theme.accent; Text { anchors.centerIn: parent; text: modelData.charAt(0).toUpperCase() + modelData.slice(1); color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 } MouseArea { anchors.fill: parent; onClicked: { Theme.barPosition = modelData; Theme.save() } } }
                                }
                            }
                        }

                        Column {
                            width: parent.width; spacing: 8
                            Text { text: "DOCK POSITION"; color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.bold: true }
                            Row {
                                spacing: 10
                                Repeater {
                                    model: ["left", "middle", "right"]
                                    Rectangle { required property string modelData; width: 110; height: 34; radius: 8; color: Theme.dockPosition === modelData ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : Theme.surface; border.width: Theme.dockPosition === modelData ? 1 : 0; border.color: Theme.accent; Text { anchors.centerIn: parent; text: modelData.charAt(0).toUpperCase() + modelData.slice(1); color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 } MouseArea { anchors.fill: parent; onClicked: { Theme.dockPosition = modelData; Theme.save() } } }
                                }
                            }
                        }

                        Column {
                            width: parent.width; spacing: 8
                            Text { text: "APP CHOOSER POSITION"; color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.bold: true }
                            Row {
                                spacing: 10
                                Repeater {
                                    model: ["left", "middle", "right"]
                                    Rectangle { required property string modelData; width: 110; height: 34; radius: 8; color: Theme.launcherPosition === modelData ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : Theme.surface; border.width: Theme.launcherPosition === modelData ? 1 : 0; border.color: Theme.accent; Text { anchors.centerIn: parent; text: modelData.charAt(0).toUpperCase() + modelData.slice(1); color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 } MouseArea { anchors.fill: parent; onClicked: { Theme.launcherPosition = modelData; Theme.save() } } }
                                }
                            }
                        }
                    }

                    // TAB 4: ABOUT & UPDATES
                    Column {
                        visible: root.activeTab === "about"
                        anchors.fill: parent; anchors.margins: 24; spacing: 14

                        Row {
                            spacing: 14
                            MoonLogo { width: 52; height: 52; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: Theme.lightMode ? "Daylight Shell" : "Nocturnal Shell"; color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 22; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
                        }

                        Text { text: "Made by rig\nBuilt off Hyprland"; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; lineHeight: 1.5 }
                        Rectangle { width: parent.width; height: 1; color: Theme.border }
                        Column {
                            spacing: 8
                            Text { text: "Compositor: Hyprland (Lua)"; color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
                            Text { text: "Shell UI:   Quickshell (QML)"; color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
                            Text { text: "OS:         " + root.osPretty; color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13 }
                            Text { text: "Version:    v" + root.localVer; color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; font.bold: true }
                        }

                        Row {
                            spacing: 10
                            Rectangle {
                                width: 170; height: 34; radius: 8
                                color: Theme.surface; border.width: 1; border.color: Theme.accent
                                Text { anchors.centerIn: parent; text: "Check for Updates"; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                                MouseArea { anchors.fill: parent; onClicked: { root.updateMsg = "Checking..."; checkUpdProc.running = true } }
                            }
                            Rectangle {
                                visible: root.remoteVer !== "" && root.remoteVer !== root.localVer
                                width: 130; height: 34; radius: 8; color: Theme.accent
                                Text { anchors.centerIn: parent; text: "Update Now"; color: Theme.lightMode ? "#ffffff" : "#12131a"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; font.bold: true }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        root.open = false
                                        Quickshell.execDetached(["quickshell", "ipc", "-p", root.homeDir + "/nocturnal/quickshell/shell.qml", "call", "updater", "start", root.remoteVer])
                                    }
                                }
                            }
                        }

                        Text { visible: root.updateMsg !== ""; text: root.updateMsg; color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                    }
                }

                Rectangle { width: 1; height: parent.height; color: Theme.border }

                Column {
                    width: 164; height: parent.height; padding: 14; spacing: 8
                    Row {
                        width: parent.width - 28
                        Text { text: "Settings"; color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; font.bold: true; width: parent.width - 22; anchors.verticalCenter: parent.verticalCenter }
                        Text { text: "✕"; color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 15; MouseArea { anchors.fill: parent; onClicked: root.open = false } }
                    }
                    Item { width: 1; height: 6 }
                    Repeater {
                        model: [{ id: "themes", label: "Themes" }, { id: "wallpaper", label: "Wallpaper" }, { id: "position", label: "Position" }, { id: "about", label: "About" }]
                        Rectangle {
                            required property var modelData
                            width: parent.width - 28; height: 38; radius: 8
                            color: root.activeTab === modelData.id ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : (tabMouse.containsMouse ? Theme.surface : "transparent")
                            border.width: root.activeTab === modelData.id ? 1 : 0; border.color: Theme.accent
                            Text { anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: 12; text: modelData.label; color: root.activeTab === modelData.id ? Theme.accent : Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; font.bold: root.activeTab === modelData.id }
                            MouseArea { id: tabMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.activeTab = modelData.id }
                        }
                    }
                }
            }
        }
    }
}
