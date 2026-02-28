#!/bin/bash

# Kill all relevant processes
killall ags agsv1 gjs ydotool qs quickshell

# Wait briefly to ensure termination before restarting
sleep 0.5

# Restart quickshell in the background
# Ensure $qsConfig is defined in your shell environment (e.g., in ~/.bashrc or ~/.zshrc)
# If not, replace $qsConfig with the actual path to your config file
qs -c "$qsConfig" &

# #!/bin/bash

# # More graceful process termination
# pkill -TERM quickshell
# sleep 0.5

# # Force kill if still running
# pkill -KILL quickshell 2>/dev/null

# # Wait for cleanup
# sleep 0.5

# # Set config path
# # qsConfig="${qsConfig:-$HOME/.config/quickshell/ii/shell.qml}"
# echo "$qsConfig"
# # Verify config exists
# if [ ! -f "$qsConfig" ]; then
#     notify-send "Quickshell Error" "Config not found: $qsConfig"
#     exit 1
# fi

# # Restart with proper logging
# qs -c "$qsConfig" &> /tmp/quickshell-restart.log &

# echo "Quickshell restarted (PID: $!)"