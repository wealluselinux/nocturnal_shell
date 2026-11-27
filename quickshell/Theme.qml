pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: theme
    property color accent: "#c9b8ff"
    property color bg: "#12131a"
    property real panelOpacity: 0.85
    property int shapeRadius: 12
    readonly property color panelBg: Qt.rgba(bg.r, bg.g, bg.b, panelOpacity)
    property string themePreset: "Nocturnal"
    property string wallpaper: ""
    property bool blurEnabled: true
    property int rounding: 14
    property bool dockEnabled: true
    property bool widgetsEnabled: true
    property string barPosition: "top"
    property string dockPosition: "middle"
    property string launcherPosition: "middle"
    property var pinnedIds: []
    property var rightPillOrder: ["wifi", "stats", "battery", "volume"]

    FileView {
        id: settingsFile
        path: Qt.resolvedUrl("settings.json")
        preload: true
        printErrors: false
        onLoaded: {
            try {
                var data = JSON.parse(text())
                if (data.accent) theme.accent = data.accent
                if (data.bg) theme.bg = data.bg
                if (data.panelOpacity !== undefined) theme.panelOpacity = data.panelOpacity
                if (data.shapeRadius !== undefined) theme.shapeRadius = data.shapeRadius
                if (data.themePreset) theme.themePreset = data.themePreset
                if (data.wallpaper) theme.wallpaper = data.wallpaper
                if (data.blurEnabled !== undefined) theme.blurEnabled = data.blurEnabled
                if (data.rounding !== undefined) theme.rounding = data.rounding
                if (data.dockEnabled !== undefined) theme.dockEnabled = data.dockEnabled
                if (data.widgetsEnabled !== undefined) theme.widgetsEnabled = data.widgetsEnabled
                if (data.barPosition) theme.barPosition = data.barPosition
                if (data.dockPosition) theme.dockPosition = data.dockPosition
                if (data.launcherPosition) theme.launcherPosition = data.launcherPosition
                if (Array.isArray(data.rightPillOrder)) theme.rightPillOrder = data.rightPillOrder
            } catch (e) {}
        }
    }

    FileView {
        id: pinnedFile
        path: Qt.resolvedUrl("pinned.json")
        preload: true
        printErrors: false
        onLoaded: {
            try {
                var parsed = JSON.parse(text())
                if (Array.isArray(parsed)) theme.pinnedIds = parsed
            } catch (e) {
                theme.pinnedIds = []
            }
        }
    }

    function syncKitty() {
        Quickshell.execDetached([Quickshell.env("HOME") + "/nocturnal/bin/sync-kitty", theme.accent.toString()]); Quickshell.execDetached([Quickshell.env("HOME") + "/nocturnal/bin/sync-dolphin", theme.accent.toString()])
    }

    function save() {
        settingsFile.setText(JSON.stringify({
            accent: theme.accent.toString(),
            bg: theme.bg.toString(),
            panelOpacity: theme.panelOpacity,
            shapeRadius: theme.shapeRadius,
            themePreset: theme.themePreset,
            wallpaper: theme.wallpaper,
            blurEnabled: theme.blurEnabled,
            rounding: theme.rounding,
            dockEnabled: theme.dockEnabled,
            widgetsEnabled: theme.widgetsEnabled,
            barPosition: theme.barPosition,
            dockPosition: theme.dockPosition,
            launcherPosition: theme.launcherPosition,
            rightPillOrder: theme.rightPillOrder
        }))
        syncKitty()
    }

    function moveRightPill(idx, delta) {
        var next = theme.rightPillOrder.slice()
        var target = idx + delta
        if (target < 0 || target >= next.length) return
        var tmp = next[idx]
        next[idx] = next[target]
        next[target] = tmp
        theme.rightPillOrder = next
        save()
    }

    function isPinned(appId) {
        return theme.pinnedIds.indexOf(appId) >= 0
    }

    function togglePin(appId) {
        var next = theme.pinnedIds.slice()
        var idx = next.indexOf(appId)
        if (idx >= 0) {
            next.splice(idx, 1)
        } else {
            next.push(appId)
        }
        theme.pinnedIds = next
        pinnedFile.setText(JSON.stringify(next))
    }
}
