#!/usr/bin/env bash

# Kill any existing polybar instances
killall -q polybar

# Wait until all polybar processes have exited
while pgrep -x polybar >/dev/null; do
    sleep 0.05
done

# Launch the main bar (adjust name if your bar is different)
polybar main &

echo "polybar started"
