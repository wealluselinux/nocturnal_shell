# Nocturnal Shell

A lightweight, dark/daylight desktop environment built on **Hyprland (Lua)** and **Quickshell (QML)**, made by **rig**.

## Features
- **Adaptive Bar (`Top` / `Bottom` / `Left` / `Right`)**: 10 virtual workspaces with live app icons, inline MPRIS music controls + 1-line synced lyrics, weather, and reorderable right-side status pills (Wi-Fi, CPU/RAM, Battery, Volume with earbang protection).
- **Nocturnal & Daylight Modes**: Switch between dark **Nocturnal** (Crescent Moon) and light **Daylight** (Sun) with animated splash & lock screens, live wallpaper color extraction, transparency/shape presets, and automatic **Kitty** & **Dolphin** theming.
- **Dashboard & Right Sidebar**: Click the clock for the Dashboard (stacked clock, weather, greeting, calendar, CPU/RAM/Swap rings, Game Mode, Airplane Mode, Keep Awake, and wallpaper grid); click any right-side pill for notifications, user profile, and Sleep/Logout/Reboot/Power actions.
- **App Launcher & Dock**: Bottom-positioned launcher (`Super`) with app pinning and `?web` search, synced live with a multi-monitor floating Dock (with optional auto-hide).
- **Desktop Widgets & CAVA**: Draggable desktop cards (Clock/Calendar, Analog Clock, Music, Sound) + optional bottom-edge CAVA audio visualizer.
- **Extras**: Built-in **Nocturnal AI** (`Super + A`, supports Groq/Gemini/OpenAI/Ollama), Emoji Picker (`Super + .`), Clipboard History (`Super + V`), and Region Screenshots (`Super + Shift + S`).

## Keybinds
| Keybind | Action |
|---|---|
| `Super` (tap) | Toggle App Launcher |
| `Super + T` | Open Kitty Terminal |
| `Super + B` | Open Browser (`firefox-bin`) |
| `Super + E` | Open Dolphin |
| `Super + Q` | Close Window |
| `Super + Shift + F` | Toggle Floating Window |
| `Super + Shift + S` | Region Screenshot |
| `Super + I` | Open Settings |
| `Super + A` | Open Nocturnal AI |
| `Super + .` | Emoji Picker |
| `Super + V` | Clipboard History |
| `Super + L` | Lock Screen |
| `Super + M` | Exit Session |

## Install
```sh
git clone https://github.com/wealluselinux/nocturnal_shell.git ~/nocturnal
cd ~/nocturnal && ./install.sh
```
The installer detects your Linux distribution, maps it to its base family (Arch, Debian/Ubuntu, Fedora, Gentoo, or openSUSE), asks for confirmation (`Y/N`), installs dependencies, and registers **Nocturnal** as a selectable session in your login manager (SDDM/GDM).
