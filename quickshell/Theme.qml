pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: theme
    property bool lightMode: false
    property bool liquidGlass: false
    property bool weatherEffects: false
    property color accent: "#c9b8ff"
    property color bg: lightMode ? "#f3f1fa" : "#12131a"
    property real panelOpacity: 0.85
    property int shapeRadius: 12
    readonly property real effectiveOpacity: liquidGlass ? Math.min(panelOpacity, lightMode ? 0.42 : 0.32) : panelOpacity
    readonly property color panelBg: liquidGlass
        ? Qt.rgba(lightMode ? 0.96 : 0.14, lightMode ? 0.96 : 0.16, lightMode ? 1.0 : 0.24, effectiveOpacity)
        : Qt.rgba(bg.r, bg.g, bg.b, panelOpacity)
    readonly property color text: lightMode ? "#181924" : "#e6e1ff"
    readonly property color textMuted: lightMode ? "#5c5a72" : "#b8b3d6"
    readonly property color surface: liquidGlass
        ? (lightMode ? "#38ffffff" : "#26ffffff")
        : (lightMode ? "#14000000" : "#14ffffff")
    readonly property color border: liquidGlass
        ? (lightMode ? "#78ffffff" : "#4dffffff")
        : (lightMode ? "#24000000" : "#22ffffff")
    readonly property color splashBg: lightMode ? "#f3f1fa" : "#08090e"

    property string themePreset: "Nocturnal"
    property string wallpaper: ""
    property bool blurEnabled: true
    property int rounding: 14
    property bool dockEnabled: true
    property bool widgetsEnabled: true
    property bool widgetClock: true
    property bool widgetAnalog: true
    property bool widgetMusic: true
    property bool widgetSound: true
    property bool dockAutoHide: false
    property bool cavaEnabled: false
    property bool fastfetchLogo: false
    property bool use24h: false
    property int volumeLimit: 100
    property string barPosition: "top"
    property string dockPosition: "middle"
    property string launcherPosition: "middle"
    property var rightPillOrder: ["wifi", "stats", "battery", "volume"]
    property var pinnedIds: []

    FileView {
        id: settingsFile
        path: Qt.resolvedUrl("settings.json")
        preload: true
        printErrors: false
        onLoaded: {
            try {
                var data = JSON.parse(text())
                if (data.lightMode !== undefined) theme.lightMode = data.lightMode
                if (data.liquidGlass !== undefined) theme.liquidGlass = data.liquidGlass
                if (data.weatherEffects !== undefined) theme.weatherEffects = data.weatherEffects
                if (data.accent) theme.accent = data.accent
                if (data.themePreset) theme.themePreset = data.themePreset
                if (data.wallpaper) theme.wallpaper = data.wallpaper
                if (data.panelOpacity !== undefined) theme.panelOpacity = data.panelOpacity
                if (data.shapeRadius !== undefined) theme.shapeRadius = data.shapeRadius
                if (data.blurEnabled !== undefined) theme.blurEnabled = data.blurEnabled
                if (data.rounding !== undefined) theme.rounding = data.rounding
                if (data.dockEnabled !== undefined) theme.dockEnabled = data.dockEnabled
                if (data.widgetsEnabled !== undefined) theme.widgetsEnabled = data.widgetsEnabled
                if (data.widgetClock !== undefined) theme.widgetClock = data.widgetClock
                if (data.widgetAnalog !== undefined) theme.widgetAnalog = data.widgetAnalog
                if (data.widgetMusic !== undefined) theme.widgetMusic = data.widgetMusic
                if (data.widgetSound !== undefined) theme.widgetSound = data.widgetSound
                if (data.dockAutoHide !== undefined) theme.dockAutoHide = data.dockAutoHide
                if (data.cavaEnabled !== undefined) theme.cavaEnabled = data.cavaEnabled
                if (data.fastfetchLogo !== undefined) theme.fastfetchLogo = data.fastfetchLogo
                if (data.use24h !== undefined) theme.use24h = data.use24h
                if (data.volumeLimit !== undefined) theme.volumeLimit = data.volumeLimit
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

    function syncApps() {
        var m = theme.lightMode ? "light" : "dark"
        Quickshell.execDetached([Quickshell.env("HOME") + "/nocturnal/bin/sync-kitty", theme.accent.toString(), m])
        Quickshell.execDetached([Quickshell.env("HOME") + "/nocturnal/bin/sync-dolphin", theme.accent.toString()])
        Quickshell.execDetached([Quickshell.env("HOME") + "/nocturnal/bin/sync-fastfetch", theme.fastfetchLogo ? "on" : "off", m])
        if (theme.liquidGlass) {
            Quickshell.execDetached(["hyprctl", "--batch", "keyword decoration:blur:enabled true; keyword decoration:blur:size 7; keyword decoration:blur:passes 3; keyword decoration:blur:xray false"])
        } else {
            Quickshell.execDetached(["hyprctl", "--batch", "keyword decoration:blur:enabled " + (theme.blurEnabled ? "true" : "false") + "; keyword decoration:blur:size 4; keyword decoration:blur:passes 2; keyword decoration:blur:xray true"])
        }
    }

    function save() {
        settingsFile.setText(JSON.stringify({
            lightMode: theme.lightMode,
            liquidGlass: theme.liquidGlass,
            weatherEffects: theme.weatherEffects,
            accent: theme.accent.toString(),
            themePreset: theme.themePreset,
            wallpaper: theme.wallpaper,
            panelOpacity: theme.panelOpacity,
            shapeRadius: theme.shapeRadius,
            blurEnabled: theme.blurEnabled,
            rounding: theme.rounding,
            dockEnabled: theme.dockEnabled,
            widgetsEnabled: theme.widgetsEnabled,
            widgetClock: theme.widgetClock,
            widgetAnalog: theme.widgetAnalog,
            widgetMusic: theme.widgetMusic,
            widgetSound: theme.widgetSound,
            dockAutoHide: theme.dockAutoHide,
            cavaEnabled: theme.cavaEnabled,
            fastfetchLogo: theme.fastfetchLogo,
            use24h: theme.use24h,
            volumeLimit: theme.volumeLimit,
            barPosition: theme.barPosition,
            dockPosition: theme.dockPosition,
            launcherPosition: theme.launcherPosition,
            rightPillOrder: theme.rightPillOrder
        }))
        syncApps()
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
        if (idx >= 0) next.splice(idx, 1)
        else next.push(appId)
        theme.pinnedIds = next
        pinnedFile.setText(JSON.stringify(next))
    }
}
