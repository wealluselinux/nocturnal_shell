pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: store
    property var positions: ({})

    FileView {
        id: file
        path: Qt.resolvedUrl("widgets.json")
        preload: true
        printErrors: false
        onLoaded: {
            try {
                var data = JSON.parse(text())
                if (data && typeof data === "object") store.positions = data
            } catch (e) {}
        }
    }

    function pos(name, dx, dy) {
        var p = store.positions[name]
        if (p && typeof p.x === "number" && typeof p.y === "number") return { x: p.x, y: p.y }
        return { x: dx, y: dy }
    }

    function set(name, x, y) {
        var next = {}
        for (var k in store.positions) next[k] = store.positions[k]
        next[name] = { x: Math.round(x), y: Math.round(y) }
        store.positions = next
        file.setText(JSON.stringify(next))
    }

    function reset() {
        store.positions = {}
        file.setText("{}")
    }
}
