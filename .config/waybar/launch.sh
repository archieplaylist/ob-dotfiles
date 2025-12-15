#!/bin/bash

CONFIG_FILE="$HOME/.config/waybar/config"
# Add your style file if you want to monitor both
STYLE_FILE="$HOME/.config/waybar/style.css" 

# Kill waybar on script exit
cleanup() {
    pkill waybar
}
trap cleanup EXIT

# Start waybar in the background
waybar &

# Loop to monitor files and restart waybar
while true; do
    # Wait for a modify event on the config or style files
    inotifywait -e modify "$CONFIG_FILE" "$STYLE_FILE"
    
    # Reload Waybar after a change is detected
    killall -SIGUSR2 waybar
done
