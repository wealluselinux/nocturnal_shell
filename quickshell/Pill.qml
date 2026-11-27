import QtQuick

Rectangle {
    default property alias content: row.data

    height: 38
    width: row.implicitWidth + 32
    radius: 19
    color: "#cc12131a"
    border.width: 1
    border.color: "#22ffffff"

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 12
    }
}
