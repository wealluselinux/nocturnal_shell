-- Nocturnal appearance: soft frosted blur, rounded corners, no animations yet
hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 8,
        border_size = 1,
    },
    decoration = {
        rounding = 14,
        blur = {
            enabled = true,
            size = 4,
            passes = 2,
            noise = 0.02,
            vibrancy = 0.1,
            xray = true,
            new_optimizations = true,
        },
        shadow = { enabled = false },
    },
    animations = { enabled = true },
    misc = { disable_hyprland_logo = true },
})

-- Float and center file picker dialogs
hl.window_rule({
    name = "kdialog-popup",
    match = { class = ".*kdialog.*" },
    float = true,
    size = {860, 560},
    center = true,
})
