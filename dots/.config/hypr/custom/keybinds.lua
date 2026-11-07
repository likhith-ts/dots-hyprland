-- Custom keybinds (ported from live keybinds.conf, 2026-11-07)
-- See ~/.config/hypr/hyprland/keybinds.lua for examples
-- Lua API (Hyprland 0.57): hl.unbind("MODS + key") removes upstream binds before rebinding.

local customScripts = "$HOME/.config/hypr/custom/scripts"

--#!
--##! Hyprland
hl.bind("SUPER + ALT + J", hl.dsp.exec_cmd(customScripts .. "/toggle_smart_split.sh"), { description = "Custom: Toggle smart split" })

hl.unbind("SUPER + B") -- upstream: left sidebar (also on Super+O / Super+S below)
hl.bind("SUPER + B", hl.dsp.exec_cmd(customScripts .. "/toggle_hyprbars.sh"), { description = "Custom: Toggle hyprbars" })

-- Zoom with Ctrl+Super+Alt + scroll (zoom.sh is gone upstream; same logic as upstream's zoomfunction)
local function zoom(delta)
    local z = hl.get_config("cursor:zoom_factor") + delta
    hl.config({ cursor = { zoom_factor = math.max(1.0, math.min(3.0, z)) } })
end
hl.bind("CTRL + SUPER + ALT + mouse_up", function() zoom(-0.3) end) -- [hidden] Zoom out
hl.bind("CTRL + SUPER + ALT + mouse_down", function() zoom(0.3) end) -- [hidden] Zoom in

-- Resize active window (replaces upstream's splitratio on these keys)
hl.unbind("SUPER + Semicolon")
hl.unbind("SUPER + Apostrophe")
hl.bind("SUPER + Semicolon", hl.dsp.window.resize({ x = -25, y = 0, relative = true }), { repeating = true }) -- [hidden] Resize left
hl.bind("SUPER + Apostrophe", hl.dsp.window.resize({ x = 25, y = 0, relative = true }), { repeating = true }) -- [hidden] Resize right
hl.bind("SUPER + SHIFT + Semicolon", hl.dsp.window.resize({ x = 0, y = -25, relative = true }), { repeating = true }) -- [hidden] Resize up
hl.bind("SUPER + SHIFT + Apostrophe", hl.dsp.window.resize({ x = 0, y = 25, relative = true }), { repeating = true }) -- [hidden] Resize down

--##! User
hl.bind("CTRL + SUPER + Slash", hl.dsp.exec_cmd("xdg-open ~/.config/illogical-impulse/config.json"), { description = "Custom: Edit shell config" })
hl.bind("CTRL + SUPER + ALT + Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), { description = "Custom: Edit extra keybinds" })

--##! Extra
hl.bind("SUPER + R", hl.dsp.exec_cmd("rofi -show drun -show-icons"), { description = "Custom: Jarvis search (rofi)" })
hl.bind("SUPER + Space", hl.dsp.exec_cmd("nwg-drawer"), { description = "Custom: Apps grid (nwg-drawer)" })
hl.bind("CTRL + SUPER + C", hl.dsp.exec_cmd(customScripts .. "/kalk-toggle.sh")) -- [hidden] Calculator
-- Window switching across workspaces: hyprshell (started in execs.lua)

--##! Minimize
hl.bind("SUPER + H", hl.dsp.exec_cmd(customScripts .. "/minimize.sh minimize"), { description = "Custom: Minimize window" })
hl.bind("SUPER + SHIFT + H", hl.dsp.exec_cmd(customScripts .. "/minimize.sh toggle"), { description = "Custom: Toggle minimized view" })
hl.bind("CTRL + SUPER + H", hl.dsp.exec_cmd(customScripts .. "/minimize.sh restore-all"), { description = "Custom: Restore all minimized" })

--##! Rebinded keys
hl.unbind("SUPER + A")
hl.unbind("SUPER + S") -- upstream: scratchpad
hl.bind("SUPER + S", hl.dsp.global("quickshell:sidebarLeftToggle"), { description = "Custom: Toggle left sidebar" })
-- Scratchpad with a count notification instead:
-- hl.unbind("SUPER + S"); hl.bind("SUPER + S", hl.dsp.exec_cmd(customScripts .. "/scratchpad_toggle.sh"))

--##! Fix: Super-release overview
-- Upstream's Lua port dropped the searchToggleReleaseInterrupt binds. Without them,
-- quickshell's GlobalShortcut.onReleased fires after every Super+<key> chord and the
-- overview opens. The old fix was `binditn = Super, catchall`, but in Lua (0.57)
-- catchall only works inside submaps, so we bind every keycode explicitly instead,
-- for every modifier combo that includes Super. non_consuming + transparent: the
-- real binds on those keys still fire normally.
local qsInterrupt = hl.dsp.global("quickshell:searchToggleReleaseInterrupt")
local skipCodes = { [37]=true, [50]=true, [62]=true, [64]=true, [105]=true, [108]=true, [133]=true, [134]=true } -- Ctrl/Shift/Alt/Super themselves
-- Keycodes 9-135 = every key on a standard keyboard (letters, numbers, F-keys, arrows, nav, numpad, media).
-- Combos limited to those upstream + custom binds actually use, to keep the bind list small (~830).
local superCombos = { "SUPER", "SUPER + SHIFT", "SUPER + CTRL", "SUPER + ALT", "SUPER + SHIFT + ALT", "SUPER + CTRL + ALT", "SUPER + SHIFT + CTRL" }
for _, mods in ipairs(superCombos) do
    for code = 9, 135 do
        if not skipCodes[code] then
            hl.bind(mods .. " + code:" .. code, qsInterrupt, { non_consuming = true, transparent = true })
        end
    end
end
hl.bind("CTRL + SUPER_L", qsInterrupt)
hl.bind("CTRL + SUPER_R", qsInterrupt)
for _, btn in ipairs({ "mouse:272", "mouse:273", "mouse:274", "mouse:275", "mouse:276", "mouse:277", "mouse_up", "mouse_down" }) do
    hl.bind("SUPER + " .. btn, qsInterrupt, { non_consuming = true })
end
