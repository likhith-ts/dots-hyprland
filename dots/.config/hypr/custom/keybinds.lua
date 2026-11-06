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
