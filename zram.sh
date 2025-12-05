#!/bin/bash

# --- Configuration Variables ---
# Set the amount of RAM to use for zram. 
# It's common to set it to 50% of the total system RAM. 
# If left blank, zram-tools will use its default (often 1/2 of RAM).
sudo apt update && sudo apt install zram-tools

ZRAM_SIZE_PERCENTAGE="50" 

# --- Script Start ---
echo "Starting Zram enablement on Debian..."

# 1. Check for root/sudo privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root or with sudo." 
   exit 1
fi

# 2. Update package list and install zram-tools
echo "Updating package list and installing zram-tools..."
apt update
if ! apt install -y zram-tools; then
    echo "Error: Failed to install zram-tools. Exiting."
    exit 1
fi
echo "zram-tools installed successfully."

# 3. Configure zram (Optional: Use default or set size)
# zram-tools reads configuration from /etc/default/zramswap
ZRAM_CONFIG_FILE="/etc/default/zramswap"

if [[ ! -f "$ZRAM_CONFIG_FILE" ]]; then
    echo "Warning: $ZRAM_CONFIG_FILE not found after installation. Proceeding with service activation."
else
    # Check if the size is already configured and if we should override it
    if grep -q "^PERCENT=$ZRAM_SIZE_PERCENTAGE" "$ZRAM_CONFIG_FILE"; then
        echo "Zram size already set to $ZRAM_SIZE_PERCENTAGE% in $ZRAM_CONFIG_FILE."
    else
        echo "Setting Zram size to $ZRAM_SIZE_PERCENTAGE% in $ZRAM_CONFIG_FILE..."
        # Use a temporary file and sed to safely update the PERCENT line
        # This will either replace an existing PERCENT= line or append it if not found.
        if grep -q "^PERCENT=" "$ZRAM_CONFIG_FILE"; then
            sed -i "s/^PERCENT=.*/PERCENT=$ZRAM_SIZE_PERCENTAGE/" "$ZRAM_CONFIG_FILE"
        else
            echo "PERCENT=$ZRAM_SIZE_PERCENTAGE" >> "$ZRAM_CONFIG_FILE"
        fi
    fi
    echo "Zram configuration updated."
fi

# 4. Start and Enable the zram-swap service
# zram-tools provides a systemd service called zram-swap.
echo "Starting and enabling the zram-swap systemd service..."
systemctl start zram-swap
systemctl enable zram-swap
systemctl status zram-swap --no-pager

# 5. Verification
echo "--- Verification ---"
echo "Checking active swap devices..."
swapon --show

echo "Zram setup complete! Your system is now using compressed RAM for swap."