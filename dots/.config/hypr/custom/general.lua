-- General config (ported from live general.conf, 2026-11-07)
-- See ~/.config/hypr/hyprland/general.lua for examples

-- 3-finger swipe down to minimize (disabled; upstream uses 3-finger swipe for "move")
-- hl.gesture({ fingers = 3, direction = "down", action = function()
--     hl.dispatch(hl.dsp.exec_cmd("$HOME/.config/hypr/custom/scripts/minimize.sh minimize"))
-- end })

-- Kalk scratchpad animation
-- hl.animation({ leaf = "specialWorkspaceIn",  enabled = true, speed = 2.8, bezier = "emphasizedDecel", style = "slide" })
-- hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 1.2, bezier = "emphasizedAccel", style = "slide" })

hl.config({
    general = {
        -- layout = "scrolling",
        border_size = 2,
    },
    scrolling = {
        column_width = 0.5, -- default width of new windows
    },
    input = {
        touchpad = {
            disable_while_typing = false, -- upstream default: true
        },
    },
    -- XWayland: enabled, crisp scaling off
    xwayland = {
        enabled = true,
        use_nearest_neighbor = false,
    },
    -- misc = { vfr = false },
    -- decoration = { blur = { enabled = true, passes = 1, size = 6, new_optimizations = true, xray = true, noise = 0.05, brightness = 1 } },
})

-- Hyprbars (traffic-light title bars) lives in its own file
require("custom.hyprbars")
