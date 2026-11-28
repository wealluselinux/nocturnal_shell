# Nocturnal Shell Mods

Mods live in `~/.config/nocturnal/mods/` so they are **never overwritten** when Nocturnal Shell updates.

## Folder Structure

Create a folder for your mod:

```
~/.config/nocturnal/mods/my-cool-mod/
├── mod.json
└── main.qml
```

## 1. `mod.json`

```json
{
  "name": "My Cool Mod",
  "author": "yourname",
  "version": "1.0.0",
  "description": "Adds a custom floating badge to the desktop."
}
```

## 2. `main.qml`

Your `main.qml` is loaded by Quickshell inside `ModLoader.qml`. You can use `Quickshell`, `Quickshell.Wayland`, `Quickshell.Io`, `QtQuick`, and Nocturnal's `Theme` singleton (`Theme.panelBg`, `Theme.accent`, `Theme.text`, `Theme.border`, `Theme.shapeRadius`):

```qml
import Quickshell
import Quickshell.Wayland
import QtQuick

PanelWindow {
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Bottom
    anchors { bottom: true; right: true }
    margins { bottom: 16; right: 16 }
    implicitWidth: 180
    implicitHeight: 44
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        radius: Theme.shapeRadius
        color: Theme.panelBg
        border.width: 1
        border.color: Theme.accent

        Text {
            anchors.centerIn: parent
            text: "Hello from Mod!"
            color: Theme.text
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            font.bold: true
        }
    }
}
```

## 3. Enable Your Mod

Open **Settings → Mods**, click **Refresh**, and toggle your mod **ON**.
