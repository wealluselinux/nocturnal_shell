import QtQuick

Rectangle {
    default property alias content: row.data

    height: 36
    width: row.implicitWidth + 24
    radius: Math.min(height / 2, Theme.shapeRadius)
    color: Theme.panelBg
    border.width: 1
    border.color: "#22ffffff"

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 10
    }
}
