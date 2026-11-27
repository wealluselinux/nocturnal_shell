-- Nocturnal: my own keybinds
local mainMod = "SUPER"

-- Super + B opens the web browser
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("firefox-bin"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(os.getenv("HOME") .. "/nocturnal/bin/screenshot"))

-- Tap Windows key to toggle the app launcher
hl.bind("SUPER + SUPER_L", hl.dsp.exec_cmd("quickshell ipc -p " .. os.getenv("HOME") .. "/nocturnal/quickshell/shell.qml call launcher toggle"), { release = true })

-- Super + I toggles the Nocturnal settings panel
hl.bind("SUPER + I", hl.dsp.exec_cmd("quickshell ipc -p " .. os.getenv("HOME") .. "/nocturnal/quickshell/shell.qml call settings toggle"))

-- Win + . opens Emoji Picker, Win + V opens Clipboard History
hl.bind("SUPER + period", hl.dsp.exec_cmd("quickshell ipc -p " .. os.getenv("HOME") .. "/nocturnal/quickshell/shell.qml call emoji toggle"))
hl.bind("SUPER + V", hl.dsp.exec_cmd("quickshell ipc -p " .. os.getenv("HOME") .. "/nocturnal/quickshell/shell.qml call clipboard toggle"))

-- Super + A toggles Nocturnal AI
hl.bind("SUPER + A", hl.dsp.exec_cmd("quickshell ipc -p " .. os.getenv("HOME") .. "/nocturnal/quickshell/shell.qml call ai toggle"))

-- Super + L locks the screen
hl.bind("SUPER + L", hl.dsp.exec_cmd("quickshell ipc -p " .. os.getenv("HOME") .. "/nocturnal/quickshell/shell.qml call lockscreen lock"))
