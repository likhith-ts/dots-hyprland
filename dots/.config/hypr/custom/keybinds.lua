-- Custom keybinds (ported from keybinds.conf)
-- See ~/.config/hypr/hyprland/keybinds.lua for examples

local customScripts = "$HOME/.config/hypr/custom/scripts"

--##! User
hl.bind("CTRL + SUPER + Slash", hl.dsp.exec_cmd("xdg-open ~/.config/illogical-impulse/config.json"), { description = "Edit shell config" })
hl.bind("CTRL + SUPER + ALT + Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), { description = "Edit user keybinds" })

--##! Extra
hl.bind("SUPER + R", hl.dsp.exec_cmd("rofi -show drun -show-icons"), { description = "Jarvis search (rofi)" })
hl.bind("SUPER + Space", hl.dsp.exec_cmd("nwg-drawer"), { description = "Apps grid (nwg-drawer)" })
hl.bind("CTRL + SUPER + C", hl.dsp.exec_cmd(customScripts .. "/kalk-toggle.sh")) -- # [hidden] Calculator

--##! Minimize
hl.bind("SUPER + H", hl.dsp.exec_cmd(customScripts .. "/minimize.sh minimize"), { description = "Minimize window" })
hl.bind("SUPER + SHIFT + H", hl.dsp.exec_cmd(customScripts .. "/minimize.sh toggle"), { description = "Toggle minimized view" })
hl.bind("CTRL + SUPER + H", hl.dsp.exec_cmd(customScripts .. "/minimize.sh restore-all"), { description = "Restore all minimized" })

--##! Fix: Super-release overview
-- Upstream's Lua port dropped the searchToggleReleaseInterrupt binds that the old
-- keybinds.conf had. Without them, quickshell's GlobalShortcut.onReleased fires after
-- every Super+<key> chord and toggles the overview. These restore the old behaviour:
-- any key or mouse button pressed while Super is held cancels the release trigger.
local qsInterrupt = hl.dsp.global("quickshell:searchToggleReleaseInterrupt")
-- old: binditn = Super, catchall, ...   (i = ignore_mods, t = transparent, n = non_consuming)
hl.bind("SUPER + catchall", qsInterrupt, { ignore_mods = true, transparent = true, non_consuming = true })
hl.bind("CTRL + SUPER_L", qsInterrupt)
hl.bind("CTRL + SUPER_R", qsInterrupt)
for _, btn in ipairs({ "mouse:272", "mouse:273", "mouse:274", "mouse:275", "mouse:276", "mouse:277", "mouse_up", "mouse_down" }) do
    hl.bind("SUPER + " .. btn, qsInterrupt, { non_consuming = true })
end
