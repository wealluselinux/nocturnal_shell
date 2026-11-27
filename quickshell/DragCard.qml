import QtQuick

Rectangle {
    id: card

    property string name: ""
    property real defaultX: 12
    property real defaultY: 56
    property Item area: parent
    default property alias content: inner.data

    radius: 16
    color: Theme.panelBg
    border.width: dragArea.drag.active ? 2 : 1
    border.color: dragArea.drag.active ? Theme.accent : "#22ffffff"

    function applySaved() {
        if (area.width <= 0 || area.height <= 0) return
        var p = WidgetStore.pos(card.name, card.defaultX, card.defaultY)
        card.x = Math.max(0, Math.min(p.x, area.width - card.width))
        card.y = Math.max(0, Math.min(p.y, area.height - card.height))
    }

    Component.onCompleted: applySaved()

    Connections {
        target: WidgetStore
        function onPositionsChanged() { if (!dragArea.drag.active) card.applySaved() }
    }
    Connections {
        target: card.area
        function onWidthChanged() { if (!dragArea.drag.active) card.applySaved() }
        function onHeightChanged() { if (!dragArea.drag.active) card.applySaved() }
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        drag.target: card
        drag.axis: Drag.XAndYAxis
        drag.minimumX: 0
        drag.maximumX: Math.max(0, card.area.width - card.width)
        drag.minimumY: 0
        drag.maximumY: Math.max(0, card.area.height - card.height)
        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.ArrowCursor
        onReleased: WidgetStore.set(card.name, card.x, card.y)
    }

    Item { id: inner; anchors.fill: parent }
}
