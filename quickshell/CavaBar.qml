import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
    id: root
    property var bars: []

    Process {
        id: cavaProc
        running: Theme.cavaEnabled
        command: ["sh", "-c",
            "command -v cava >/dev/null 2>&1 || exit 0; " +
            "printf '[general]\\nframerate = 60\\nbars = 48\\n[output]\\nmethod = raw\\nraw_target = /dev/stdout\\ndata_format = ascii\\nascii_max_range = 100\\n' > /tmp/nocturnal-cava.conf && " +
            "exec cava -p /tmp/nocturnal-cava.conf"
        ]
        stdout: SplitParser {
            onRead: (line) => {
                var parts = line.trim().split(";")
                var vals = []
                for (var i = 0; i < parts.length; i++) {
                    if (parts[i].length > 0) vals.push(parseInt(parts[i]) || 0)
                }
                if (vals.length > 0) root.bars = vals
            }
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: Theme.cavaEnabled
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            mask: Region {}

            anchors { bottom: true; left: true; right: true }
            implicitHeight: 90
            color: "transparent"

            Canvas {
                anchors.fill: parent
                property var barsData: root.bars
                onBarsDataChanged: requestPaint()

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    var n = barsData.length
                    if (n === 0) return
                    var slotW = width / n
                    var barW = Math.max(3, slotW * 0.65)
                    ctx.fillStyle = Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.55)
                    for (var i = 0; i < n; i++) {
                        var h = Math.max(2, (barsData[i] / 100.0) * (height - 4))
                        var x = i * slotW + (slotW - barW) / 2
                        var y = height - h
                        ctx.fillRect(x, y, barW, h)
                    }
                }
            }
        }
    }
}
