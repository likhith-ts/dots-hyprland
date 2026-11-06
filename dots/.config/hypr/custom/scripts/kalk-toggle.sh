#!/usr/bin/env bash
# Toggle the Kalk scratchpad; launch Kalk first if it isn't running.
# Placement (special:kalk, float, size, position) comes from custom/rules.lua.
if hyprctl clients -j | jq -e 'any(.[]; .class == "org.kde.kalk")' >/dev/null; then
    hyprctl dispatch 'hl.dsp.workspace.toggle_special("kalk")'
else
    kalk & disown
    sleep 0.4
    hyprctl dispatch 'hl.dsp.workspace.toggle_special("kalk")'
fi
