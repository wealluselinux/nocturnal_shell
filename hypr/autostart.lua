-- Nocturnal autostart: things that launch when the session starts
local home = os.getenv("HOME")
local wallpaper = home .. "/nocturnal/wallpapers/wall0.png"

hl.on("hyprland.start", function()
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")
    hl.exec_cmd("swaybg -i " .. wallpaper .. " -m fill")
    hl.exec_cmd("quickshell -p " .. home .. "/nocturnal/quickshell/shell.qml")
end)
