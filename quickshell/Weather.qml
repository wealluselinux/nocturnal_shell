import Quickshell.Io
import QtQuick

Text {
    id: root
    property string info: "Weather…"

    text: info
    color: "#e6e1ff"
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: 15
    anchors.verticalCenter: parent.verticalCenter

    Process {
        id: proc
        command: ["curl", "-s", "-m", "10", "wttr.in/?u&format=%t+%C"]
        stdout: StdioCollector {
            id: collector
            onStreamFinished: {
                var t = collector.text.trim()
                if (t.length > 0 && t.length < 40 && t.indexOf("°") >= 0)
                    root.info = t.replace(/^\+/, "")
            }
        }
    }

    Timer {
        interval: 900000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }
}
