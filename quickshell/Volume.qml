import Quickshell.Services.Pipewire
import QtQuick

Item {
    id: root
    anchors.verticalCenter: parent.verticalCenter
    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool ready: sink !== null && sink.audio !== null
    readonly property real vol: ready ? sink.audio.volume : 0
    readonly property bool muted: ready ? sink.audio.muted : false

    Text {
        id: label
        text: (root.muted ? "\uf026  " : "\uf028  ") + Math.round(root.vol * 100) + "%"
        color: root.muted ? "#88e6e1ff" : "#e6e1ff"
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 15
    }

    MouseArea {
        anchors.fill: parent
        onClicked: if (root.ready) root.sink.audio.muted = !root.sink.audio.muted
        onWheel: (wheel) => {
            if (!root.ready) return
            var step = wheel.angleDelta.y > 0 ? 0.05 : -0.05
            root.sink.audio.volume = Math.max(0, Math.min(1, root.vol + step))
        }
    }
}
