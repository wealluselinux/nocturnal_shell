import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
    id: root
    property bool open: false
    property string userHost: Quickshell.env("USER") || "user"
    property string uptimeStr: ""
    property string facePath: Quickshell.env("HOME") + "/.face"

    IpcHandler {
        target: "rightsidebar"
        function toggle(): void { root.open = !root.open }
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Process {
        id: upProc
        command: ["sh", "-c", "echo \"$(whoami)@$(hostname)|$(uptime -p | sed -E 's/up //; s/ minutes?/m/; s/ hours?/h/')\""]
        stdout: StdioCollector {
            id: upCol
            onStreamFinished: {
                var p = upCol.text.trim().split("|")
                if (p.length >= 2) { root.userHost = p[0]; root.uptimeStr = p[1] }
            }
        }
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

    PanelWindow {
        id: win
        visible: root.open || card.opacity > 0.01
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay

        anchors { top: true; right: true }
        margins { top: 52; right: 8 }
        implicitWidth: 350
        implicitHeight: 648
        color: "transparent"

        onVisibleChanged: { if (visible) upProc.running = true }

        Rectangle {
            id: card
            anchors.fill: parent
            radius: Theme.shapeRadius
            color: Theme.panelBg
            border.width: 1
            border.color: Theme.border

            opacity: root.open ? 1 : 0
            transform: Translate { x: root.open ? 0 : 24 }
            Behavior on opacity { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }

            Column {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // 1. User Profile Header
                Rectangle {
                    width: parent.width; height: 76; radius: 12
                    color: Theme.surface; border.width: 1; border.color: Theme.border

                    Row {
                        anchors.fill: parent; anchors.margins: 12; spacing: 12

                        Rectangle {
                            width: 50; height: 50; radius: 25
                            color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22)
                            border.width: 2; border.color: Theme.accent
                            clip: true; anchors.verticalCenter: parent.verticalCenter

                            Image { id: avatarImg; anchors.fill: parent; source: "file://" + root.facePath; fillMode: Image.PreserveAspectCrop; visible: status === Image.Ready }
                            Text { anchors.centerIn: parent; text: "\uf007"; color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 20; visible: avatarImg.status !== Image.Ready }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            Text { text: root.userHost; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; font.bold: true }
                            Text { text: Theme.lightMode ? "Daylight Shell" : "Nocturnal Shell"; color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                            Text { visible: root.uptimeStr !== ""; text: "Up " + root.uptimeStr; color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10 }
                        }
                    }
                }

                // Power / Session Actions
                Row {
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: [
                            { icon: "\uf186", label: "Sleep",  cmd: ["systemctl", "suspend"], danger: false },
                            { icon: "\uf2f5", label: "Logout", cmd: ["sh", "-c", "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"], danger: false },
                            { icon: "\uf021", label: "Reboot", cmd: ["systemctl", "reboot"], danger: true },
                            { icon: "\uf011", label: "Power",  cmd: ["systemctl", "poweroff"], danger: true }
                        ]

                        Rectangle {
                            required property var modelData
                            width: (parent.width - 18) / 4; height: 44; radius: 10
                            color: pMouse.containsMouse ? (modelData.danger ? "#33f38ba8" : Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22)) : Theme.surface
                            border.width: pMouse.containsMouse ? 1 : 0
                            border.color: modelData.danger ? "#f38ba8" : Theme.accent

                            Column {
                                anchors.centerIn: parent; spacing: 2
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.icon; color: modelData.danger ? "#f38ba8" : Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14 }
                                Text { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10 }
                            }
                            MouseArea { id: pMouse; anchors.fill: parent; hoverEnabled: true; onClicked: Quickshell.execDetached(modelData.cmd) }
                        }
                    }
                }

                // 2. Notifications Header + List
                Row {
                    width: parent.width
                    Text { text: "NOTIFICATIONS"; color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.bold: true; width: parent.width - 70; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        text: "Clear All"
                        color: clearMouse.containsMouse ? Theme.text : Theme.textMuted
                        font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter
                        MouseArea { id: clearMouse; anchors.fill: parent; hoverEnabled: true; onClicked: NotifStore.clearAll() }
                    }
                }

                Item {
                    width: parent.width; height: 215
                    Text { anchors.centerIn: parent; visible: notifList.count === 0; text: "No notifications"; color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }

                    ListView {
                        id: notifList
                        anchors.fill: parent; clip: true; spacing: 6
                        model: NotifStore.list

                        delegate: Rectangle {
                            required property var modelData
                            width: ListView.view.width; height: nCol.implicitHeight + 16; radius: 10; color: Theme.surface

                            Column {
                                id: nCol
                                anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 8; spacing: 2
                                Row {
                                    width: parent.width
                                    Text { text: modelData.appName || "App"; color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.bold: true; width: parent.width - 16; elide: Text.ElideRight }
                                    Text { text: "✕"; color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; MouseArea { anchors.fill: parent; onClicked: modelData.dismiss() } }
                                }
                                Text { width: parent.width; text: modelData.summary; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; font.bold: true; wrapMode: Text.WordWrap }
                                Text { visible: text !== ""; width: parent.width; text: modelData.body; color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; wrapMode: Text.WordWrap }
                            }
                        }
                    }
                }

                // 3. Bottom Clock + Calendar
                Rectangle {
                    width: parent.width; height: 225; radius: 12
                    color: Theme.surface; border.width: 1; border.color: Theme.border

                    Column {
                        anchors.fill: parent; anchors.margins: 12; spacing: 6
                        Row {
                            width: parent.width
                            Text { text: Qt.formatDateTime(clock.date, Theme.use24h ? "HH:mm" : "h:mm AP"); color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18; font.bold: true; width: parent.width - 120 }
                            Text { text: Qt.formatDateTime(clock.date, "ddd, MMM d"); color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; horizontalAlignment: Text.AlignRight; width: 120; anchors.verticalCenter: parent.verticalCenter }
                        }

                        Grid {
                            width: parent.width; columns: 7; rowSpacing: 2
                            Repeater {
                                model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
                                Text { required property string modelData; width: 42; horizontalAlignment: Text.AlignHCenter; text: modelData; color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.bold: true }
                            }
                        }

                        Grid {
                            width: parent.width; columns: 7; rowSpacing: 2
                            Repeater {
                                model: root.calendarDays
                                Rectangle {
                                    required property var modelData
                                    width: 42; height: 22; radius: 6
                                    color: modelData.isToday ? Theme.accent : "transparent"
                                    Text { anchors.centerIn: parent; text: modelData.d; color: modelData.isToday ? (Theme.lightMode ? "#ffffff" : "#12131a") : Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11; font.bold: modelData.isToday }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
