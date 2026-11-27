import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

Item {
    id: root
    property bool open: false
    property var targetScreen: null
    property string activeTab: "dashboard"

    property bool wifiOn: false
    property bool btOn: false
    property bool gameMode: false
    property bool airplaneMode: false
    property bool keepAwake: false

    property string weatherTemp: "--°F"
    property string weatherCond: "Weather"
    property string uptimeStr: "up 0m"
    property int cpuPct: 0
    property int ramPct: 0
    property int swapPct: 0
    property int calOffset: 0
    property var wallpapers: []

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool audioReady: sink !== null && sink.audio !== null
    readonly property bool audioMuted: audioReady ? sink.audio.muted : false

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    onOpenChanged: {
        if (open) {
            statusProc.running = true
            dashProc.running = true
            wallProc.running = true
        }
    }

    Process {
        id: statusProc
        command: ["sh", "-c", "w=$(nmcli radio wifi 2>/dev/null || echo off); b=$(bluetoothctl show 2>/dev/null | grep -q 'Powered: yes' && echo on || echo off); k=$(pgrep -f 'systemd-inhibit.*nocturnal' >/dev/null && echo on || echo off); echo \"$w|$b|$k\""]
        stdout: StdioCollector {
            id: sCol
            onStreamFinished: {
                var p = sCol.text.trim().split("|")
                root.wifiOn = (p[0] === "enabled")
                root.btOn = (p[1] === "on")
                root.keepAwake = (p[2] === "on")
            }
        }
    }

    Process {
        id: dashProc
        command: ["sh", "-c",
            "up=$(uptime -p 2>/dev/null | sed 's/up /up /'); " +
            "c=$(grep -m1 'cpu ' /proc/stat | awk '{u=$2+$4; t=$2+$4+$5; if(t>0) printf \"%d\", u*100/t; else print 0}'); " +
            "r=$(free -m | awk '/Mem:/ {if($2>0) printf \"%d\", $3*100/$2; else print 0}'); " +
            "s=$(free -m | awk '/Swap:/ {if($2>0) printf \"%d\", $3*100/$2; else print 0}'); " +
            "w=$(curl -s -m 5 'wttr.in/?u&format=%t|%C' 2>/dev/null); " +
            "echo \"$up|$c|$r|$s|$w\""
        ]
        stdout: StdioCollector {
            id: dCol
            onStreamFinished: {
                var p = dCol.text.trim().split("|")
                if (p.length >= 4) {
                    root.uptimeStr = p[0] || "up 0m"
                    root.cpuPct = parseInt(p[1]) || 0
                    root.ramPct = parseInt(p[2]) || 0
                    root.swapPct = parseInt(p[3]) || 0
                }
                if (p.length >= 6 && p[4].indexOf("°") >= 0) {
                    root.weatherTemp = p[4].replace(/^\+/, "")
                    root.weatherCond = p[5]
                }
            }
        }
    }

    Process {
        id: wallProc
        command: ["sh", "-c", "find \"$HOME/nocturnal/wallpapers\" \"$HOME/Pictures/Wallpapers\" -maxdepth 1 -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\) 2>/dev/null | sort"]
        stdout: StdioCollector {
            id: wCol
            onStreamFinished: root.wallpapers = wCol.text.trim().split("\n").filter(l => l.length > 0)
        }
    }

    Timer {
        interval: 3000
        running: root.open
        repeat: true
        onTriggered: dashProc.running = true
    }

    readonly property string greeting: {
        var h = clock.date.getHours()
        if (h < 12) return "Good morning, Rig"
        if (h < 18) return "Good afternoon, Rig"
        return "Good evening, Rig"
    }

    readonly property var calData: {
        var now = clock.date
        var view = new Date(now.getFullYear(), now.getMonth() + root.calOffset, 1)
        var y = view.getFullYear()
        var m = view.getMonth()
        var first = (view.getDay() + 6) % 7 // Monday-start
        var daysInMonth = new Date(y, m + 1, 0).getDate()
        var prevDays = new Date(y, m, 0).getDate()
        var cells = []
        for (var i = first - 1; i >= 0; i--) cells.push({ d: prevDays - i, cur: false, today: false })
        for (var d = 1; d <= daysInMonth; d++) {
            var isToday = (root.calOffset === 0 && d === now.getDate())
            cells.push({ d: d, cur: true, today: isToday })
        }
        while (cells.length < 42) cells.push({ d: cells.length - (first + daysInMonth) + 1, cur: false, today: false })
        return { title: Qt.formatDateTime(view, "MMMM yyyy"), cells: cells }
    }

    PanelWindow {
        id: win
        screen: root.targetScreen
        visible: root.open || card.opacity > 0.01
        exclusionMode: ExclusionMode.Ignore

        anchors { top: true }
        margins { top: 52 }
        implicitWidth: 680
        implicitHeight: 410
        color: "transparent"

        Rectangle {
            id: card
            anchors.fill: parent
            radius: Theme.shapeRadius
            color: Theme.panelBg
            border.width: 1
            border.color: "#22ffffff"

            opacity: root.open ? 1 : 0
            transform: Translate { y: root.open ? 0 : -14 }
            Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

            Column {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                // TOP TAB BAR
                Row {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: [
                            { id: "dashboard", icon: "\uf009", label: "Dashboard" },
                            { id: "toggles",   icon: "\uf205", label: "Toggles" },
                            { id: "wallpaper", icon: "\uf03e", label: "Wallpaper" }
                        ]

                        Rectangle {
                            required property var modelData
                            width: (parent.width - 16) / 3
                            height: 36
                            radius: 18
                            color: root.activeTab === modelData.id ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25) : "transparent"
                            Behavior on color { ColorAnimation { duration: 160 } }

                            Row {
                                anchors.centerIn: parent
                                spacing: 8
                                Text {
                                    text: modelData.icon
                                    color: root.activeTab === modelData.id ? Theme.accent : "#b8b3d6"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    text: modelData.label
                                    color: root.activeTab === modelData.id ? "#e6e1ff" : "#b8b3d6"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                    font.bold: root.activeTab === modelData.id
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.activeTab = modelData.id
                            }
                        }
                    }
                }

                // TAB 1: DASHBOARD (assd.png layout)
                Row {
                    opacity: root.activeTab === "dashboard" ? 1 : 0
                    visible: opacity > 0.01
                    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    transform: Translate { y: root.activeTab === "dashboard" ? 0 : 8; Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } } }
                    width: parent.width
                    height: parent.height - 48
                    spacing: 10

                    // Left vertical stacked clock
                    Rectangle {
                        width: 96
                        height: parent.height
                        radius: 14
                        color: "#14ffffff"

                        Column {
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Qt.formatDateTime(clock.date, "HH")
                                color: "#e6e1ff"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 34
                                font.bold: true
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Qt.formatDateTime(clock.date, "mm")
                                color: Theme.accent
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 34
                                font.bold: true
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Qt.formatDateTime(clock.date, "ddd").toUpperCase()
                                color: "#88e6e1ff"
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                            }
                        }
                    }

                    // Center: Weather + Greeting row, and Calendar below
                    Column {
                        width: parent.width - 212
                        height: parent.height
                        spacing: 10

                        Row {
                            width: parent.width
                            height: 76
                            spacing: 10

                            // Weather card
                            Rectangle {
                                width: (parent.width - 10) * 0.45
                                height: parent.height
                                radius: 14
                                color: "#14ffffff"

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 10
                                    Text {
                                        text: "\uf0c2"
                                        color: Theme.accent
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 22
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        Text {
                                            text: root.weatherTemp
                                            color: "#e6e1ff"
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 18
                                            font.bold: true
                                        }
                                        Text {
                                            text: root.weatherCond
                                            color: "#99e6e1ff"
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                            width: 95
                                        }
                                    }
                                }
                            }

                            // Greeting card
                            Rectangle {
                                width: (parent.width - 10) * 0.55
                                height: parent.height
                                radius: 14
                                color: "#14ffffff"

                                Column {
                                    anchors.centerIn: parent
                                    width: parent.width - 20
                                    spacing: 6

                                    Text {
                                        text: root.greeting
                                        color: "#e6e1ff"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 13
                                        font.bold: true
                                        elide: Text.ElideRight
                                        width: parent.width
                                    }

                                    Row {
                                        spacing: 6
                                        Rectangle {
                                            width: 96; height: 22; radius: 11
                                            color: "#1affffff"
                                            Text {
                                                anchors.centerIn: parent
                                                text: "\uf109 Gentoo"
                                                color: "#b8b3d6"
                                                font.family: "JetBrainsMono Nerd Font"
                                                font.pixelSize: 10
                                            }
                                        }
                                        Rectangle {
                                            width: 82; height: 22; radius: 11
                                            color: "#1affffff"
                                            Text {
                                                anchors.centerIn: parent
                                                text: "\uf017 " + root.uptimeStr
                                                color: "#b8b3d6"
                                                font.family: "JetBrainsMono Nerd Font"
                                                font.pixelSize: 10
                                                elide: Text.ElideRight
                                                width: 72
                                                horizontalAlignment: Text.AlignHCenter
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Calendar Card
                        Rectangle {
                            width: parent.width
                            height: parent.height - 86
                            radius: 14
                            color: "#14ffffff"

                            Column {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 6

                                Row {
                                    width: parent.width
                                    Text {
                                        text: root.calData.title
                                        color: "#e6e1ff"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 14
                                        font.bold: true
                                        width: parent.width - 56
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Row {
                                        spacing: 6
                                        Rectangle {
                                            width: 24; height: 24; radius: 12; color: "#1affffff"
                                            Text { anchors.centerIn: parent; text: "<"; color: "#e6e1ff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                                            MouseArea { anchors.fill: parent; onClicked: root.calOffset-- }
                                        }
                                        Rectangle {
                                            width: 24; height: 24; radius: 12; color: "#1affffff"
                                            Text { anchors.centerIn: parent; text: ">"; color: "#e6e1ff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                                            MouseArea { anchors.fill: parent; onClicked: root.calOffset++ }
                                        }
                                    }
                                }

                                Grid {
                                    width: parent.width
                                    columns: 7
                                    Repeater {
                                        model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                                        Text {
                                            required property string modelData
                                            width: (parent.width) / 7
                                            horizontalAlignment: Text.AlignHCenter
                                            text: modelData
                                            color: "#88e6e1ff"
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 11
                                        }
                                    }
                                }

                                Grid {
                                    width: parent.width
                                    columns: 7
                                    rowSpacing: 2
                                    Repeater {
                                        model: root.calData.cells
                                        Rectangle {
                                            required property var modelData
                                            width: (parent.width) / 7
                                            height: 26
                                            radius: 8
                                            color: modelData.today ? Theme.accent : "transparent"

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.d
                                                color: modelData.today ? "#12131a" : (modelData.cur ? "#e6e1ff" : "#44e6e1ff")
                                                font.family: "JetBrainsMono Nerd Font"
                                                font.pixelSize: 12
                                                font.bold: modelData.today
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Right vertical performance rings (CPU, RAM, Swap)
                    Rectangle {
                        width: 96
                        height: parent.height
                        radius: 14
                        color: "#14ffffff"

                        Column {
                            anchors.centerIn: parent
                            spacing: 14

                            Repeater {
                                model: [
                                    { label: "CPU",  val: root.cpuPct },
                                    { label: "RAM",  val: root.ramPct },
                                    { label: "Swap", val: root.swapPct }
                                ]

                                Item {
                                    required property var modelData
                                    width: 74
                                    height: 74

                                    Canvas {
                                        anchors.fill: parent
                                        property int pct: modelData.val
                                        onPctChanged: requestPaint()
                                        onPaint: {
                                            var ctx = getContext("2d")
                                            ctx.reset()
                                            var cx = width / 2, cy = height / 2, r = 30
                                            ctx.lineWidth = 5
                                            ctx.lineCap = "round"
                                            ctx.strokeStyle = "#22ffffff"
                                            ctx.beginPath()
                                            ctx.arc(cx, cy, r, 0, Math.PI * 2)
                                            ctx.stroke()
                                            if (pct > 0) {
                                                ctx.strokeStyle = Theme.accent
                                                ctx.beginPath()
                                                ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + (Math.PI * 2 * Math.min(100, pct) / 100))
                                                ctx.stroke()
                                            }
                                        }
                                    }

                                    Column {
                                        anchors.centerIn: parent
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: modelData.val + "%"
                                            color: "#e6e1ff"
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 12
                                            font.bold: true
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: modelData.label
                                            color: "#88e6e1ff"
                                            font.family: "JetBrainsMono Nerd Font"
                                            font.pixelSize: 10
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // TAB 2: QUICK TOGGLES (Wi-Fi, Bluetooth, Audio, Game Mode, Airplane Mode, Keep Awake, Blur, Dock)
                Grid {
                    opacity: root.activeTab === "toggles" ? 1 : 0
                    visible: opacity > 0.01
                    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    transform: Translate { y: root.activeTab === "toggles" ? 0 : 8; Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } } }
                    width: parent.width
                    columns: 2
                    spacing: 10

                    // 1. Wi-Fi
                    Rectangle {
                        width: (parent.width - 10) / 2; height: 64; radius: 12
                        color: root.wifiOn ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : "#14ffffff"
                        border.width: root.wifiOn ? 1 : 0; border.color: Theme.accent
                        Row {
                            anchors.fill: parent; anchors.leftMargin: 14; spacing: 12
                            Text { text: "\uf1eb"; color: root.wifiOn ? Theme.accent : "#88e6e1ff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18; anchors.verticalCenter: parent.verticalCenter }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                Text { text: "Wi-Fi"; color: "#e6e1ff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; font.bold: true }
                                Text { text: root.wifiOn ? "On" : "Off"; color: "#99e6e1ff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                            }
                        }
                        MouseArea { anchors.fill: parent; onClicked: { root.wifiOn = !root.wifiOn; Quickshell.execDetached(["nmcli", "radio", "wifi", root.wifiOn ? "on" : "off"]) } }
                    }

                    // 2. Bluetooth
                    Rectangle {
                        width: (parent.width - 10) / 2; height: 64; radius: 12
                        color: root.btOn ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : "#14ffffff"
                        border.width: root.btOn ? 1 : 0; border.color: Theme.accent
                        Row {
                            anchors.fill: parent; anchors.leftMargin: 14; spacing: 12
                            Text { text: "\uf293"; color: root.btOn ? Theme.accent : "#88e6e1ff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18; anchors.verticalCenter: parent.verticalCenter }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                Text { text: "Bluetooth"; color: "#e6e1ff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; font.bold: true }
                                Text { text: root.btOn ? "On" : "Off"; color: "#99e6e1ff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                            }
                        }
                        MouseArea { anchors.fill: parent; onClicked: { root.btOn = !root.btOn; Quickshell.execDetached(["bluetoothctl", "power", root.btOn ? "on" : "off"]) } }
                    }

                    // 3. Game Mode
                    Rectangle {
                        width: (parent.width - 10) / 2; height: 64; radius: 12
                        color: root.gameMode ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : "#14ffffff"
                        border.width: root.gameMode ? 1 : 0; border.color: Theme.accent
                        Row {
                            anchors.fill: parent; anchors.leftMargin: 14; spacing: 12
                            Text { text: "\uf11b"; color: root.gameMode ? Theme.accent : "#88e6e1ff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18; anchors.verticalCenter: parent.verticalCenter }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                Text { text: "Game Mode"; color: "#e6e1ff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; font.bold: true }
                                Text { text: root.gameMode ? "Performance" : "Off"; color: "#99e6e1ff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.gameMode = !root.gameMode
                                if (root.gameMode) {
                                    Quickshell.execDetached(["sh", "-c", "hyprctl --batch 'keyword decoration:blur:enabled false; keyword decoration:rounding 0; keyword animations:enabled false'"])
                                } else {
                                    Quickshell.execDetached(["sh", "-c", "hyprctl --batch 'keyword decoration:blur:enabled " + (Theme.blurEnabled ? "true" : "false") + "; keyword decoration:rounding " + Theme.rounding + "'"])
                                }
                            }
                        }
                    }

                    // 4. Airplane Mode
                    Rectangle {
                        width: (parent.width - 10) / 2; height: 64; radius: 12
                        color: root.airplaneMode ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : "#14ffffff"
                        border.width: root.airplaneMode ? 1 : 0; border.color: Theme.accent
                        Row {
                            anchors.fill: parent; anchors.leftMargin: 14; spacing: 12
                            Text { text: "\uf072"; color: root.airplaneMode ? Theme.accent : "#88e6e1ff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18; anchors.verticalCenter: parent.verticalCenter }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                Text { text: "Airplane Mode"; color: "#e6e1ff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; font.bold: true }
                                Text { text: root.airplaneMode ? "On" : "Off"; color: "#99e6e1ff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.airplaneMode = !root.airplaneMode
                                if (root.airplaneMode) {
                                    root.wifiOn = false; root.btOn = false
                                    Quickshell.execDetached(["sh", "-c", "nmcli radio all off; bluetoothctl power off"])
                                } else {
                                    root.wifiOn = true
                                    Quickshell.execDetached(["nmcli", "radio", "all", "on"])
                                }
                            }
                        }
                    }

                    // 5. Keep Awake
                    Rectangle {
                        width: (parent.width - 10) / 2; height: 64; radius: 12
                        color: root.keepAwake ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : "#14ffffff"
                        border.width: root.keepAwake ? 1 : 0; border.color: Theme.accent
                        Row {
                            anchors.fill: parent; anchors.leftMargin: 14; spacing: 12
                            Text { text: "\uf0f4"; color: root.keepAwake ? Theme.accent : "#88e6e1ff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18; anchors.verticalCenter: parent.verticalCenter }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                Text { text: "Keep Awake"; color: "#e6e1ff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; font.bold: true }
                                Text { text: root.keepAwake ? "Awake" : "Normal"; color: "#99e6e1ff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.keepAwake = !root.keepAwake
                                if (root.keepAwake) {
                                    Quickshell.execDetached(["sh", "-c", "systemd-inhibit --what=idle:sleep --who=nocturnal --why='Keep Awake' sleep infinity &"])
                                } else {
                                    Quickshell.execDetached(["pkill", "-f", "systemd-inhibit.*nocturnal"])
                                }
                            }
                        }
                    }

                    // 6. Audio Mute
                    Rectangle {
                        width: (parent.width - 10) / 2; height: 64; radius: 12
                        color: !root.audioMuted ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : "#14ffffff"
                        border.width: !root.audioMuted ? 1 : 0; border.color: Theme.accent
                        Row {
                            anchors.fill: parent; anchors.leftMargin: 14; spacing: 12
                            Text { text: root.audioMuted ? "\uf026" : "\uf028"; color: !root.audioMuted ? Theme.accent : "#88e6e1ff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18; anchors.verticalCenter: parent.verticalCenter }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                Text { text: "Audio"; color: "#e6e1ff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; font.bold: true }
                                Text { text: root.audioMuted ? "Muted" : "Active"; color: "#99e6e1ff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                            }
                        }
                        MouseArea { anchors.fill: parent; onClicked: if (root.audioReady) root.sink.audio.muted = !root.sink.audio.muted }
                    }

                    // 7. Blur
                    Rectangle {
                        width: (parent.width - 10) / 2; height: 64; radius: 12
                        color: Theme.blurEnabled ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22) : "#14ffffff"
                        border.width: Theme.blurEnabled ? 1 : 0; border.color: Theme.accent
                        Row {
                            anchors.fill: parent; anchors.leftMargin: 14; spacing: 12
                            Text { text: "\uf0d0"; color: Theme.blurEnabled ? Theme.accent : "#88e6e1ff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18; anchors.verticalCenter: parent.verticalCenter }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                Text { text: "Frosted Blur"; color: "#e6e1ff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; font.bold: true }
                                Text { text: Theme.blurEnabled ? "On" : "Off"; color: "#99e6e1ff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                Theme.blurEnabled = !Theme.blurEnabled; Theme.save()
                                Quickshell.execDetached(["hyprctl", "keyword", "decoration:blur:enabled", Theme.blurEnabled ? "true" : "false"])
                            }
                        }
                    }

                    // 8. Full Settings
                    Rectangle {
                        width: (parent.width - 10) / 2; height: 64; radius: 12
                        color: "#14ffffff"
                        Row {
                            anchors.fill: parent; anchors.leftMargin: 14; spacing: 12
                            Text { text: "\uf013"; color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18; anchors.verticalCenter: parent.verticalCenter }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                Text { text: "Settings"; color: "#e6e1ff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; font.bold: true }
                                Text { text: "Open"; color: "#99e6e1ff"; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.open = false
                                Quickshell.execDetached(["quickshell", "ipc", "-p", Quickshell.env("HOME") + "/nocturnal/quickshell/shell.qml", "call", "settings", "toggle"])
                            }
                        }
                    }
                }

                // TAB 3: QUICK WALLPAPER PICKER
                GridView {
                    opacity: root.activeTab === "wallpaper" ? 1 : 0
                    visible: opacity > 0.01
                    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    transform: Translate { y: root.activeTab === "wallpaper" ? 0 : 8; Behavior on y { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } } }
                    width: parent.width
                    height: parent.height - 48
                    cellWidth: 162
                    cellHeight: 104
                    clip: true
                    model: root.wallpapers

                    delegate: Rectangle {
                        required property string modelData
                        width: 154
                        height: 96
                        radius: 10
                        color: "#14ffffff"
                        border.width: Theme.wallpaper === modelData ? 2 : 1
                        border.color: Theme.wallpaper === modelData ? Theme.accent : "#22ffffff"
                        clip: true

                        Image {
                            anchors.fill: parent
                            anchors.margins: 2
                            source: "file://" + (modelData.indexOf("/") === 0 ? modelData : Quickshell.env("HOME") + "/nocturnal/wallpapers/" + modelData)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                Theme.wallpaper = modelData
                                Theme.save()
                                Quickshell.execDetached([Quickshell.env("HOME") + "/nocturnal/bin/set-wallpaper", modelData])
                            }
                        }
                    }
                }
            }
        }
    }
}
