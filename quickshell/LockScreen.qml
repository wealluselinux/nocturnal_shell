import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick

Scope {
    id: root
    property bool lockingAnim: false
    property real revBgOpacity: 0.0
    property real revMoonOpacity: 0.0
    property real revMoonScale: 3.2

    property var users: [Quickshell.env("USER") || "rig"]
    property string selectedUser: Quickshell.env("USER") || "rig"
    property string errorMsg: ""
    property string pendingPassword: ""
    property bool checking: false

    IpcHandler {
        target: "lockscreen"
        function lock(): void {
            root.errorMsg = ""
            root.pendingPassword = ""
            root.revBgOpacity = 0.0
            root.revMoonOpacity = 0.0
            root.revMoonScale = 3.2
            root.lockingAnim = true
            reverseSeq.restart()
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Process {
        id: userProc
        command: ["sh", "-c", "awk -F: '$3 >= 1000 && $3 < 60000 {print $1}' /etc/passwd"]
        stdout: StdioCollector {
            id: uCol
            onStreamFinished: {
                var list = uCol.text.trim().split("\n").filter(u => u.length > 0)
                if (list.length > 0) root.users = list
            }
        }
    }

    Component.onCompleted: userProc.running = true

    PamContext {
        id: pam
        config: "login"
        user: root.selectedUser

        onPamMessage: {
            if (responseRequired) {
                respond(root.pendingPassword)
            }
        }

        onCompleted: (result) => {
            root.checking = false
            root.pendingPassword = ""
            if (result === PamResult.Success) {
                sessionLock.locked = false
                Quickshell.execDetached(["quickshell", "ipc", "-p", Quickshell.env("HOME") + "/nocturnal/quickshell/shell.qml", "call", "splash", "play"])
            } else {
                root.errorMsg = "Incorrect password"
            }
        }
    }

    function attemptUnlock(pw) {
        if (!pw || root.checking) return
        root.errorMsg = ""
        root.checking = true
        root.pendingPassword = pw
        if (!pam.start()) {
            root.checking = false
            root.errorMsg = "Auth failed to start"
        }
    }

    SequentialAnimation {
        id: reverseSeq
        ParallelAnimation {
            NumberAnimation { target: root; property: "revBgOpacity"; from: 0.0; to: 1.0; duration: 420; easing.type: Easing.OutCubic }
            NumberAnimation { target: root; property: "revMoonOpacity"; from: 0.0; to: 1.0; duration: 360; easing.type: Easing.OutCubic }
            NumberAnimation { target: root; property: "revMoonScale"; from: 3.2; to: 1.0; duration: 480; easing.type: Easing.OutCubic }
        }
        ScriptAction {
            script: {
                sessionLock.locked = true
                root.lockingAnim = false
            }
        }
    }

    // Reverse-splash overlay when locking
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.lockingAnim
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            mask: Region {}
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                color: "#08090e"
                opacity: root.revBgOpacity

                MoonLogo {
                    width: 128
                    height: 128
                    anchors.centerIn: parent
                    scale: root.revMoonScale
                    opacity: root.revMoonOpacity
                }
            }
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: false

        WlSessionLockSurface {
            Rectangle {
                anchors.fill: parent
                color: "#08090e"

                Column {
                    anchors.centerIn: parent
                    spacing: 18
                    width: 300

                    MoonLogo {
                        width: 96
                        height: 96
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 4

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDateTime(clock.date, "h:mm AP")
                            color: "#e6e1ff"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 36
                            font.bold: true
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDateTime(clock.date, "dddd, MMM d")
                            color: Theme.accent
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                        }
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 180
                        height: 34
                        radius: 17
                        color: "#14ffffff"
                        border.width: 1
                        border.color: "#22ffffff"

                        Text {
                            anchors.centerIn: parent
                            text: "\uf007  " + root.selectedUser + (root.users.length > 1 ? "  ▾" : "")
                            color: "#e6e1ff"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (root.users.length > 1) {
                                    var idx = (root.users.indexOf(root.selectedUser) + 1) % root.users.length
                                    root.selectedUser = root.users[idx]
                                    root.errorMsg = ""
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: 280
                        height: 42
                        radius: 12
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "#1affffff"
                        border.width: 1
                        border.color: root.errorMsg !== "" ? "#f38ba8" : Theme.accent

                        TextInput {
                            id: pwInput
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            verticalAlignment: TextInput.AlignVCenter
                            horizontalAlignment: TextInput.AlignHCenter
                            color: "#e6e1ff"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            echoMode: TextInput.Password
                            focus: true

                            Keys.onReturnPressed: {
                                root.attemptUnlock(pwInput.text)
                                pwInput.text = ""
                            }

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                text: root.checking ? "Unlocking..." : "Enter password..."
                                color: "#66e6e1ff"
                                font: pwInput.font
                                visible: pwInput.text === ""
                            }
                        }
                    }

                    Text {
                        visible: root.errorMsg !== ""
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.errorMsg
                        color: "#f38ba8"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}
