import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick

Scope {
    id: root
    property bool open: false
    property var pinnedIds: []

    FileView {
        id: pinnedFile
        path: Qt.resolvedUrl("pinned.json")
        preload: true
        printErrors: false
        onLoaded: {
            try {
                var parsed = JSON.parse(text())
                if (Array.isArray(parsed)) root.pinnedIds = parsed
            } catch (e) {
                root.pinnedIds = []
            }
        }
    }

    function isPinned(appId) {
        return root.pinnedIds.indexOf(appId) >= 0
    }

    function togglePin(appId) {
        var next = root.pinnedIds.slice()
        var idx = next.indexOf(appId)
        if (idx >= 0) {
            next.splice(idx, 1)
        } else {
            next.push(appId)
        }
        root.pinnedIds = next
        pinnedFile.setText(JSON.stringify(next))
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void {
            root.open = !root.open
        }
    }

    PanelWindow {
        id: win
        property real slideOffset: root.open ? 0 : 410
        Behavior on slideOffset {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        visible: root.open || slideOffset < 405
        focusable: true
        exclusionMode: ExclusionMode.Ignore

        anchors { bottom: true }
        margins { bottom: 0 }
        implicitWidth: 420
        implicitHeight: 396
        color: "transparent"

        onVisibleChanged: {
            if (visible) {
                searchInput.text = ""
                searchInput.forceActiveFocus()
            }
        }

        readonly property var displayItems: {
            var q = searchInput.text.trim().toLowerCase()
            var all = DesktopEntries.applications.values.slice()
            all.sort((a, b) => a.name.localeCompare(b.name))

            if (q !== "") {
                return all
                    .filter(app => app.name.toLowerCase().indexOf(q) >= 0)
                    .map(app => ({ isHeader: false, app: app, pinned: root.isPinned(app.id) }))
            }

            var pinned = []
            var unpinned = []
            for (var i = 0; i < all.length; i++) {
                if (root.isPinned(all[i].id)) {
                    pinned.push({ isHeader: false, app: all[i], pinned: true })
                } else {
                    unpinned.push({ isHeader: false, app: all[i], pinned: false })
                }
            }

            var items = []
            if (pinned.length > 0) {
                items.push({ isHeader: true, title: "PINNED" })
                items = items.concat(pinned)
                items.push({ isHeader: true, title: "ALL APPS" })
            }
            return items.concat(unpinned)
        }

        Rectangle {
            anchors.fill: parent
            anchors.bottomMargin: 16
            radius: 18
            color: "#cc12131a"
            border.width: 1
            border.color: "#22ffffff"

            opacity: root.open ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180 } }
            transform: Translate { y: win.slideOffset }

            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                // Search bar at the top
                Rectangle {
                    width: parent.width
                    height: 40
                    radius: 12
                    color: "#1affffff"
                    border.width: 1
                    border.color: searchInput.activeFocus ? "#c9b8ff" : "#22ffffff"

                    TextInput {
                        id: searchInput
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        verticalAlignment: TextInput.AlignVCenter
                        color: "#e6e1ff"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                        clip: true

                        Keys.onEscapePressed: root.open = false
                        Keys.onReturnPressed: {
                            for (var i = 0; i < win.displayItems.length; i++) {
                                if (!win.displayItems[i].isHeader) {
                                    win.displayItems[i].app.execute()
                                    root.open = false
                                    break
                                }
                            }
                        }

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "Search apps..."
                            color: "#66e6e1ff"
                            font: searchInput.font
                            visible: searchInput.text === ""
                        }
                    }
                }

                // App list with Pinned section at the top
                ListView {
                    width: parent.width
                    height: parent.height - 50
                    clip: true
                    spacing: 4
                    model: win.displayItems

                    delegate: Item {
                        required property var modelData
                        width: ListView.view.width
                        height: modelData.isHeader ? 24 : 38

                        // Section header
                        Text {
                            visible: modelData.isHeader
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            text: modelData.title || ""
                            color: modelData.title === "PINNED" ? "#c9b8ff" : "#88e6e1ff"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            font.bold: true
                        }

                        // App row
                        Rectangle {
                            visible: !modelData.isHeader
                            anchors.fill: parent
                            radius: 10
                            color: itemMouse.containsMouse || pinMouse.containsMouse ? "#28c9b8ff" : "transparent"

                            MouseArea {
                                id: itemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: (mouse) => {
                                    if (mouse.button === Qt.RightButton) {
                                        root.togglePin(modelData.app.id)
                                    } else {
                                        modelData.app.execute()
                                        root.open = false
                                    }
                                }
                            }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 8
                                spacing: 10

                                IconImage {
                                    implicitSize: 22
                                    source: modelData.app ? Quickshell.iconPath(modelData.app.icon, true) : ""
                                    visible: source !== ""
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    width: parent.width - 66
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.app ? modelData.app.name : ""
                                    color: "#e6e1ff"
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 14
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    width: 28
                                    height: 28
                                    radius: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: pinMouse.containsMouse ? "#33ffffff" : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "\uf08d"
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 13
                                        color: modelData.pinned ? "#c9b8ff" : "#44e6e1ff"
                                    }

                                    MouseArea {
                                        id: pinMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: root.togglePin(modelData.app.id)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
