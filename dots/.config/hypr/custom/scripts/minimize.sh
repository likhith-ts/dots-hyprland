#!/bin/bash
# Minimize/Restore window script for Hyprland with Genie animation
# Uses Quickshell IPC for animated minimize, falls back to direct if QS unavailable

SPECIAL_WS="special:minimize"
QS_CONFIG="ii"

# Check if quickshell is running and use IPC for animation
use_animated() {
    qs -c $QS_CONFIG ipc call TEST_ALIVE &>/dev/null
    return $?
}

minimize_active() {
    if use_animated; then
        # Use Quickshell IPC for animated minimize
        qs -c $QS_CONFIG ipc call minimize active
    else
        # Fallback: direct minimize without animation
        local addr=$(hyprctl activewindow -j | jq -r '.address')
        if [[ "$addr" != "null" && -n "$addr" ]]; then
            hyprctl dispatch movetoworkspacesilent "$SPECIAL_WS"
        fi
    fi
}

restore_window() {
    # Restore a specific window by address to the current workspace
    local addr="$1"
    if [[ -n "$addr" ]]; then
        # Get current active workspace
        local current_ws=$(hyprctl activeworkspace -j | jq -r '.id')
        # Move window to current workspace and focus it
        hyprctl dispatch movetoworkspace "$current_ws,address:$addr"
        hyprctl dispatch focuswindow "address:$addr"
    fi
}

toggle_minimize_view() {
    # Toggle the minimize view overlay with header
    if use_animated; then
        qs -c $QS_CONFIG ipc call minimize toggleView
    else
        # Fallback to basic special workspace toggle
        hyprctl dispatch togglespecialworkspace minimize
    fi
}

show_minimized() {
    # List all minimized windows (for debugging or rofi selector)
    hyprctl clients -j | jq -r '.[] | select(.workspace.name == "special:minimize") | "\(.address) \(.class) - \(.title)"'
}

restore_all() {
    # Restore all minimized windows to current workspace
    local current_ws=$(hyprctl activeworkspace -j | jq -r '.id')
    hyprctl clients -j | jq -r '.[] | select(.workspace.name == "special:minimize") | .address' | while read addr; do
        hyprctl dispatch movetoworkspace "$current_ws,address:$addr"
    done
}

restore_by_class() {
    # Restore windows of a specific class
    local class="$1"
    local current_ws=$(hyprctl activeworkspace -j | jq -r '.id')
    hyprctl clients -j | jq -r --arg class "$class" '.[] | select(.workspace.name == "special:minimize" and .class == $class) | .address' | while read addr; do
        hyprctl dispatch movetoworkspace "$current_ws,address:$addr"
        hyprctl dispatch focuswindow "address:$addr"
    done
}

# Command handler
case "$1" in
    minimize)
        minimize_active
        ;;
    restore)
        restore_window "$2"
        ;;
    toggle)
        toggle_minimize_view
        ;;
    list)
        show_minimized
        ;;
    restore-all)
        restore_all
        ;;
    restore-class)
        restore_by_class "$2"
        ;;
    *)
        echo "Usage: $0 {minimize|restore <addr>|toggle|list|restore-all|restore-class <class>}"
        exit 1
        ;;
esac
