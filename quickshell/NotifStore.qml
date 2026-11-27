pragma Singleton
import Quickshell
import Quickshell.Services.Notifications
import QtQuick

Singleton {
    id: store
    property var currentNotif: null
    property bool showToast: false
    readonly property alias list: server.trackedNotifications

    NotificationServer {
        id: server
        bodySupported: true
        actionsSupported: true

        onNotification: (notif) => {
            notif.tracked = true
            store.currentNotif = notif
            store.showToast = true
            hideTimer.restart()
        }
    }

    Timer {
        id: hideTimer
        interval: 5000
        onTriggered: store.showToast = false
    }

    function clearAll() {
        var items = server.trackedNotifications.values.slice()
        for (var i = 0; i < items.length; i++) {
            items[i].dismiss()
        }
    }
}
