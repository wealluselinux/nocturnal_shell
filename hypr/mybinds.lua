-- Nocturnal: my own keybinds
local mainMod = "SUPER"

-- Super + B opens the web browser
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("firefox-bin"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(os.getenv("HOME") .. "/nocturnal/bin/screenshot"))
