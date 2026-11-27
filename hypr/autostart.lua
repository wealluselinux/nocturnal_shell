-- Nocturnal autostart: wallpaper + bar + clipboard + shell
local home = os.getenv("HOME")
local default_wall = home .. "/nocturnal/wallpapers/wall0.png"

hl.on("hyprland.start", function()
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")
    hl.exec_cmd("sh -c 'w=$(cat \"$HOME/.cache/nocturnal/wallpaper\" 2>/dev/null); [ -f \"$w\" ] || w=$(python3 -c \"import json,os; p=os.path.expanduser(\\\"~/nocturnal/quickshell/settings.json\\\"); d=json.load(open(p)); w=d.get(\\\"wallpaper\\\",\\\"\\\"); print(w if w.startswith(\\\"/\\\") else (os.path.expanduser(\\\"~/nocturnal/wallpapers/\\\")+w if w else \\\"\\\"))\" 2>/dev/null); [ -f \"$w\" ] || w=\"" .. default_wall .. "\"; exec \"$HOME/nocturnal/bin/set-wallpaper\" \"$w\" --quiet'")
    hl.exec_cmd(home .. "/nocturnal/bin/clipwatch")
    hl.exec_cmd("quickshell -p " .. home .. "/nocturnal/quickshell/shell.qml")
end)
