#!/usr/bin/env bash
# Toggle hyprbars on/off (Super+B). Loading/config lives in custom/hyprbars.lua;
# this flips a flag file it checks, then applies the change immediately.
HYPR_ICON="$HOME/.config/hypr/custom/Hyprland_logo.png"
SO="$HOME/.config/hypr/custom/plugins/hyprbars.so"
FLAG="$HOME/.config/hypr/custom/plugins/.hyprbars-disabled"

if [ ! -f "$SO" ]; then
    notify-send "Hyprbars" "Plugin not built for this Hyprland yet. Run custom/scripts/build-hyprbars.sh" -i "$HYPR_ICON" -a Hyprland
    exit 1
fi

if hyprctl plugin list | grep -qi hyprbars; then
    touch "$FLAG"
    hyprctl plugin unload "$SO" >/dev/null
    hyprctl reload >/dev/null
    notify-send "Hyprbars" "Plugin disabled" -i "$HYPR_ICON" -a Hyprland
else
    rm -f "$FLAG"
    hyprctl plugin load "$SO" >/dev/null
    hyprctl reload >/dev/null   # applies buttons/rules now that the plugin is loaded
    notify-send "Hyprbars" "Plugin enabled" -i "$HYPR_ICON" -a Hyprland
fi
