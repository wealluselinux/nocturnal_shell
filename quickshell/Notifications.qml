import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    visible: (NotifStore.showToast || card.opacity > 0.01) && NotifStore.currentNotif !== null
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay

    anchors { top: true }
    margins { top: 54 }
    implicitWidth: 340
    implicitHeight: Math.max(84, contentCol.implicitHeight + 28)
    color: "transparent"

    Rectangle {
        id: card
        anchors.fill: parent
        radius: Theme.shapeRadius
        color: Theme.panelBg
        border.width: 1
        border.color: Theme.accent

        opacity: NotifStore.showToast ? 1 : 0
        transform: Translate { y: NotifStore.showToast ? 0 : -14 }
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        Column {
            id: contentCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 14
            spacing: 6

            Row {
                width: parent.width

                Text {
                    text: NotifStore.currentNotif ? (NotifStore.currentNotif.appName || "Notification") : ""
                    color: Theme.accent
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    font.bold: true
                    width: parent.width - 20
                    elide: Text.ElideRight
                }

                Text {
                    text: "✕"
                    color: "#88e6e1ff"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            NotifStore.showToast = false
                            if (NotifStore.currentNotif) NotifStore.currentNotif.dismiss()
                        }
                    }
                }
            }

            Text {
                width: parent.width
                text: NotifStore.currentNotif ? NotifStore.currentNotif.summary : ""
                color: "#e6e1ff"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                font.bold: true
                wrapMode: Text.WordWrap
            }

            Text {
                visible: text !== ""
                width: parent.width
                text: NotifStore.currentNotif ? NotifStore.currentNotif.body : ""
                color: "#b8b3d6"
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }
        }
    }
}
