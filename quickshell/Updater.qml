import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
    id: root
    property bool updating: false
    property bool showDoneBanner: false
    property string statusText: "Downloading Nocturnal update..."
    property string newVersion: ""
    property string updateAction: "update" // "update" | "reinstall" | "rollback"
    property string homeDir: Quickshell.env("HOME") || ""

    IpcHandler {
        target: "updater"
        function start(ver: string): void {
            root.updateAction = "update"
            root.newVersion = ver
            root.statusText = "Preparing update to v" + ver + "..."
            root.updating = true
            updateDelayTimer.restart()
        }
        function reinstall(): void {
            root.updateAction = "reinstall"
            root.newVersion = ""
            root.statusText = "Preparing clean reinstall..."
            root.updating = true
            updateDelayTimer.restart()
        }
        function rollback(): void {
            root.updateAction = "rollback"
            root.newVersion = ""
            root.statusText = "Preparing downgrade to previous version..."
            root.updating = true
            updateDelayTimer.restart()
        }
    }

    Timer {
        id: updateDelayTimer
        interval: 5000
        repeat: false
        onTriggered: {
            if (root.updateAction === "reinstall") {
                root.statusText = "Reinstalling Nocturnal Shell..."
                reinstallProc.running = true
            } else if (root.updateAction === "rollback") {
                root.statusText = "Downgrading to previous version..."
                rollbackProc.running = true
            } else {
                root.statusText = "Updating Nocturnal Shell to v" + root.newVersion + "..."
                updateProc.running = true
            }
        }
    }

    Component.onCompleted: { checkFlagProc.running = true }

    Process {
        id: checkFlagProc
        command: ["sh", "-c", "[ -f /tmp/nocturnal-updated ] && cat /tmp/nocturnal-updated && rm -f /tmp/nocturnal-updated"]
        stdout: StdioCollector {
            id: flagCol
            onStreamFinished: {
                var v = flagCol.text.trim()
                if (v.length > 0) {
                    root.newVersion = v
                    root.showDoneBanner = true
                    doneTimer.restart()
                }
            }
        }
    }

    Timer { id: doneTimer; interval: 4500; onTriggered: root.showDoneBanner = false }

    readonly property string backupPrefix:
        "mkdir -p /tmp/nocturnal-userbak && " +
        "for f in settings.json pinned.json widgets.json; do [ -f \"$HOME/nocturnal/quickshell/$f\" ] && cp \"$HOME/nocturnal/quickshell/$f\" \"/tmp/nocturnal-userbak/$f\"; done && " +
        "cd \"$HOME/nocturnal\" && "

    readonly property string restoreSuffix:
        " && for f in settings.json pinned.json widgets.json; do [ -f \"/tmp/nocturnal-userbak/$f\" ] && cp \"/tmp/nocturnal-userbak/$f\" \"$HOME/nocturnal/quickshell/$f\"; done && " +
        "rm -rf /tmp/nocturnal-userbak && " +
        "chmod +x bin/* && " +
        "cat VERSION > /tmp/nocturnal-updated && " +
        "setsid -f sh -c 'sleep 0.5; pkill -x quickshell; sleep 0.4; exec quickshell -p \"$HOME/nocturnal/quickshell/shell.qml\" >/dev/null 2>&1' </dev/null >/dev/null 2>&1"

    Process {
        id: updateProc
        command: ["sh", "-c", root.backupPrefix + "(git -c core.fileMode=false stash -q 2>/dev/null || true) && git -c core.fileMode=false pull --rebase origin main" + root.restoreSuffix]
        stdout: StdioCollector { onStreamFinished: { root.statusText = "Restarting Nocturnal Shell..." } }
    }

    Process {
        id: reinstallProc
        command: ["sh", "-c", root.backupPrefix + "git fetch origin main && git reset --hard origin/main" + root.restoreSuffix]
        stdout: StdioCollector { onStreamFinished: { root.statusText = "Restarting Nocturnal Shell..." } }
    }

    Process {
        id: rollbackProc
        command: ["sh", "-c", root.backupPrefix + "git reset --hard HEAD~1" + root.restoreSuffix]
        stdout: StdioCollector { onStreamFinished: { root.statusText = "Restarting Nocturnal Shell..." } }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.updating
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                color: Theme.splashBg

                Column {
                    anchors.centerIn: parent
                    spacing: 18

                    MoonLogo {
                        width: 112; height: 112
                        anchors.horizontalCenter: parent.horizontalCenter
                        RotationAnimation on rotation {
                            running: root.updating
                            from: 0; to: 360; duration: 2400; loops: Animation.Infinite
                        }
                    }

                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: root.statusText; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 18; font.bold: true }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Preserving your settings & wallpaper..."; color: Theme.textMuted; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                }
            }
        }
    }

    PanelWindow {
        visible: root.showDoneBanner
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        mask: Region {}

        anchors { top: true }
        margins { top: 56 }
        implicitWidth: 340
        implicitHeight: 68
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: Theme.shapeRadius
            color: Theme.panelBg
            border.width: 2
            border.color: Theme.accent

            Row {
                anchors.centerIn: parent
                spacing: 12

                MoonLogo { width: 32; height: 32; anchors.verticalCenter: parent.verticalCenter }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Text { text: "Update Complete!"; color: Theme.accent; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14; font.bold: true }
                    Text { text: "Nocturnal Shell v" + root.newVersion + " is ready"; color: Theme.text; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 11 }
                }
            }
        }
    }
}
