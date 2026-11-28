import Quickshell
import QtQuick

Scope {
    id: root
    property string homeDir: Quickshell.env("HOME") || ""

    Variants {
        model: Theme.enabledMods

        Loader {
            required property string modelData
            active: true
            source: "file://" + root.homeDir + "/.config/nocturnal/mods/" + modelData + "/main.qml"
            onStatusChanged: {
                if (status === Loader.Error) {
                    console.log("Nocturnal ModLoader: failed to load mod", modelData)
                }
            }
        }
    }
}
