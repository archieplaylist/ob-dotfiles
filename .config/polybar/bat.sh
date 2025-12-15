#!/bin/bash

# Define the paths for your two batteries (adjust BAT0/BAT1 if needed)
BAT1_PATH="/sys/class/power_supply/BAT0"
BAT2_PATH="/sys/class/power_supply/BAT1"
AC_PATH="/sys/class/power_supply/AC"

# Check if AC adapter is connected
AC_STATUS=$(cat ${AC_PATH}/online 2>/dev/null)

if [ "$AC_STATUS" = "1" ]; then
    STATUS="Charging"
else
    STATUS="Discharging"
fi

# Calculate total charge (energy_now) and total capacity (energy_full)
TOTAL_NOW=$(($(cat ${BAT1_PATH}/energy_now 2>/dev/null) + $(cat ${BAT2_PATH}/energy_now 2>/dev/null)))
TOTAL_FULL=$(($(cat ${BAT1_PATH}/energy_full 2>/dev/null) + $(cat ${BAT2_PATH}/energy_full 2>/dev/null)))

# Calculate percentage
PERCENTAGE=$((100 * $TOTAL_NOW / $TOTAL_FULL))

# Define icons (requires a Nerd Font like Font Awesome)
ICON_FULL=""
ICON_CHARGING=""
ICON_DISCHARGING_RAMP=(    )

if [ "$PERCENTAGE" -gt 95 ] && [ "$AC_STATUS" = "1" ]; then
    echo "$ICON_FULL ${PERCENTAGE}%"
elif [ "$AC_STATUS" = "1" ]; then
    echo "$ICON_CHARGING ${PERCENTAGE}%"
else
    # Calculate index for capacity ramp (0-4)
    RAMP_INDEX=$(( ($PERCENTAGE + 9) / 20 ))
    # Ensure index is within bounds [0, 4]
    if [ "$RAMP_INDEX" -gt 4 ]; then RAMP_INDEX=4; fi
    ICON_DISCHARGING=${ICON_DISCHARGING_RAMP[$RAMP_INDEX]}
    echo "$ICON_DISCHARGING ${PERCENTAGE}%"
fi

exit 0
