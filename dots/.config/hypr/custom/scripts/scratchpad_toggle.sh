#!/bin/bash
# Toggle the scratchpad and show how many windows are in it (optional Super+S, see keybinds.lua)
WINDOWS=$(hyprctl clients -j | jq '[.[] | select(.workspace.name == "special:special")] | length')
hyprctl dispatch 'hl.dsp.workspace.toggle_special("special")' >/dev/null
if [[ -z "$WINDOWS" || "$WINDOWS" == "0" ]]; then
    notify-send -t 600 -u low "󰟑 Scratchpad" "Empty"
else
    notify-send -t 600 -u low "󰟑 Scratchpad" "$WINDOWS window(s)"
fi
