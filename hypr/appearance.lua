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
    animations = { enabled = false },
    misc = { disable_hyprland_logo = true },
})
