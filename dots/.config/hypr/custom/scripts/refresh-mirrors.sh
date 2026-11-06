#!/bin/bash

# Flag file to track if script has run this boot
FLAG_FILE="/tmp/mirrorlist-refreshed-$USER"

# Check if already run this boot session
if [ -f "$FLAG_FILE" ]; then
    exit 0
fi

# Check if connected to WiFi
if nmcli -t -f TYPE,STATE device | grep -q "wifi:connected"; then
    # Run reflector to update mirrorlist
    if sudo reflector --country india --sort rate --save /etc/pacman.d/mirrorlist; then
        # Create flag file on success
        touch "$FLAG_FILE"
        notify-send "Mirrorlist Updated" "Successfully refreshed Arch mirrorlist" -u normal -i network-wireless
        exit 0
    else
        notify-send "Mirrorlist Update Failed" "Could not refresh mirrorlist" -u critical -i dialog-error
        exit 1
    fi
else
    notify-send "Mirrorlist Update Skipped" "No WiFi connection detected" -u low -i network-wireless-offline
fi
