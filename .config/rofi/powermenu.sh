#!/bin/bash

options="Shutdown\nReboot\nLock\nSuspend\nLogout"

# Use the gruvbox theme explicitly to ensure consistent colors
chosen=$(echo -e "$options" | rofi -theme gruvbox-dark -dmenu -p "Power Menu")

case "$chosen" in
    "Shutdown") systemctl poweroff ;;
    "Reboot") systemctl reboot ;;
    "Lock") light-locker-command -l ;;
    "Suspend") systemctl suspend ;;
    "Logout") i3-msg exit ;;
esac
