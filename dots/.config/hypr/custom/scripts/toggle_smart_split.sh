#!/bin/sh
# Toggle dwindle smart_split (Super+Alt+J). Hyprland 0.57: `hyprctl keyword` is gone, use `hyprctl eval`.
HYPR_ICON="$HOME/.config/hypr/custom/Hyprland_logo.png"
current=$(hyprctl getoption dwindle:smart_split -j | jq ".int")
if [ "$current" = "1" ]; then
    hyprctl eval 'hl.config({ dwindle = { smart_split = false } })' >/dev/null
    notify-send "Hyprland" "Smart Split: OFF" -i "$HYPR_ICON" --app-name="Hyprland"
else
    hyprctl eval 'hl.config({ dwindle = { smart_split = true } })' >/dev/null
    notify-send "Hyprland" "Smart Split: ON" -i "$HYPR_ICON" --app-name="Hyprland"
fi
