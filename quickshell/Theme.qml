pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: theme
    property color accent: "#c9b8ff"
    property string wallpaper: ""
    property bool blurEnabled: true
    property int rounding: 14
    property bool dockEnabled: true
    property string dockPosition: "middle"
    property string launcherPosition: "middle"
    property var pinnedIds: []

    FileView {
        id: settingsFile
        path: Qt.resolvedUrl("settings.json")
        preload: true
        printErrors: false
        onLoaded: {
            try {
                var data = JSON.parse(text())
                if (data.accent) theme.accent = data.accent
                if (data.wallpaper) theme.wallpaper = data.wallpaper
                if (data.blurEnabled !== undefined) theme.blurEnabled = data.blurEnabled
                if (data.rounding !== undefined) theme.rounding = data.rounding
                if (data.dockEnabled !== undefined) theme.dockEnabled = data.dockEnabled
                if (data.dockPosition) theme.dockPosition = data.dockPosition
                if (data.launcherPosition) theme.launcherPosition = data.launcherPosition
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
        var acc = theme.accent.toString()
        var script =
            "command -v kitty >/dev/null 2>&1 || exit 0\n" +
            "mkdir -p \"$HOME/.config/kitty\"\n" +
            "conf=\"$HOME/.config/kitty/kitty.conf\"\n" +
            "[ -f \"$conf\" ] && [ ! -f \"$conf.nocturnal-bak\" ] && cp \"$conf\" \"$conf.nocturnal-bak\"\n" +
            "grep -qxF 'include nocturnal.conf' \"$conf\" 2>/dev/null || printf '\\ninclude nocturnal.conf\\n' >> \"$conf\"\n" +
            "cat > \"$HOME/.config/kitty/nocturnal.conf\" <<KCONF\n" +
            "background #12131a\n" +
            "foreground #e6e1ff\n" +
            "background_opacity 0.78\n" +
            "cursor " + acc + "\n" +
            "selection_background " + acc + "\n" +
            "selection_foreground #12131a\n" +
            "active_border_color " + acc + "\n" +
            "KCONF\n" +
            "pkill -USR1 kitty 2>/dev/null || true\n"
        Quickshell.execDetached(["sh", "-c", script])
    }

    function save() {
        settingsFile.setText(JSON.stringify({
            accent: theme.accent.toString(),
            wallpaper: theme.wallpaper,
            blurEnabled: theme.blurEnabled,
            rounding: theme.rounding,
            dockEnabled: theme.dockEnabled,
            dockPosition: theme.dockPosition,
            launcherPosition: theme.launcherPosition
        }))
        syncKitty()
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
