import Quickshell.Io
import QtQuick

Row {
    id: root
    spacing: 6

    property string wifi: "Off"
    property string cpu: "0%"
    property string ram: "0G"
    property string bat: ""
    property bool charging: false

    Process {
        id: statsProc
        command: ["sh", "-c",
            "w=$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | grep '^yes:' | head -1 | cut -d: -f2); " +
            "[ -z \"$w\" ] && w='Off'; " +
            "c=$(grep -m1 'cpu ' /proc/stat | awk '{u=$2+$4; t=$2+$4+$5; if(t>0) printf \"%d%%\", u*100/t; else print \"0%\"}'); " +
            "r=$(free -m | awk '/Mem:/ {printf \"%.1fG\", $3/1024}'); " +
            "b=$(cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1); " +
            "s=$(cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1); " +
            "echo \"$w|$c|$r|$b|$s\""
        ]
        stdout: StdioCollector {
            id: collector
            onStreamFinished: {
                var p = collector.text.trim().split("|")
                if (p.length >= 5) {
                    root.wifi = p[0]
                    root.cpu = p[1]
                    root.ram = p[2]
                    root.bat = p[3]
                    root.charging = (p[4] === "Charging")
                }
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: statsProc.running = true
    }

    // Wi-Fi pill
    Pill {
        Text {
            text: "\uf1eb  " + root.wifi
            color: root.wifi === "Off" ? Theme.text : Theme.text
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
            elide: Text.ElideRight
            width: Math.min(implicitWidth, 120)
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // CPU + RAM pill
    Pill {
        Text {
            text: "\uf4bc " + root.cpu + "  \uf2db " + root.ram
            color: Theme.text
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // Battery pill (shown on laptops)
    Pill {
        visible: root.bat !== ""
        Text {
            text: (root.charging ? "\uf0e7 " : "\uf240 ") + root.bat + "%"
            color: root.charging ? Theme.accent : Theme.text
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
